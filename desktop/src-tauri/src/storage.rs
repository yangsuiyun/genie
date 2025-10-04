use chrono::{DateTime, Utc};
use rusqlite::{params, Connection, Result as SqliteResult, Row};
use serde_json;
use std::path::PathBuf;
use tokio::sync::Mutex;
use uuid::Uuid;

use crate::models::{
    CreateTaskRequest, PomodoroSession, SessionRow, SessionState, SessionType, Settings, Task,
    TaskPriority, TaskRow, TaskStatus, UpdateSessionRequest, UpdateTaskRequest,
};

pub struct StorageManager {
    db: Mutex<Connection>,
}

impl StorageManager {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let db_path = Self::get_database_path()?;

        // Ensure the parent directory exists
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        let conn = Connection::open(db_path)?;
        let storage_manager = Self {
            db: Mutex::new(conn),
        };

        storage_manager.initialize_database().await?;
        Ok(storage_manager)
    }

    fn get_database_path() -> Result<PathBuf, Box<dyn std::error::Error>> {
        let data_dir = dirs::data_local_dir()
            .ok_or("Could not find local data directory")?
            .join("Pomodoro");

        Ok(data_dir.join("pomodoro.db"))
    }

    async fn initialize_database(&self) -> Result<(), Box<dyn std::error::Error>> {
        let db = self.db.lock().await;

        // Create tasks table
        db.execute(
            "CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                status TEXT NOT NULL DEFAULT 'pending',
                priority TEXT NOT NULL DEFAULT 'medium',
                due_date TEXT,
                tags TEXT NOT NULL DEFAULT '[]',
                estimated_pomodoros INTEGER NOT NULL DEFAULT 1,
                completed_pomodoros INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )",
            [],
        )?;

        // Create pomodoro_sessions table
        db.execute(
            "CREATE TABLE IF NOT EXISTS pomodoro_sessions (
                id TEXT PRIMARY KEY,
                task_id TEXT,
                session_type TEXT NOT NULL,
                state TEXT NOT NULL DEFAULT 'ready',
                duration_minutes INTEGER NOT NULL,
                remaining_seconds INTEGER NOT NULL,
                started_at TEXT,
                paused_at TEXT,
                completed_at TEXT,
                rating INTEGER,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE SET NULL
            )",
            [],
        )?;

        // Create settings table
        db.execute(
            "CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )",
            [],
        )?;

        // Create subtasks table
        db.execute(
            "CREATE TABLE IF NOT EXISTS subtasks (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                title TEXT NOT NULL,
                completed BOOLEAN NOT NULL DEFAULT 0,
                order_index INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
            )",
            [],
        )?;

        // Create notes table
        db.execute(
            "CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
            )",
            [],
        )?;

        // Create reminders table
        db.execute(
            "CREATE TABLE IF NOT EXISTS reminders (
                id TEXT PRIMARY KEY,
                task_id TEXT NOT NULL,
                reminder_time TEXT NOT NULL,
                message TEXT,
                completed BOOLEAN NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
            )",
            [],
        )?;

        // Create indexes for better performance
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks (status)",
            [],
        )?;
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks (due_date)",
            [],
        )?;
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON tasks (updated_at)",
            [],
        )?;
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_sessions_task_id ON pomodoro_sessions (task_id)",
            [],
        )?;
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON pomodoro_sessions (created_at)",
            [],
        )?;
        db.execute(
            "CREATE INDEX IF NOT EXISTS idx_subtasks_task_id ON subtasks (task_id)",
            [],
        )?;

        // Initialize default settings if not exists
        self.initialize_default_settings(&db).await?;

        Ok(())
    }

    async fn initialize_default_settings(&self, db: &Connection) -> Result<(), Box<dyn std::error::Error>> {
        let default_settings = Settings::default();
        let settings_json = serde_json::to_string(&default_settings)?;

        // Check if settings already exist
        let count: i64 = db.query_row("SELECT COUNT(*) FROM settings", [], |row| row.get(0))?;

        if count == 0 {
            // Insert default settings
            let settings_pairs = [
                ("work_duration_minutes", default_settings.work_duration_minutes.to_string()),
                ("short_break_duration_minutes", default_settings.short_break_duration_minutes.to_string()),
                ("long_break_duration_minutes", default_settings.long_break_duration_minutes.to_string()),
                ("long_break_interval", default_settings.long_break_interval.to_string()),
                ("auto_start_breaks", default_settings.auto_start_breaks.to_string()),
                ("auto_start_pomodoros", default_settings.auto_start_pomodoros.to_string()),
                ("enable_notifications", default_settings.enable_notifications.to_string()),
                ("enable_sounds", default_settings.enable_sounds.to_string()),
                ("sound_volume", default_settings.sound_volume.to_string()),
                ("work_end_sound", default_settings.work_end_sound),
                ("break_end_sound", default_settings.break_end_sound),
                ("minimize_to_tray", default_settings.minimize_to_tray.to_string()),
                ("start_minimized", default_settings.start_minimized.to_string()),
                ("close_to_tray", default_settings.close_to_tray.to_string()),
                ("enable_startup", default_settings.enable_startup.to_string()),
                ("theme", default_settings.theme),
                ("language", default_settings.language),
            ];

            for (key, value) in settings_pairs {
                db.execute(
                    "INSERT INTO settings (key, value) VALUES (?1, ?2)",
                    params![key, value],
                )?;
            }
        }

        Ok(())
    }

    // Task operations
    pub async fn get_all_tasks(&self) -> Result<Vec<Task>, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let mut stmt = db.prepare(
            "SELECT id, title, description, status, priority, due_date, tags,
                    estimated_pomodoros, completed_pomodoros, created_at, updated_at
             FROM tasks ORDER BY updated_at DESC"
        )?;

        let task_rows = stmt.query_map([], |row| {
            Ok(TaskRow {
                id: row.get(0)?,
                title: row.get(1)?,
                description: row.get(2)?,
                status: row.get(3)?,
                priority: row.get(4)?,
                due_date: row.get(5)?,
                tags: row.get(6)?,
                estimated_pomodoros: row.get(7)?,
                completed_pomodoros: row.get(8)?,
                created_at: row.get(9)?,
                updated_at: row.get(10)?,
            })
        })?;

        let mut tasks = Vec::new();
        for task_row in task_rows {
            tasks.push(Task::from(task_row?));
        }

        Ok(tasks)
    }

    pub async fn get_task_by_id(&self, task_id: &str) -> Result<Option<Task>, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let mut stmt = db.prepare(
            "SELECT id, title, description, status, priority, due_date, tags,
                    estimated_pomodoros, completed_pomodoros, created_at, updated_at
             FROM tasks WHERE id = ?1"
        )?;

        let task_row = stmt.query_row([task_id], |row| {
            Ok(TaskRow {
                id: row.get(0)?,
                title: row.get(1)?,
                description: row.get(2)?,
                status: row.get(3)?,
                priority: row.get(4)?,
                due_date: row.get(5)?,
                tags: row.get(6)?,
                estimated_pomodoros: row.get(7)?,
                completed_pomodoros: row.get(8)?,
                created_at: row.get(9)?,
                updated_at: row.get(10)?,
            })
        });

        match task_row {
            Ok(row) => Ok(Some(Task::from(row))),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(Box::new(e)),
        }
    }

    pub async fn create_task(&self, request: CreateTaskRequest) -> Result<Task, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let now = Utc::now();
        let task_id = Uuid::new_v4().to_string();

        let tags_json = serde_json::to_string(&request.tags.unwrap_or_default())?;
        let due_date_str = request.due_date.map(|d| d.to_rfc3339());
        let priority_str = request.priority.unwrap_or(TaskPriority::Medium);
        let estimated_pomodoros = request.estimated_pomodoros.unwrap_or(1);

        db.execute(
            "INSERT INTO tasks (id, title, description, status, priority, due_date, tags,
                               estimated_pomodoros, completed_pomodoros, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
            params![
                task_id,
                request.title,
                request.description,
                "pending",
                format!("{:?}", priority_str).to_lowercase(),
                due_date_str,
                tags_json,
                estimated_pomodoros,
                0,
                now.to_rfc3339(),
                now.to_rfc3339(),
            ],
        )?;

        // Return the created task
        Ok(Task {
            id: task_id,
            title: request.title,
            description: request.description,
            status: TaskStatus::Pending,
            priority: priority_str,
            due_date: request.due_date,
            tags: request.tags.unwrap_or_default(),
            estimated_pomodoros,
            completed_pomodoros: 0,
            created_at: now,
            updated_at: now,
        })
    }

    pub async fn update_task(
        &self,
        task_id: &str,
        request: UpdateTaskRequest,
    ) -> Result<Task, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let now = Utc::now();

        // Build dynamic update query
        let mut update_fields = Vec::new();
        let mut params = Vec::new();

        if let Some(title) = &request.title {
            update_fields.push("title = ?");
            params.push(title.clone());
        }
        if let Some(description) = &request.description {
            update_fields.push("description = ?");
            params.push(description.clone());
        }
        if let Some(status) = &request.status {
            update_fields.push("status = ?");
            params.push(format!("{:?}", status).to_lowercase());
        }
        if let Some(priority) = &request.priority {
            update_fields.push("priority = ?");
            params.push(format!("{:?}", priority).to_lowercase());
        }
        if let Some(due_date) = &request.due_date {
            update_fields.push("due_date = ?");
            params.push(due_date.to_rfc3339());
        }
        if let Some(tags) = &request.tags {
            update_fields.push("tags = ?");
            params.push(serde_json::to_string(tags)?);
        }
        if let Some(estimated_pomodoros) = request.estimated_pomodoros {
            update_fields.push("estimated_pomodoros = ?");
            params.push(estimated_pomodoros.to_string());
        }
        if let Some(completed_pomodoros) = request.completed_pomodoros {
            update_fields.push("completed_pomodoros = ?");
            params.push(completed_pomodoros.to_string());
        }

        update_fields.push("updated_at = ?");
        params.push(now.to_rfc3339());
        params.push(task_id.to_string());

        let query = format!(
            "UPDATE tasks SET {} WHERE id = ?",
            update_fields.join(", ")
        );

        let param_refs: Vec<&dyn rusqlite::ToSql> = params.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
        db.execute(&query, param_refs.as_slice())?;

        // Return the updated task
        self.get_task_by_id(task_id).await?.ok_or_else(|| "Task not found after update".into())
    }

    pub async fn delete_task(&self, task_id: &str) -> Result<(), Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        db.execute("DELETE FROM tasks WHERE id = ?1", params![task_id])?;
        Ok(())
    }

    // Pomodoro session operations
    pub async fn create_pomodoro_session(
        &self,
        task_id: Option<String>,
        session_type: SessionType,
        duration_minutes: u32,
    ) -> Result<PomodoroSession, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let now = Utc::now();
        let session_id = Uuid::new_v4().to_string();

        db.execute(
            "INSERT INTO pomodoro_sessions (id, task_id, session_type, state, duration_minutes,
                                           remaining_seconds, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                session_id,
                task_id,
                format!("{:?}", session_type).to_lowercase(),
                "ready",
                duration_minutes,
                duration_minutes * 60,
                now.to_rfc3339(),
                now.to_rfc3339(),
            ],
        )?;

        Ok(PomodoroSession {
            id: session_id,
            task_id,
            session_type,
            state: SessionState::Ready,
            duration_minutes,
            remaining_seconds: duration_minutes * 60,
            started_at: None,
            paused_at: None,
            completed_at: None,
            rating: None,
            notes: None,
            created_at: now,
            updated_at: now,
        })
    }

    pub async fn update_pomodoro_session(
        &self,
        session_id: &str,
        request: UpdateSessionRequest,
    ) -> Result<PomodoroSession, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let now = Utc::now();

        // Build dynamic update query
        let mut update_fields = Vec::new();
        let mut params = Vec::new();

        if let Some(state) = &request.state {
            update_fields.push("state = ?");
            params.push(format!("{:?}", state).to_lowercase());
        }
        if let Some(remaining_seconds) = request.remaining_seconds {
            update_fields.push("remaining_seconds = ?");
            params.push(remaining_seconds.to_string());
        }
        if let Some(started_at) = &request.started_at {
            update_fields.push("started_at = ?");
            params.push(started_at.to_rfc3339());
        }
        if let Some(paused_at) = &request.paused_at {
            update_fields.push("paused_at = ?");
            params.push(paused_at.to_rfc3339());
        }
        if let Some(completed_at) = &request.completed_at {
            update_fields.push("completed_at = ?");
            params.push(completed_at.to_rfc3339());
        }
        if let Some(rating) = request.rating {
            update_fields.push("rating = ?");
            params.push(rating.to_string());
        }
        if let Some(notes) = &request.notes {
            update_fields.push("notes = ?");
            params.push(notes.clone());
        }

        update_fields.push("updated_at = ?");
        params.push(now.to_rfc3339());
        params.push(session_id.to_string());

        let query = format!(
            "UPDATE pomodoro_sessions SET {} WHERE id = ?",
            update_fields.join(", ")
        );

        let param_refs: Vec<&dyn rusqlite::ToSql> = params.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
        db.execute(&query, param_refs.as_slice())?;

        // Return the updated session
        self.get_pomodoro_session_by_id(session_id).await?.ok_or_else(|| "Session not found after update".into())
    }

    pub async fn get_pomodoro_session_by_id(
        &self,
        session_id: &str,
    ) -> Result<Option<PomodoroSession>, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let mut stmt = db.prepare(
            "SELECT id, task_id, session_type, state, duration_minutes, remaining_seconds,
                    started_at, paused_at, completed_at, rating, notes, created_at, updated_at
             FROM pomodoro_sessions WHERE id = ?1"
        )?;

        let session_row = stmt.query_row([session_id], |row| {
            Ok(SessionRow {
                id: row.get(0)?,
                task_id: row.get(1)?,
                session_type: row.get(2)?,
                state: row.get(3)?,
                duration_minutes: row.get(4)?,
                remaining_seconds: row.get(5)?,
                started_at: row.get(6)?,
                paused_at: row.get(7)?,
                completed_at: row.get(8)?,
                rating: row.get(9)?,
                notes: row.get(10)?,
                created_at: row.get(11)?,
                updated_at: row.get(12)?,
            })
        });

        match session_row {
            Ok(row) => Ok(Some(PomodoroSession::from(row))),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(Box::new(e)),
        }
    }

    pub async fn get_pomodoro_sessions(
        &self,
        task_id: Option<String>,
        start_date: Option<String>,
        end_date: Option<String>,
    ) -> Result<Vec<PomodoroSession>, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;

        let mut query = "SELECT id, task_id, session_type, state, duration_minutes, remaining_seconds,
                                started_at, paused_at, completed_at, rating, notes, created_at, updated_at
                         FROM pomodoro_sessions WHERE 1=1".to_string();
        let mut params = Vec::new();

        if let Some(task_id) = task_id {
            query.push_str(" AND task_id = ?");
            params.push(task_id);
        }

        if let Some(start_date) = start_date {
            query.push_str(" AND created_at >= ?");
            params.push(start_date);
        }

        if let Some(end_date) = end_date {
            query.push_str(" AND created_at <= ?");
            params.push(end_date);
        }

        query.push_str(" ORDER BY created_at DESC");

        let mut stmt = db.prepare(&query)?;
        let param_refs: Vec<&dyn rusqlite::ToSql> = params.iter().map(|p| p as &dyn rusqlite::ToSql).collect();

        let session_rows = stmt.query_map(param_refs.as_slice(), |row| {
            Ok(SessionRow {
                id: row.get(0)?,
                task_id: row.get(1)?,
                session_type: row.get(2)?,
                state: row.get(3)?,
                duration_minutes: row.get(4)?,
                remaining_seconds: row.get(5)?,
                started_at: row.get(6)?,
                paused_at: row.get(7)?,
                completed_at: row.get(8)?,
                rating: row.get(9)?,
                notes: row.get(10)?,
                created_at: row.get(11)?,
                updated_at: row.get(12)?,
            })
        })?;

        let mut sessions = Vec::new();
        for session_row in session_rows {
            sessions.push(PomodoroSession::from(session_row?));
        }

        Ok(sessions)
    }

    // Settings operations
    pub async fn get_settings(&self) -> Result<Settings, Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        let mut stmt = db.prepare("SELECT key, value FROM settings")?;

        let rows = stmt.query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?))
        })?;

        let mut settings = Settings::default();

        for row in rows {
            let (key, value) = row?;
            match key.as_str() {
                "work_duration_minutes" => settings.work_duration_minutes = value.parse().unwrap_or(25),
                "short_break_duration_minutes" => settings.short_break_duration_minutes = value.parse().unwrap_or(5),
                "long_break_duration_minutes" => settings.long_break_duration_minutes = value.parse().unwrap_or(15),
                "long_break_interval" => settings.long_break_interval = value.parse().unwrap_or(4),
                "auto_start_breaks" => settings.auto_start_breaks = value.parse().unwrap_or(false),
                "auto_start_pomodoros" => settings.auto_start_pomodoros = value.parse().unwrap_or(false),
                "enable_notifications" => settings.enable_notifications = value.parse().unwrap_or(true),
                "enable_sounds" => settings.enable_sounds = value.parse().unwrap_or(true),
                "sound_volume" => settings.sound_volume = value.parse().unwrap_or(0.8),
                "work_end_sound" => settings.work_end_sound = value,
                "break_end_sound" => settings.break_end_sound = value,
                "minimize_to_tray" => settings.minimize_to_tray = value.parse().unwrap_or(true),
                "start_minimized" => settings.start_minimized = value.parse().unwrap_or(false),
                "close_to_tray" => settings.close_to_tray = value.parse().unwrap_or(true),
                "enable_startup" => settings.enable_startup = value.parse().unwrap_or(false),
                "theme" => settings.theme = value,
                "language" => settings.language = value,
                _ => {}
            }
        }

        Ok(settings)
    }

    pub async fn update_settings(&self, settings: Settings) -> Result<(), Box<dyn std::error::Error>> {
        let db = self.db.lock().await;

        let settings_updates = [
            ("work_duration_minutes", settings.work_duration_minutes.to_string()),
            ("short_break_duration_minutes", settings.short_break_duration_minutes.to_string()),
            ("long_break_duration_minutes", settings.long_break_duration_minutes.to_string()),
            ("long_break_interval", settings.long_break_interval.to_string()),
            ("auto_start_breaks", settings.auto_start_breaks.to_string()),
            ("auto_start_pomodoros", settings.auto_start_pomodoros.to_string()),
            ("enable_notifications", settings.enable_notifications.to_string()),
            ("enable_sounds", settings.enable_sounds.to_string()),
            ("sound_volume", settings.sound_volume.to_string()),
            ("work_end_sound", settings.work_end_sound),
            ("break_end_sound", settings.break_end_sound),
            ("minimize_to_tray", settings.minimize_to_tray.to_string()),
            ("start_minimized", settings.start_minimized.to_string()),
            ("close_to_tray", settings.close_to_tray.to_string()),
            ("enable_startup", settings.enable_startup.to_string()),
            ("theme", settings.theme),
            ("language", settings.language),
        ];

        for (key, value) in settings_updates {
            db.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params![key, value],
            )?;
        }

        Ok(())
    }

    // Data export/import
    pub async fn export_all_data(&self) -> Result<String, Box<dyn std::error::Error>> {
        let tasks = self.get_all_tasks().await?;
        let sessions = self.get_pomodoro_sessions(None, None, None).await?;
        let settings = self.get_settings().await?;

        let export_data = serde_json::json!({
            "version": "1.0",
            "exported_at": Utc::now().to_rfc3339(),
            "tasks": tasks,
            "sessions": sessions,
            "settings": settings
        });

        Ok(serde_json::to_string_pretty(&export_data)?)
    }

    pub async fn import_data(&self, data: &str) -> Result<(), Box<dyn std::error::Error>> {
        let import_data: serde_json::Value = serde_json::from_str(data)?;

        // Import tasks
        if let Some(tasks) = import_data.get("tasks").and_then(|v| v.as_array()) {
            for task_value in tasks {
                if let Ok(task) = serde_json::from_value::<Task>(task_value.clone()) {
                    // Insert or update task
                    let db = self.db.lock().await;
                    let tags_json = serde_json::to_string(&task.tags)?;

                    db.execute(
                        "INSERT OR REPLACE INTO tasks (id, title, description, status, priority, due_date, tags,
                                                      estimated_pomodoros, completed_pomodoros, created_at, updated_at)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
                        params![
                            task.id,
                            task.title,
                            task.description,
                            format!("{:?}", task.status).to_lowercase(),
                            format!("{:?}", task.priority).to_lowercase(),
                            task.due_date.map(|d| d.to_rfc3339()),
                            tags_json,
                            task.estimated_pomodoros,
                            task.completed_pomodoros,
                            task.created_at.to_rfc3339(),
                            task.updated_at.to_rfc3339(),
                        ],
                    )?;
                }
            }
        }

        // Import sessions
        if let Some(sessions) = import_data.get("sessions").and_then(|v| v.as_array()) {
            for session_value in sessions {
                if let Ok(session) = serde_json::from_value::<PomodoroSession>(session_value.clone()) {
                    let db = self.db.lock().await;

                    db.execute(
                        "INSERT OR REPLACE INTO pomodoro_sessions (id, task_id, session_type, state, duration_minutes,
                                                                  remaining_seconds, started_at, paused_at, completed_at,
                                                                  rating, notes, created_at, updated_at)
                         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)",
                        params![
                            session.id,
                            session.task_id,
                            format!("{:?}", session.session_type).to_lowercase(),
                            format!("{:?}", session.state).to_lowercase(),
                            session.duration_minutes,
                            session.remaining_seconds,
                            session.started_at.map(|d| d.to_rfc3339()),
                            session.paused_at.map(|d| d.to_rfc3339()),
                            session.completed_at.map(|d| d.to_rfc3339()),
                            session.rating,
                            session.notes,
                            session.created_at.to_rfc3339(),
                            session.updated_at.to_rfc3339(),
                        ],
                    )?;
                }
            }
        }

        // Import settings
        if let Some(settings_value) = import_data.get("settings") {
            if let Ok(settings) = serde_json::from_value::<Settings>(settings_value.clone()) {
                self.update_settings(settings).await?;
            }
        }

        Ok(())
    }

    // Database maintenance
    pub async fn vacuum_database(&self) -> Result<(), Box<dyn std::error::Error>> {
        let db = self.db.lock().await;
        db.execute("VACUUM", [])?;
        Ok(())
    }

    pub async fn get_database_size(&self) -> Result<u64, Box<dyn std::error::Error>> {
        let db_path = Self::get_database_path()?;
        let metadata = std::fs::metadata(db_path)?;
        Ok(metadata.len())
    }
}