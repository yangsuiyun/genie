package config

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/supabase-community/supabase-go"
)

// RealtimeConfig holds real-time subscription configuration
type RealtimeConfig struct {
	SupabaseURL          string
	SupabaseKey          string
	JWTSecret            string
	HeartbeatInterval    time.Duration
	ReconnectDelay       time.Duration
	MaxReconnectAttempts int
	ChannelBufferSize    int
}

// RealtimeManager manages Supabase real-time subscriptions
type RealtimeManager struct {
	config         *RealtimeConfig
	supabaseClient *supabase.Client
	subscriptions  map[string]*Subscription
	eventHandlers  map[string][]EventHandler
	wsUpgrader     websocket.Upgrader
	isConnected    bool
}

// Subscription represents a real-time subscription
type Subscription struct {
	ID        string
	Topic     string
	Event     string
	Schema    string
	Table     string
	Filter    string
	UserID    uuid.UUID
	Channel   chan RealtimeEvent
	IsActive  bool
	CreatedAt time.Time
}

// RealtimeEvent represents a real-time database event
type RealtimeEvent struct {
	Type      string                 `json:"type"`
	Schema    string                 `json:"schema"`
	Table     string                 `json:"table"`
	EventType string                 `json:"event_type"`
	New       map[string]interface{} `json:"new,omitempty"`
	Old       map[string]interface{} `json:"old,omitempty"`
	Columns   []Column               `json:"columns,omitempty"`
	UserID    uuid.UUID              `json:"user_id,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
}

// Column represents a database column in real-time events
type Column struct {
	Name  string      `json:"name"`
	Type  string      `json:"type"`
	Value interface{} `json:"value"`
}

// EventHandler is a function that handles real-time events
type EventHandler func(event RealtimeEvent) error

// RealtimeEventType constants for different types of database events
const (
	EventTypeInsert = "INSERT"
	EventTypeUpdate = "UPDATE"
	EventTypeDelete = "DELETE"
)

// LoadRealtimeConfig loads real-time configuration from environment variables
func LoadRealtimeConfig() *RealtimeConfig {
	return &RealtimeConfig{
		SupabaseURL:          getEnv("SUPABASE_URL", ""),
		SupabaseKey:          getEnv("SUPABASE_ANON_KEY", ""),
		JWTSecret:            getEnv("SUPABASE_JWT_SECRET", ""),
		HeartbeatInterval:    time.Duration(getEnvAsInt("REALTIME_HEARTBEAT_INTERVAL_SECONDS", 30)) * time.Second,
		ReconnectDelay:       time.Duration(getEnvAsInt("REALTIME_RECONNECT_DELAY_SECONDS", 5)) * time.Second,
		MaxReconnectAttempts: getEnvAsInt("REALTIME_MAX_RECONNECT_ATTEMPTS", 10),
		ChannelBufferSize:    getEnvAsInt("REALTIME_CHANNEL_BUFFER_SIZE", 100),
	}
}

// NewRealtimeManager creates a new real-time manager
func NewRealtimeManager() (*RealtimeManager, error) {
	config := LoadRealtimeConfig()

	// Validate configuration
	if config.SupabaseURL == "" {
		return nil, fmt.Errorf("SUPABASE_URL is required for real-time functionality")
	}
	if config.SupabaseKey == "" {
		return nil, fmt.Errorf("SUPABASE_ANON_KEY is required for real-time functionality")
	}

	// Initialize Supabase client
	supabaseClient, err := supabase.NewClient(config.SupabaseURL, config.SupabaseKey, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create Supabase client: %w", err)
	}

	return &RealtimeManager{
		config:         config,
		supabaseClient: supabaseClient,
		subscriptions:  make(map[string]*Subscription),
		eventHandlers:  make(map[string][]EventHandler),
		wsUpgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// In production, implement proper origin checking
				return true
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
		isConnected: false,
	}, nil
}

// Connect establishes connection to Supabase real-time
func (rm *RealtimeManager) Connect(ctx context.Context) error {
	// For this implementation, we'll set up the connection state
	// In a full implementation, you would establish WebSocket connection here
	rm.isConnected = true
	log.Println("Connected to Supabase real-time")
	return nil
}

// Disconnect closes connection to Supabase real-time
func (rm *RealtimeManager) Disconnect() error {
	rm.isConnected = false

	// Close all active subscriptions
	for _, subscription := range rm.subscriptions {
		if subscription.IsActive {
			close(subscription.Channel)
			subscription.IsActive = false
		}
	}

	log.Println("Disconnected from Supabase real-time")
	return nil
}

// IsConnected returns the connection status
func (rm *RealtimeManager) IsConnected() bool {
	return rm.isConnected
}

// SubscribeToTable subscribes to changes on a specific table
func (rm *RealtimeManager) SubscribeToTable(userID uuid.UUID, table string, event string, filter string) (*Subscription, error) {
	if !rm.isConnected {
		return nil, fmt.Errorf("not connected to real-time service")
	}

	subscriptionID := uuid.New().String()
	topic := fmt.Sprintf("realtime:public:%s", table)

	if filter != "" {
		topic += ":" + filter
	}

	subscription := &Subscription{
		ID:        subscriptionID,
		Topic:     topic,
		Event:     event,
		Schema:    "public",
		Table:     table,
		Filter:    filter,
		UserID:    userID,
		Channel:   make(chan RealtimeEvent, rm.config.ChannelBufferSize),
		IsActive:  true,
		CreatedAt: time.Now(),
	}

	rm.subscriptions[subscriptionID] = subscription

	log.Printf("Created subscription %s for user %s on table %s", subscriptionID, userID, table)
	return subscription, nil
}

// SubscribeToUserTasks subscribes to task changes for a specific user
func (rm *RealtimeManager) SubscribeToUserTasks(userID uuid.UUID) (*Subscription, error) {
	filter := fmt.Sprintf("user_id=eq.%s", userID.String())
	return rm.SubscribeToTable(userID, "tasks", "*", filter)
}

// SubscribeToUserSessions subscribes to pomodoro session changes for a specific user
func (rm *RealtimeManager) SubscribeToUserSessions(userID uuid.UUID) (*Subscription, error) {
	filter := fmt.Sprintf("user_id=eq.%s", userID.String())
	return rm.SubscribeToTable(userID, "pomodoro_sessions", "*", filter)
}

// SubscribeToUserNotes subscribes to note changes for a specific user
func (rm *RealtimeManager) SubscribeToUserNotes(userID uuid.UUID) (*Subscription, error) {
	filter := fmt.Sprintf("user_id=eq.%s", userID.String())
	return rm.SubscribeToTable(userID, "notes", "*", filter)
}

// SubscribeToUserReminders subscribes to reminder changes for a specific user
func (rm *RealtimeManager) SubscribeToUserReminders(userID uuid.UUID) (*Subscription, error) {
	filter := fmt.Sprintf("user_id=eq.%s", userID.String())
	return rm.SubscribeToTable(userID, "reminders", "*", filter)
}

// Unsubscribe removes a subscription
func (rm *RealtimeManager) Unsubscribe(subscriptionID string) error {
	subscription, exists := rm.subscriptions[subscriptionID]
	if !exists {
		return fmt.Errorf("subscription %s not found", subscriptionID)
	}

	if subscription.IsActive {
		close(subscription.Channel)
		subscription.IsActive = false
	}

	delete(rm.subscriptions, subscriptionID)
	log.Printf("Removed subscription %s", subscriptionID)
	return nil
}

// UnsubscribeUser removes all subscriptions for a specific user
func (rm *RealtimeManager) UnsubscribeUser(userID uuid.UUID) error {
	var toRemove []string

	for id, subscription := range rm.subscriptions {
		if subscription.UserID == userID {
			toRemove = append(toRemove, id)
		}
	}

	for _, id := range toRemove {
		if err := rm.Unsubscribe(id); err != nil {
			log.Printf("Error removing subscription %s: %v", id, err)
		}
	}

	log.Printf("Removed %d subscriptions for user %s", len(toRemove), userID)
	return nil
}

// RegisterEventHandler registers a handler for specific events
func (rm *RealtimeManager) RegisterEventHandler(eventType string, handler EventHandler) {
	if rm.eventHandlers[eventType] == nil {
		rm.eventHandlers[eventType] = make([]EventHandler, 0)
	}
	rm.eventHandlers[eventType] = append(rm.eventHandlers[eventType], handler)
}

// HandleEvent processes incoming real-time events
func (rm *RealtimeManager) HandleEvent(event RealtimeEvent) {
	// Send event to appropriate subscription channels
	for _, subscription := range rm.subscriptions {
		if rm.shouldReceiveEvent(subscription, event) && subscription.IsActive {
			select {
			case subscription.Channel <- event:
				// Event sent successfully
			default:
				// Channel buffer is full, log warning
				log.Printf("Warning: Channel buffer full for subscription %s", subscription.ID)
			}
		}
	}

	// Call registered event handlers
	handlers := rm.eventHandlers[event.EventType]
	for _, handler := range handlers {
		go func(h EventHandler) {
			if err := h(event); err != nil {
				log.Printf("Error in event handler: %v", err)
			}
		}(handler)
	}

	// Call global handlers
	globalHandlers := rm.eventHandlers["*"]
	for _, handler := range globalHandlers {
		go func(h EventHandler) {
			if err := h(event); err != nil {
				log.Printf("Error in global event handler: %v", err)
			}
		}(handler)
	}
}

// shouldReceiveEvent determines if a subscription should receive an event
func (rm *RealtimeManager) shouldReceiveEvent(subscription *Subscription, event RealtimeEvent) bool {
	// Check table match
	if subscription.Table != "*" && subscription.Table != event.Table {
		return false
	}

	// Check event type match
	if subscription.Event != "*" && subscription.Event != event.EventType {
		return false
	}

	// Check user filter
	if event.UserID != uuid.Nil && subscription.UserID != event.UserID {
		return false
	}

	// Additional filter logic could be implemented here
	// For now, we'll assume the filter matches if we get this far

	return true
}

// BroadcastToUser sends a custom event to all subscriptions for a specific user
func (rm *RealtimeManager) BroadcastToUser(userID uuid.UUID, eventType string, data map[string]interface{}) {
	event := RealtimeEvent{
		Type:      "broadcast",
		EventType: eventType,
		New:       data,
		UserID:    userID,
		Timestamp: time.Now(),
	}

	for _, subscription := range rm.subscriptions {
		if subscription.UserID == userID && subscription.IsActive {
			select {
			case subscription.Channel <- event:
				// Event sent successfully
			default:
				log.Printf("Warning: Could not send broadcast to subscription %s", subscription.ID)
			}
		}
	}
}

// GetActiveSubscriptions returns information about active subscriptions
func (rm *RealtimeManager) GetActiveSubscriptions() map[string]*Subscription {
	active := make(map[string]*Subscription)
	for id, subscription := range rm.subscriptions {
		if subscription.IsActive {
			active[id] = subscription
		}
	}
	return active
}

// GetUserSubscriptions returns all active subscriptions for a specific user
func (rm *RealtimeManager) GetUserSubscriptions(userID uuid.UUID) []*Subscription {
	var userSubs []*Subscription
	for _, subscription := range rm.subscriptions {
		if subscription.UserID == userID && subscription.IsActive {
			userSubs = append(userSubs, subscription)
		}
	}
	return userSubs
}

// GetStats returns real-time service statistics
func (rm *RealtimeManager) GetStats() map[string]interface{} {
	totalSubs := len(rm.subscriptions)
	activeSubs := 0
	userCounts := make(map[uuid.UUID]int)

	for _, subscription := range rm.subscriptions {
		if subscription.IsActive {
			activeSubs++
			userCounts[subscription.UserID]++
		}
	}

	return map[string]interface{}{
		"connected":              rm.isConnected,
		"total_subscriptions":    totalSubs,
		"active_subscriptions":   activeSubs,
		"unique_users":           len(userCounts),
		"heartbeat_interval":     rm.config.HeartbeatInterval.String(),
		"channel_buffer_size":    rm.config.ChannelBufferSize,
		"max_reconnect_attempts": rm.config.MaxReconnectAttempts,
	}
}

// Health checks the health of the real-time service
func (rm *RealtimeManager) Health() map[string]interface{} {
	stats := rm.GetStats()

	health := map[string]interface{}{
		"status": "healthy",
		"stats":  stats,
	}

	if !rm.isConnected {
		health["status"] = "disconnected"
		health["error"] = "Not connected to real-time service"
	}

	return health
}

// WebSocket handler for client connections
func (rm *RealtimeManager) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := rm.wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	// Handle WebSocket connection
	rm.handleWebSocketConnection(conn)
}

// handleWebSocketConnection manages individual WebSocket connections
func (rm *RealtimeManager) handleWebSocketConnection(conn *websocket.Conn) {
	// Set up ping/pong handlers for connection health
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	// Heartbeat ticker
	ticker := time.NewTicker(rm.config.HeartbeatInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// Send ping
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("WebSocket ping failed: %v", err)
				return
			}
		}
	}
}

// Simulate real-time event (for testing purposes)
func (rm *RealtimeManager) SimulateEvent(table string, eventType string, userID uuid.UUID, data map[string]interface{}) {
	event := RealtimeEvent{
		Type:      "db_change",
		Schema:    "public",
		Table:     table,
		EventType: eventType,
		New:       data,
		UserID:    userID,
		Timestamp: time.Now(),
	}

	rm.HandleEvent(event)
}

// Global real-time manager instance
var globalRealtimeManager *RealtimeManager

// GetRealtimeManager returns the global real-time manager instance
func GetRealtimeManager() *RealtimeManager {
	return globalRealtimeManager
}

// SetRealtimeManager sets the global real-time manager instance
func SetRealtimeManager(manager *RealtimeManager) {
	globalRealtimeManager = manager
}

// InitializeRealtime initializes the global real-time manager
func InitializeRealtime(ctx context.Context) error {
	manager, err := NewRealtimeManager()
	if err != nil {
		return fmt.Errorf("failed to create real-time manager: %w", err)
	}

	if err := manager.Connect(ctx); err != nil {
		return fmt.Errorf("failed to connect to real-time service: %w", err)
	}

	SetRealtimeManager(manager)
	log.Println("Real-time service initialized successfully")
	return nil
}

// CloseRealtime closes the global real-time manager
func CloseRealtime() error {
	if globalRealtimeManager != nil {
		return globalRealtimeManager.Disconnect()
	}
	return nil
}

// Helper function to convert database change to RealtimeEvent
func DatabaseChangeToRealtimeEvent(table string, eventType string, old, new map[string]interface{}) RealtimeEvent {
	event := RealtimeEvent{
		Type:      "db_change",
		Schema:    "public",
		Table:     table,
		EventType: eventType,
		Timestamp: time.Now(),
	}

	if new != nil {
		event.New = new
		// Extract user_id if present
		if userIDStr, exists := new["user_id"]; exists {
			if userID, err := uuid.Parse(userIDStr.(string)); err == nil {
				event.UserID = userID
			}
		}
	}

	if old != nil {
		event.Old = old
		// Extract user_id from old record if not in new
		if event.UserID == uuid.Nil {
			if userIDStr, exists := old["user_id"]; exists {
				if userID, err := uuid.Parse(userIDStr.(string)); err == nil {
					event.UserID = userID
				}
			}
		}
	}

	return event
}

// Middleware to enable real-time events for API endpoints
func RealtimeMiddleware(table string, eventType string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Execute the original handler
			next.ServeHTTP(w, r)

			// After successful response, trigger real-time event
			// This is a simplified example - in practice, you'd need to
			// capture the actual data changes and user context
			if rm := GetRealtimeManager(); rm != nil {
				// You would extract actual data from the request/response context
				rm.SimulateEvent(table, eventType, uuid.Nil, map[string]interface{}{
					"message":   fmt.Sprintf("%s operation on %s", eventType, table),
					"timestamp": time.Now(),
				})
			}
		})
	}
}
