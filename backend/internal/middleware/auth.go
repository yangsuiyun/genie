package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type AuthConfig struct {
	JWTSecret        string        `json:"-"`
	TokenExpiry      time.Duration `json:"token_expiry"`
	RefreshExpiry    time.Duration `json:"refresh_expiry"`
	Issuer           string        `json:"issuer"`
	RequireHTTPS     bool          `json:"require_https"`
	SkipPaths        []string      `json:"skip_paths"`
	HeaderName       string        `json:"header_name"`
	AuthScheme       string        `json:"auth_scheme"`
	CookieName       string        `json:"cookie_name"`
	QueryParam       string        `json:"query_param"`
	EnableLogging    bool          `json:"enable_logging"`
	RequireRole      string        `json:"require_role,omitempty"`
	RequireScope     []string      `json:"require_scope,omitempty"`
}

type Claims struct {
	UserID    string   `json:"user_id"`
	Email     string   `json:"email"`
	Name      string   `json:"name"`
	Role      string   `json:"role"`
	Scopes    []string `json:"scopes"`
	TokenType string   `json:"token_type"`
	jwt.RegisteredClaims
}

type AuthService interface {
	ValidateToken(tokenString string) (*Claims, error)
	RefreshToken(refreshToken string) (string, string, error)
	RevokeToken(tokenString string) error
	IsTokenRevoked(tokenString string) bool
}

type TokenValidator func(tokenString string) (*Claims, error)

type AuthMiddleware struct {
	config    AuthConfig
	validator TokenValidator
	service   AuthService
}

func NewAuthMiddleware(config AuthConfig, service AuthService) *AuthMiddleware {
	if config.HeaderName == "" {
		config.HeaderName = "Authorization"
	}
	if config.AuthScheme == "" {
		config.AuthScheme = "Bearer"
	}
	if config.CookieName == "" {
		config.CookieName = "auth_token"
	}
	if config.QueryParam == "" {
		config.QueryParam = "token"
	}
	if config.TokenExpiry == 0 {
		config.TokenExpiry = 15 * time.Minute
	}
	if config.RefreshExpiry == 0 {
		config.RefreshExpiry = 7 * 24 * time.Hour
	}

	return &AuthMiddleware{
		config:  config,
		service: service,
	}
}

func (am *AuthMiddleware) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		if am.shouldSkipAuth(c) {
			c.Next()
			return
		}

		if am.config.RequireHTTPS && c.Request.Header.Get("X-Forwarded-Proto") != "https" && c.Request.TLS == nil {
			am.abortWithError(c, http.StatusUpgradeRequired, "HTTPS required", "Authentication requires HTTPS connection")
			return
		}

		token, err := am.extractToken(c)
		if err != nil {
			am.abortWithError(c, http.StatusUnauthorized, "TOKEN_MISSING", err.Error())
			return
		}

		claims, err := am.validateToken(token)
		if err != nil {
			am.abortWithError(c, http.StatusUnauthorized, "TOKEN_INVALID", err.Error())
			return
		}

		if claims.TokenType != "access" {
			am.abortWithError(c, http.StatusUnauthorized, "INVALID_TOKEN_TYPE", "Invalid token type for this operation")
			return
		}

		if am.service != nil && am.service.IsTokenRevoked(token) {
			am.abortWithError(c, http.StatusUnauthorized, "TOKEN_REVOKED", "Token has been revoked")
			return
		}

		if err := am.checkPermissions(claims); err != nil {
			am.abortWithError(c, http.StatusForbidden, "INSUFFICIENT_PERMISSIONS", err.Error())
			return
		}

		am.setUserContext(c, claims)
		c.Next()
	}
}

func (am *AuthMiddleware) OptionalAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		if am.shouldSkipAuth(c) {
			c.Next()
			return
		}

		token, err := am.extractToken(c)
		if err != nil {
			c.Next()
			return
		}

		claims, err := am.validateToken(token)
		if err != nil {
			c.Next()
			return
		}

		if claims.TokenType == "access" && (am.service == nil || !am.service.IsTokenRevoked(token)) {
			am.setUserContext(c, claims)
		}

		c.Next()
	}
}

func (am *AuthMiddleware) RequireRole(role string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := c.GetString("user_role")
		if userRole == "" {
			am.abortWithError(c, http.StatusUnauthorized, "AUTHENTICATION_REQUIRED", "Authentication required")
			return
		}

		if !am.hasRole(userRole, role) {
			am.abortWithError(c, http.StatusForbidden, "INSUFFICIENT_ROLE", fmt.Sprintf("Required role: %s", role))
			return
		}

		c.Next()
	}
}

func (am *AuthMiddleware) RequireScope(scopes ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userScopes := am.getUserScopes(c)
		if len(userScopes) == 0 {
			am.abortWithError(c, http.StatusUnauthorized, "AUTHENTICATION_REQUIRED", "Authentication required")
			return
		}

		for _, requiredScope := range scopes {
			if !am.hasScope(userScopes, requiredScope) {
				am.abortWithError(c, http.StatusForbidden, "INSUFFICIENT_SCOPE", fmt.Sprintf("Required scope: %s", requiredScope))
				return
			}
		}

		c.Next()
	}
}

func (am *AuthMiddleware) RequireAnyScope(scopes ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userScopes := am.getUserScopes(c)
		if len(userScopes) == 0 {
			am.abortWithError(c, http.StatusUnauthorized, "AUTHENTICATION_REQUIRED", "Authentication required")
			return
		}

		for _, requiredScope := range scopes {
			if am.hasScope(userScopes, requiredScope) {
				c.Next()
				return
			}
		}

		am.abortWithError(c, http.StatusForbidden, "INSUFFICIENT_SCOPE", fmt.Sprintf("Required one of scopes: %v", scopes))
	}
}

func (am *AuthMiddleware) RefreshTokenEndpoint() gin.HandlerFunc {
	return func(c *gin.Context) {
		refreshToken, err := am.extractRefreshToken(c)
		if err != nil {
			am.abortWithError(c, http.StatusUnauthorized, "REFRESH_TOKEN_MISSING", err.Error())
			return
		}

		if am.service == nil {
			am.abortWithError(c, http.StatusInternalServerError, "SERVICE_UNAVAILABLE", "Authentication service not available")
			return
		}

		newAccessToken, newRefreshToken, err := am.service.RefreshToken(refreshToken)
		if err != nil {
			am.abortWithError(c, http.StatusUnauthorized, "REFRESH_FAILED", err.Error())
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"access_token":  newAccessToken,
			"refresh_token": newRefreshToken,
			"token_type":    "Bearer",
			"expires_in":    int(am.config.TokenExpiry.Seconds()),
		})
	}
}

func (am *AuthMiddleware) LogoutEndpoint() gin.HandlerFunc {
	return func(c *gin.Context) {
		token, err := am.extractToken(c)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"message": "Logged out successfully",
				"success": true,
			})
			return
		}

		if am.service != nil {
			if err := am.service.RevokeToken(token); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"error": gin.H{
						"message":     "Failed to revoke token",
						"type":        "logout_error",
						"status_code": http.StatusInternalServerError,
					},
					"success": false,
					"code":    "LOGOUT_FAILED",
				})
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Logged out successfully",
			"success": true,
		})
	}
}

func (am *AuthMiddleware) shouldSkipAuth(c *gin.Context) bool {
	path := c.Request.URL.Path
	for _, skipPath := range am.config.SkipPaths {
		if strings.HasPrefix(path, skipPath) {
			return true
		}
	}
	return false
}

func (am *AuthMiddleware) extractToken(c *gin.Context) (string, error) {
	authHeader := c.GetHeader(am.config.HeaderName)
	if authHeader != "" {
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) == 2 && strings.ToLower(parts[0]) == strings.ToLower(am.config.AuthScheme) {
			return parts[1], nil
		}
	}

	if cookie, err := c.Cookie(am.config.CookieName); err == nil && cookie != "" {
		return cookie, nil
	}

	if token := c.Query(am.config.QueryParam); token != "" {
		return token, nil
	}

	return "", fmt.Errorf("no authentication token found")
}

func (am *AuthMiddleware) extractRefreshToken(c *gin.Context) (string, error) {
	var request struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		return "", fmt.Errorf("invalid request format")
	}

	if request.RefreshToken == "" {
		return "", fmt.Errorf("refresh token is required")
	}

	return request.RefreshToken, nil
}

func (am *AuthMiddleware) validateToken(tokenString string) (*Claims, error) {
	if am.service != nil {
		return am.service.ValidateToken(tokenString)
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(am.config.JWTSecret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		if claims.Issuer != am.config.Issuer {
			return nil, fmt.Errorf("invalid token issuer")
		}

		if time.Now().After(claims.ExpiresAt.Time) {
			return nil, fmt.Errorf("token has expired")
		}

		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

func (am *AuthMiddleware) checkPermissions(claims *Claims) error {
	if am.config.RequireRole != "" {
		if !am.hasRole(claims.Role, am.config.RequireRole) {
			return fmt.Errorf("insufficient role permissions")
		}
	}

	if len(am.config.RequireScope) > 0 {
		for _, requiredScope := range am.config.RequireScope {
			if !am.hasScope(claims.Scopes, requiredScope) {
				return fmt.Errorf("insufficient scope permissions")
			}
		}
	}

	return nil
}

func (am *AuthMiddleware) hasRole(userRole, requiredRole string) bool {
	roleHierarchy := map[string]int{
		"guest":  0,
		"user":   1,
		"admin":  2,
		"super":  3,
	}

	userLevel, userExists := roleHierarchy[userRole]
	requiredLevel, requiredExists := roleHierarchy[requiredRole]

	if !userExists || !requiredExists {
		return userRole == requiredRole
	}

	return userLevel >= requiredLevel
}

func (am *AuthMiddleware) hasScope(userScopes []string, requiredScope string) bool {
	for _, scope := range userScopes {
		if scope == requiredScope || scope == "*" {
			return true
		}
	}
	return false
}

func (am *AuthMiddleware) getUserScopes(c *gin.Context) []string {
	if scopes, exists := c.Get("user_scopes"); exists {
		if scopeSlice, ok := scopes.([]string); ok {
			return scopeSlice
		}
	}
	return []string{}
}

func (am *AuthMiddleware) setUserContext(c *gin.Context, claims *Claims) {
	c.Set("user_id", claims.UserID)
	c.Set("user_email", claims.Email)
	c.Set("user_name", claims.Name)
	c.Set("user_role", claims.Role)
	c.Set("user_scopes", claims.Scopes)
	c.Set("token_type", claims.TokenType)
	c.Set("authenticated", true)
}

func (am *AuthMiddleware) abortWithError(c *gin.Context, statusCode int, code, message string) {
	c.JSON(statusCode, gin.H{
		"error": gin.H{
			"message":     message,
			"type":        "authentication_error",
			"status_code": statusCode,
			"timestamp":   time.Now(),
		},
		"success": false,
		"code":    code,
	})
	c.Abort()
}

func RequireAuth(config AuthConfig, service AuthService) gin.HandlerFunc {
	middleware := NewAuthMiddleware(config, service)
	return middleware.RequireAuth()
}

func OptionalAuth(config AuthConfig, service AuthService) gin.HandlerFunc {
	middleware := NewAuthMiddleware(config, service)
	return middleware.OptionalAuth()
}

func JWTAuth(secret string) gin.HandlerFunc {
	config := AuthConfig{
		JWTSecret:     secret,
		TokenExpiry:   15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
		Issuer:        "pomodoro-app",
		RequireHTTPS:  false,
	}
	return RequireAuth(config, nil)
}

func RoleBasedAuth(secret, role string) gin.HandlerFunc {
	config := AuthConfig{
		JWTSecret:     secret,
		RequireRole:   role,
		TokenExpiry:   15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
		Issuer:        "pomodoro-app",
		RequireHTTPS:  false,
	}
	return RequireAuth(config, nil)
}

func ScopeBasedAuth(secret string, scopes ...string) gin.HandlerFunc {
	config := AuthConfig{
		JWTSecret:     secret,
		RequireScope:  scopes,
		TokenExpiry:   15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
		Issuer:        "pomodoro-app",
		RequireHTTPS:  false,
	}
	return RequireAuth(config, nil)
}

func APIKeyAuth(validAPIKeys map[string]string) gin.HandlerFunc {
	return func(c *gin.Context) {
		apiKey := c.GetHeader("X-API-Key")
		if apiKey == "" {
			apiKey = c.Query("api_key")
		}

		if apiKey == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"message":     "API key is required",
					"type":        "authentication_error",
					"status_code": http.StatusUnauthorized,
				},
				"success": false,
				"code":    "API_KEY_MISSING",
			})
			c.Abort()
			return
		}

		if userID, valid := validAPIKeys[apiKey]; valid {
			c.Set("api_key", apiKey)
			c.Set("user_id", userID)
			c.Set("authenticated", true)
			c.Set("auth_method", "api_key")
			c.Next()
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"message":     "Invalid API key",
					"type":        "authentication_error",
					"status_code": http.StatusUnauthorized,
				},
				"success": false,
				"code":    "API_KEY_INVALID",
			})
			c.Abort()
		}
	}
}

func BasicAuth(credentials map[string]string) gin.HandlerFunc {
	return gin.BasicAuth(credentials)
}

func ConditionalAuth(condition func(*gin.Context) bool, authMiddleware gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		if condition(c) {
			authMiddleware(c)
		} else {
			c.Next()
		}
	}
}

func MultiAuth(middlewares ...gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		var lastError error

		for _, middleware := range middlewares {
			writer := &responseWriter{ResponseWriter: c.Writer}
			c.Writer = writer

			middleware(c)

			if !c.IsAborted() && c.GetBool("authenticated") {
				c.Writer = writer.ResponseWriter
				c.Next()
				return
			}

			if c.IsAborted() {
				lastError = fmt.Errorf("authentication failed")
			}

			c.Writer = writer.ResponseWriter
			for len(c.Errors) > 0 {
				c.Errors = c.Errors[:len(c.Errors)-1]
			}
		}

		if lastError != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"message":     "Authentication failed with all methods",
					"type":        "authentication_error",
					"status_code": http.StatusUnauthorized,
				},
				"success": false,
				"code":    "AUTHENTICATION_FAILED",
			})
			c.Abort()
		}
	}
}

type responseWriter struct {
	gin.ResponseWriter
	written bool
}

func (w *responseWriter) Write(data []byte) (int, error) {
	w.written = true
	return w.ResponseWriter.Write(data)
}

func (w *responseWriter) WriteHeader(statusCode int) {
	w.written = true
	w.ResponseWriter.WriteHeader(statusCode)
}

func GetUserID(c *gin.Context) string {
	return c.GetString("user_id")
}

func GetUserEmail(c *gin.Context) string {
	return c.GetString("user_email")
}

func GetUserRole(c *gin.Context) string {
	return c.GetString("user_role")
}

func GetUserScopes(c *gin.Context) []string {
	if scopes, exists := c.Get("user_scopes"); exists {
		if scopeSlice, ok := scopes.([]string); ok {
			return scopeSlice
		}
	}
	return []string{}
}

func IsAuthenticated(c *gin.Context) bool {
	return c.GetBool("authenticated")
}

func HasRole(c *gin.Context, role string) bool {
	userRole := GetUserRole(c)
	if userRole == "" {
		return false
	}

	roleHierarchy := map[string]int{
		"guest":  0,
		"user":   1,
		"admin":  2,
		"super":  3,
	}

	userLevel, userExists := roleHierarchy[userRole]
	requiredLevel, requiredExists := roleHierarchy[role]

	if !userExists || !requiredExists {
		return userRole == role
	}

	return userLevel >= requiredLevel
}

func HasScope(c *gin.Context, scope string) bool {
	userScopes := GetUserScopes(c)
	for _, userScope := range userScopes {
		if userScope == scope || userScope == "*" {
			return true
		}
	}
	return false
}

func HasAnyScope(c *gin.Context, scopes ...string) bool {
	for _, scope := range scopes {
		if HasScope(c, scope) {
			return true
		}
	}
	return false
}

func GetAuthInfo(c *gin.Context) map[string]interface{} {
	return map[string]interface{}{
		"authenticated": IsAuthenticated(c),
		"user_id":       GetUserID(c),
		"user_email":    GetUserEmail(c),
		"user_role":     GetUserRole(c),
		"user_scopes":   GetUserScopes(c),
		"auth_method":   c.GetString("auth_method"),
	}
}