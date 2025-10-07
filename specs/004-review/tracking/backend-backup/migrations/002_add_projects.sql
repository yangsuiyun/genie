-- ============================================
-- Migration 002: Add Project Management
-- ============================================

BEGIN;

-- Step 1: Create projects table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_projects_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_project_name_length CHECK (LENGTH(TRIM(name)) >= 1 AND LENGTH(name) <= 255),
  CONSTRAINT chk_project_description_length CHECK (description IS NULL OR LENGTH(description) <= 2000)
);

-- Step 2: Create indexes
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE UNIQUE INDEX idx_projects_user_name ON projects(user_id, name);
CREATE UNIQUE INDEX idx_projects_is_default ON projects(user_id, is_default) WHERE is_default = true;

-- Step 3: Create default "Inbox" project for all existing users
INSERT INTO projects (user_id, name, description, is_default, is_completed)
SELECT
  u.id,
  'Inbox',
  'Default project for tasks',
  true,
  false
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM projects p WHERE p.user_id = u.id AND p.is_default = true
);

-- Step 4: Add project_id to tasks (nullable first)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS project_id UUID;

-- Step 5: Backfill all existing tasks to user's Inbox project
UPDATE tasks t
SET project_id = p.id
FROM projects p
WHERE p.user_id = t.user_id
  AND p.is_default = true
  AND t.project_id IS NULL;

-- Step 6: Make project_id NOT NULL
ALTER TABLE tasks ALTER COLUMN project_id SET NOT NULL;

-- Step 7: Add FK constraint for tasks
ALTER TABLE tasks
  ADD CONSTRAINT fk_tasks_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Step 8: Create task indexes
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_project_completed ON tasks(project_id, is_completed);

-- Step 9: Add project_id to pomodoro_sessions
ALTER TABLE pomodoro_sessions ADD COLUMN IF NOT EXISTS project_id UUID;

-- Step 10: Backfill sessions from their task's project
UPDATE pomodoro_sessions ps
SET project_id = t.project_id
FROM tasks t
WHERE t.id = ps.task_id
  AND ps.project_id IS NULL;

-- Step 11: Make session project_id NOT NULL
ALTER TABLE pomodoro_sessions ALTER COLUMN project_id SET NOT NULL;

-- Step 12: Add FK constraint for sessions
ALTER TABLE pomodoro_sessions
  ADD CONSTRAINT fk_sessions_project
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

-- Step 13: Create session indexes
CREATE INDEX idx_sessions_project_id ON pomodoro_sessions(project_id);
CREATE INDEX idx_sessions_project_completed ON pomodoro_sessions(project_id, is_completed);

-- Step 14: Create trigger to sync session project_id when task moves
CREATE OR REPLACE FUNCTION sync_session_project_id()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.task_id != NEW.task_id THEN
    SELECT project_id INTO NEW.project_id
    FROM tasks WHERE id = NEW.task_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_session_project_id
  BEFORE INSERT OR UPDATE ON pomodoro_sessions
  FOR EACH ROW EXECUTE FUNCTION sync_session_project_id();

-- Step 15: Prevent default project deletion
CREATE OR REPLACE FUNCTION prevent_default_project_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_default = true THEN
    RAISE EXCEPTION 'Cannot delete default project';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_default_project_deletion
  BEFORE DELETE ON projects
  FOR EACH ROW EXECUTE FUNCTION prevent_default_project_deletion();

-- Step 16: Update updated_at trigger for projects
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

COMMIT;