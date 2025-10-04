-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    session_id UUID REFERENCES pomodoro_sessions(id) ON DELETE CASCADE,
    title VARCHAR(255),
    content TEXT NOT NULL,
    note_type VARCHAR(20) DEFAULT 'general' CHECK (note_type IN ('general', 'task', 'session', 'reflection', 'idea', 'todo')),
    tags TEXT[] DEFAULT '{}',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    color VARCHAR(7) CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'),
    attachments JSONB DEFAULT '[]'::JSONB,
    sync_version INTEGER DEFAULT 1,
    device_id VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for notes table
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_task_id ON notes(task_id);
CREATE INDEX IF NOT EXISTS idx_notes_session_id ON notes(session_id);
CREATE INDEX IF NOT EXISTS idx_notes_note_type ON notes(note_type);
CREATE INDEX IF NOT EXISTS idx_notes_is_pinned ON notes(is_pinned);
CREATE INDEX IF NOT EXISTS idx_notes_is_archived ON notes(is_archived);
CREATE INDEX IF NOT EXISTS idx_notes_tags ON notes USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_notes_content_fulltext ON notes USING GIN(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_notes_title_fulltext ON notes USING GIN(to_tsvector('english', title)) WHERE title IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at);
CREATE INDEX IF NOT EXISTS idx_notes_deleted_at ON notes(deleted_at);
CREATE INDEX IF NOT EXISTS idx_notes_sync_version ON notes(sync_version);
CREATE INDEX IF NOT EXISTS idx_notes_device_id ON notes(device_id);
CREATE INDEX IF NOT EXISTS idx_notes_last_synced_at ON notes(last_synced_at);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_notes_user_type ON notes(user_id, note_type);
CREATE INDEX IF NOT EXISTS idx_notes_user_pinned ON notes(user_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX IF NOT EXISTS idx_notes_user_archived ON notes(user_id, is_archived);
CREATE INDEX IF NOT EXISTS idx_notes_task_created ON notes(task_id, created_at) WHERE task_id IS NOT NULL;

-- Create trigger for notes table
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function for full-text search
CREATE OR REPLACE FUNCTION search_notes(
    search_user_id UUID,
    search_query TEXT,
    search_limit INTEGER DEFAULT 20,
    search_offset INTEGER DEFAULT 0
)
RETURNS TABLE(
    id UUID,
    title VARCHAR(255),
    content TEXT,
    note_type VARCHAR(20),
    tags TEXT[],
    task_id UUID,
    session_id UUID,
    is_pinned BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        n.id,
        n.title,
        n.content,
        n.note_type,
        n.tags,
        n.task_id,
        n.session_id,
        n.is_pinned,
        n.created_at,
        n.updated_at,
        ts_rank(
            setweight(to_tsvector('english', COALESCE(n.title, '')), 'A') ||
            setweight(to_tsvector('english', n.content), 'B'),
            plainto_tsquery('english', search_query)
        ) as rank
    FROM notes n
    WHERE n.user_id = search_user_id
    AND n.deleted_at IS NULL
    AND n.is_archived = FALSE
    AND (
        to_tsvector('english', COALESCE(n.title, '')) ||
        to_tsvector('english', n.content)
    ) @@ plainto_tsquery('english', search_query)
    ORDER BY rank DESC, n.updated_at DESC
    LIMIT search_limit
    OFFSET search_offset;
END;
$$ LANGUAGE plpgsql;

-- Create function to get related notes
CREATE OR REPLACE FUNCTION get_related_notes(
    note_id UUID,
    relation_limit INTEGER DEFAULT 5
)
RETURNS TABLE(
    id UUID,
    title VARCHAR(255),
    content TEXT,
    note_type VARCHAR(20),
    similarity_score REAL
) AS $$
DECLARE
    source_note RECORD;
    source_vector tsvector;
BEGIN
    -- Get the source note
    SELECT n.title, n.content, n.tags INTO source_note
    FROM notes n
    WHERE n.id = note_id AND n.deleted_at IS NULL;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Create search vector from source note
    source_vector := setweight(to_tsvector('english', COALESCE(source_note.title, '')), 'A') ||
                     setweight(to_tsvector('english', source_note.content), 'B');

    RETURN QUERY
    SELECT
        n.id,
        n.title,
        n.content,
        n.note_type,
        ts_rank(
            setweight(to_tsvector('english', COALESCE(n.title, '')), 'A') ||
            setweight(to_tsvector('english', n.content), 'B'),
            source_vector
        ) as similarity_score
    FROM notes n
    WHERE n.id != note_id
    AND n.deleted_at IS NULL
    AND n.is_archived = FALSE
    AND (
        setweight(to_tsvector('english', COALESCE(n.title, '')), 'A') ||
        setweight(to_tsvector('english', n.content), 'B')
    ) @@ source_vector
    ORDER BY similarity_score DESC
    LIMIT relation_limit;
END;
$$ LANGUAGE plpgsql;

-- Add comments
COMMENT ON TABLE notes IS 'User notes that can be attached to tasks or sessions';
COMMENT ON COLUMN notes.note_type IS 'Type of note for categorization and filtering';
COMMENT ON COLUMN notes.task_id IS 'Optional reference to associated task';
COMMENT ON COLUMN notes.session_id IS 'Optional reference to associated pomodoro session';
COMMENT ON COLUMN notes.is_pinned IS 'Whether note is pinned for quick access';
COMMENT ON COLUMN notes.is_archived IS 'Whether note is archived (hidden from normal view)';
COMMENT ON COLUMN notes.color IS 'Hex color code for note display';
COMMENT ON COLUMN notes.attachments IS 'JSON array of file attachments metadata';
COMMENT ON COLUMN notes.sync_version IS 'Version number for conflict resolution during sync';
COMMENT ON COLUMN notes.device_id IS 'ID of device that last modified this note';
COMMENT ON FUNCTION search_notes IS 'Full-text search function for notes';
COMMENT ON FUNCTION get_related_notes IS 'Find notes related to a given note by content similarity';