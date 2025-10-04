package config

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host         string
	Port         int
	User         string
	Password     string
	Database     string
	SSLMode      string
	MaxOpenConns int
	MaxIdleConns int
	MaxLifetime  time.Duration
	MaxIdleTime  time.Duration
}

// Database holds database connections and configuration
type Database struct {
	DB     *gorm.DB
	SqlDB  *sql.DB
	Config *DatabaseConfig
}

// LoadDatabaseConfig loads database configuration from environment variables
func LoadDatabaseConfig() *DatabaseConfig {
	config := &DatabaseConfig{
		Host:         getEnv("SUPABASE_DB_HOST", "localhost"),
		Port:         getEnvAsInt("SUPABASE_DB_PORT", 5432),
		User:         getEnv("SUPABASE_DB_USER", "postgres"),
		Password:     getEnv("SUPABASE_DB_PASSWORD", ""),
		Database:     getEnv("SUPABASE_DB_NAME", "postgres"),
		SSLMode:      getEnv("SUPABASE_DB_SSL_MODE", "require"),
		MaxOpenConns: getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
		MaxIdleConns: getEnvAsInt("DB_MAX_IDLE_CONNS", 5),
		MaxLifetime:  time.Duration(getEnvAsInt("DB_MAX_LIFETIME_MINUTES", 5)) * time.Minute,
		MaxIdleTime:  time.Duration(getEnvAsInt("DB_MAX_IDLE_TIME_MINUTES", 1)) * time.Minute,
	}

	// For Supabase, use the full database URL if provided
	if dbURL := getEnv("SUPABASE_DB_URL", ""); dbURL != "" {
		// Parse Supabase URL format: postgresql://user:password@host:port/database
		config.parseSupabaseURL(dbURL)
	}

	return config
}

// parseSupabaseURL parses Supabase database URL and updates config
func (c *DatabaseConfig) parseSupabaseURL(dbURL string) {
	// This is a simplified parser - in production, use a proper URL parser
	// For now, we'll rely on environment variables being set correctly
	log.Printf("Using Supabase database URL: %s", maskPassword(dbURL))
}

// ConnectDatabase establishes database connection with Supabase
func ConnectDatabase() (*Database, error) {
	config := LoadDatabaseConfig()

	// Build connection string
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host, config.Port, config.User, config.Password, config.Database, config.SSLMode)

	// If using Supabase URL directly
	if dbURL := getEnv("SUPABASE_DB_URL", ""); dbURL != "" {
		dsn = dbURL
	}

	// Configure GORM logger
	gormConfig := &gorm.Config{
		Logger: logger.Default.LogMode(getLogLevel()),
	}

	// Connect to database
	db, err := gorm.Open(postgres.Open(dsn), gormConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Get underlying sql.DB for connection pooling
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Configure connection pool
	sqlDB.SetMaxOpenConns(config.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.MaxLifetime)
	sqlDB.SetConnMaxIdleTime(config.MaxIdleTime)

	// Test connection
	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Printf("Successfully connected to Supabase database at %s:%d", config.Host, config.Port)

	return &Database{
		DB:     db,
		SqlDB:  sqlDB,
		Config: config,
	}, nil
}

// Close closes database connections
func (d *Database) Close() error {
	if d.SqlDB != nil {
		return d.SqlDB.Close()
	}
	return nil
}

// Ping tests database connectivity
func (d *Database) Ping() error {
	return d.SqlDB.Ping()
}

// GetStats returns database connection statistics
func (d *Database) GetStats() sql.DBStats {
	return d.SqlDB.Stats()
}

// RunMigrations runs database migrations
func (d *Database) RunMigrations(migrationsPath string) error {
	driver, err := postgres.WithInstance(d.SqlDB, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create migration driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", migrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migration instance: %w", err)
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	log.Println("Database migrations completed successfully")
	return nil
}

// RollbackMigrations rolls back database migrations
func (d *Database) RollbackMigrations(migrationsPath string, steps int) error {
	driver, err := postgres.WithInstance(d.SqlDB, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create migration driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", migrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migration instance: %w", err)
	}

	if err := m.Steps(-steps); err != nil {
		return fmt.Errorf("failed to rollback migrations: %w", err)
	}

	log.Printf("Successfully rolled back %d migrations", steps)
	return nil
}

// GetMigrationVersion returns current migration version
func (d *Database) GetMigrationVersion(migrationsPath string) (uint, bool, error) {
	driver, err := postgres.WithInstance(d.SqlDB, &postgres.Config{})
	if err != nil {
		return 0, false, fmt.Errorf("failed to create migration driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", migrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		return 0, false, fmt.Errorf("failed to create migration instance: %w", err)
	}

	version, dirty, err := m.Version()
	if err != nil {
		return 0, false, fmt.Errorf("failed to get migration version: %w", err)
	}

	return version, dirty, nil
}

// BeginTransaction starts a new database transaction
func (d *Database) BeginTransaction() *gorm.DB {
	return d.DB.Begin()
}

// WithTransaction executes a function within a database transaction
func (d *Database) WithTransaction(fn func(*gorm.DB) error) error {
	tx := d.DB.Begin()
	if tx.Error != nil {
		return tx.Error
	}

	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			panic(r)
		}
	}()

	if err := fn(tx); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// Health checks database health
func (d *Database) Health() map[string]interface{} {
	stats := d.GetStats()

	health := map[string]interface{}{
		"status":           "healthy",
		"open_connections": stats.OpenConnections,
		"in_use":          stats.InUse,
		"idle":            stats.Idle,
		"max_open_conns":  stats.MaxOpenConnections,
		"max_idle_conns":  d.Config.MaxIdleConns,
		"max_lifetime":    d.Config.MaxLifetime.String(),
		"max_idle_time":   d.Config.MaxIdleTime.String(),
	}

	// Test connection
	if err := d.Ping(); err != nil {
		health["status"] = "unhealthy"
		health["error"] = err.Error()
	}

	return health
}

// SupabaseConfig holds Supabase-specific configuration
type SupabaseConfig struct {
	URL       string
	AnonKey   string
	ServiceKey string
	JWTSecret string
	ProjectRef string
}

// LoadSupabaseConfig loads Supabase configuration from environment variables
func LoadSupabaseConfig() *SupabaseConfig {
	return &SupabaseConfig{
		URL:        getEnv("SUPABASE_URL", ""),
		AnonKey:    getEnv("SUPABASE_ANON_KEY", ""),
		ServiceKey: getEnv("SUPABASE_SERVICE_ROLE_KEY", ""),
		JWTSecret:  getEnv("SUPABASE_JWT_SECRET", ""),
		ProjectRef: getEnv("SUPABASE_PROJECT_REF", ""),
	}
}

// ValidateSupabaseConfig validates Supabase configuration
func (c *SupabaseConfig) Validate() error {
	if c.URL == "" {
		return fmt.Errorf("SUPABASE_URL is required")
	}
	if c.AnonKey == "" {
		return fmt.Errorf("SUPABASE_ANON_KEY is required")
	}
	if c.ServiceKey == "" {
		return fmt.Errorf("SUPABASE_SERVICE_ROLE_KEY is required")
	}
	if c.JWTSecret == "" {
		return fmt.Errorf("SUPABASE_JWT_SECRET is required")
	}
	return nil
}

// Helper functions

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getLogLevel() logger.LogLevel {
	switch getEnv("DB_LOG_LEVEL", "warn") {
	case "silent":
		return logger.Silent
	case "error":
		return logger.Error
	case "warn":
		return logger.Warn
	case "info":
		return logger.Info
	default:
		return logger.Warn
	}
}

func maskPassword(dsn string) string {
	// Simple password masking for logging
	// In production, use a more robust URL parser
	return "postgresql://user:***@host:port/database"
}

// Database utilities for testing

// CreateTestDatabase creates a test database instance
func CreateTestDatabase() (*Database, error) {
	// Override config for testing
	os.Setenv("SUPABASE_DB_NAME", "test_pomodoro")
	os.Setenv("DB_MAX_OPEN_CONNS", "5")
	os.Setenv("DB_MAX_IDLE_CONNS", "2")

	return ConnectDatabase()
}

// CleanupTestDatabase cleans up test database
func CleanupTestDatabase(db *Database) error {
	// Drop all tables for testing
	tables := []string{
		"reports", "reminders", "notes", "pomodoro_sessions",
		"subtasks", "tasks", "recurrence_rules", "users",
	}

	for _, table := range tables {
		if err := db.DB.Exec(fmt.Sprintf("DROP TABLE IF EXISTS %s CASCADE", table)).Error; err != nil {
			log.Printf("Warning: failed to drop table %s: %v", table, err)
		}
	}

	return db.Close()
}

// Global database instance (singleton pattern for application)
var globalDB *Database

// GetDB returns the global database instance
func GetDB() *Database {
	return globalDB
}

// SetDB sets the global database instance
func SetDB(db *Database) {
	globalDB = db
}

// InitializeDatabase initializes the global database connection
func InitializeDatabase() error {
	db, err := ConnectDatabase()
	if err != nil {
		return err
	}

	SetDB(db)
	return nil
}

// CloseDatabase closes the global database connection
func CloseDatabase() error {
	if globalDB != nil {
		return globalDB.Close()
	}
	return nil
}