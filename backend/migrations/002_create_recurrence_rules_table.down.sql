-- Drop recurrence rules table
DROP TRIGGER IF EXISTS update_recurrence_rules_updated_at ON recurrence_rules;
DROP TABLE IF EXISTS recurrence_rules CASCADE;