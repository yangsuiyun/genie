-- Drop notes table and related objects
DROP FUNCTION IF EXISTS get_related_notes(UUID, INTEGER);
DROP FUNCTION IF EXISTS search_notes(UUID, TEXT, INTEGER, INTEGER);
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
DROP TABLE IF EXISTS notes CASCADE;