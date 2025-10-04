-- Create recurrence rules table
CREATE TABLE IF NOT EXISTS recurrence_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern VARCHAR(50) NOT NULL CHECK (pattern IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')),
    frequency INTEGER NOT NULL DEFAULT 1 CHECK (frequency > 0),
    interval_unit VARCHAR(20) CHECK (interval_unit IN ('days', 'weeks', 'months', 'years')),
    days_of_week INTEGER[] CHECK (
        days_of_week IS NULL OR
        (array_length(days_of_week, 1) > 0 AND
         array_length(days_of_week, 1) <= 7 AND
         NOT EXISTS (SELECT 1 FROM unnest(days_of_week) AS day WHERE day < 0 OR day > 6))
    ),
    day_of_month INTEGER CHECK (day_of_month IS NULL OR (day_of_month >= 1 AND day_of_month <= 31)),
    month_of_year INTEGER CHECK (month_of_year IS NULL OR (month_of_year >= 1 AND month_of_year <= 12)),
    end_type VARCHAR(20) NOT NULL DEFAULT 'never' CHECK (end_type IN ('never', 'after_count', 'until_date')),
    end_count INTEGER CHECK (end_count IS NULL OR end_count > 0),
    end_date DATE,
    exceptions DATE[],
    custom_rrule TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for recurrence rules
CREATE INDEX IF NOT EXISTS idx_recurrence_rules_pattern ON recurrence_rules(pattern);
CREATE INDEX IF NOT EXISTS idx_recurrence_rules_end_type ON recurrence_rules(end_type);
CREATE INDEX IF NOT EXISTS idx_recurrence_rules_created_at ON recurrence_rules(created_at);

-- Create trigger for recurrence rules table
CREATE TRIGGER update_recurrence_rules_updated_at
    BEFORE UPDATE ON recurrence_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE recurrence_rules IS 'Flexible recurrence patterns for tasks and reminders';
COMMENT ON COLUMN recurrence_rules.pattern IS 'Type of recurrence pattern';
COMMENT ON COLUMN recurrence_rules.frequency IS 'How often the pattern repeats (e.g., every 2 weeks)';
COMMENT ON COLUMN recurrence_rules.days_of_week IS 'Array of days (0=Sunday, 6=Saturday) for weekly patterns';
COMMENT ON COLUMN recurrence_rules.exceptions IS 'Array of dates to exclude from recurrence';
COMMENT ON COLUMN recurrence_rules.custom_rrule IS 'RFC 5545 RRULE for complex patterns';