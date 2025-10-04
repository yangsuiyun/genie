-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    verification_token_expires_at TIMESTAMP WITH TIME ZONE,
    reset_token VARCHAR(255),
    reset_token_expires_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create users preferences JSONB column
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{
    "pomodoro": {
        "work_duration": 25,
        "short_break_duration": 5,
        "long_break_duration": 15,
        "sessions_until_long_break": 4,
        "auto_start_breaks": false,
        "auto_start_work": false,
        "sound_enabled": true,
        "sound_volume": 50,
        "notification_enabled": true
    },
    "theme": {
        "dark_mode": false,
        "primary_color": "#2563eb",
        "accent_color": "#10b981"
    },
    "language": "en",
    "timezone": "UTC",
    "date_format": "YYYY-MM-DD",
    "time_format": "24h",
    "week_start": "monday",
    "task_defaults": {
        "estimated_pomodoros": 1,
        "priority": "medium",
        "reminder_minutes": 10
    }
}'::JSONB;

-- Create indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_verification_token ON users(verification_token);
CREATE INDEX IF NOT EXISTS idx_users_reset_token ON users(reset_token);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users(deleted_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE users IS 'Application users with authentication and preferences';
COMMENT ON COLUMN users.preferences IS 'User preferences stored as JSONB for flexibility';
COMMENT ON COLUMN users.verification_token IS 'Email verification token';
COMMENT ON COLUMN users.reset_token IS 'Password reset token';