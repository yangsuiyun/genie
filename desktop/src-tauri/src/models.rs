use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub status: TaskStatus,
    pub priority: TaskPriority,
    pub due_date: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
    pub estimated_pomodoros: u32,
    pub completed_pomodoros: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskStatus {
    #[serde(rename = "pending")]
    Pending,
    #[serde(rename = "in_progress")]
    InProgress,
    #[serde(rename = "completed")]
    Completed,
    #[serde(rename = "cancelled")]
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskPriority {
    #[serde(rename = "low")]
    Low,
    #[serde(rename = "medium")]
    Medium,
    #[serde(rename = "high")]
    High,
    #[serde(rename = "urgent")]
    Urgent,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTaskRequest {
    pub title: String,
    pub description: Option<String>,
    pub priority: Option<TaskPriority>,
    pub due_date: Option<DateTime<Utc>>,
    pub tags: Option<Vec<String>>,
    pub estimated_pomodoros: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateTaskRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub status: Option<TaskStatus>,
    pub priority: Option<TaskPriority>,
    pub due_date: Option<DateTime<Utc>>,
    pub tags: Option<Vec<String>>,
    pub estimated_pomodoros: Option<u32>,
    pub completed_pomodoros: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PomodoroSession {
    pub id: String,
    pub task_id: Option<String>,
    pub session_type: SessionType,
    pub state: SessionState,
    pub duration_minutes: u32,
    pub remaining_seconds: u32,
    pub started_at: Option<DateTime<Utc>>,
    pub paused_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub rating: Option<u32>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SessionType {
    #[serde(rename = "work")]
    Work,
    #[serde(rename = "short_break")]
    ShortBreak,
    #[serde(rename = "long_break")]
    LongBreak,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SessionState {
    #[serde(rename = "ready")]
    Ready,
    #[serde(rename = "running")]
    Running,
    #[serde(rename = "paused")]
    Paused,
    #[serde(rename = "completed")]
    Completed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateSessionRequest {
    pub state: Option<SessionState>,
    pub remaining_seconds: Option<u32>,
    pub started_at: Option<DateTime<Utc>>,
    pub paused_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub rating: Option<u32>,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Settings {
    pub work_duration_minutes: u32,
    pub short_break_duration_minutes: u32,
    pub long_break_duration_minutes: u32,
    pub long_break_interval: u32,
    pub auto_start_breaks: bool,
    pub auto_start_pomodoros: bool,
    pub enable_notifications: bool,
    pub enable_sounds: bool,
    pub sound_volume: f32,
    pub work_end_sound: String,
    pub break_end_sound: String,
    pub minimize_to_tray: bool,
    pub start_minimized: bool,
    pub close_to_tray: bool,
    pub enable_startup: bool,
    pub theme: String,
    pub language: String,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            work_duration_minutes: 25,
            short_break_duration_minutes: 5,
            long_break_duration_minutes: 15,
            long_break_interval: 4,
            auto_start_breaks: false,
            auto_start_pomodoros: false,
            enable_notifications: true,
            enable_sounds: true,
            sound_volume: 0.8,
            work_end_sound: "bell".to_string(),
            break_end_sound: "chime".to_string(),
            minimize_to_tray: true,
            start_minimized: false,
            close_to_tray: true,
            enable_startup: false,
            theme: "system".to_string(),
            language: "en".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    pub success: bool,
    pub synced_tasks: u32,
    pub synced_sessions: u32,
    pub conflicts: u32,
    pub errors: Vec<String>,
    pub last_sync: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Notification {
    pub id: String,
    pub title: String,
    pub body: String,
    pub icon: Option<String>,
    pub scheduled_at: DateTime<Utc>,
    pub delivered_at: Option<DateTime<Utc>>,
    pub notification_type: NotificationType,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum NotificationType {
    #[serde(rename = "pomodoro_complete")]
    PomodoroComplete,
    #[serde(rename = "break_complete")]
    BreakComplete,
    #[serde(rename = "task_reminder")]
    TaskReminder,
    #[serde(rename = "task_due")]
    TaskDue,
    #[serde(rename = "daily_summary")]
    DailySummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subtask {
    pub id: String,
    pub task_id: String,
    pub title: String,
    pub completed: bool,
    pub order: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Note {
    pub id: String,
    pub task_id: String,
    pub content: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reminder {
    pub id: String,
    pub task_id: String,
    pub reminder_time: DateTime<Utc>,
    pub message: Option<String>,
    pub completed: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailySummary {
    pub date: DateTime<Utc>,
    pub completed_pomodoros: u32,
    pub completed_tasks: u32,
    pub total_focus_time_minutes: u32,
    pub productivity_score: f32,
    pub top_tasks: Vec<String>,
}

// Database representations (for SQLite)
#[derive(Debug)]
pub struct TaskRow {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub status: String,
    pub priority: String,
    pub due_date: Option<String>,
    pub tags: String, // JSON encoded
    pub estimated_pomodoros: u32,
    pub completed_pomodoros: u32,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug)]
pub struct SessionRow {
    pub id: String,
    pub task_id: Option<String>,
    pub session_type: String,
    pub state: String,
    pub duration_minutes: u32,
    pub remaining_seconds: u32,
    pub started_at: Option<String>,
    pub paused_at: Option<String>,
    pub completed_at: Option<String>,
    pub rating: Option<u32>,
    pub notes: Option<String>,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug)]
pub struct SettingsRow {
    pub key: String,
    pub value: String,
}

impl From<TaskRow> for Task {
    fn from(row: TaskRow) -> Self {
        Self {
            id: row.id,
            title: row.title,
            description: row.description,
            status: match row.status.as_str() {
                "pending" => TaskStatus::Pending,
                "in_progress" => TaskStatus::InProgress,
                "completed" => TaskStatus::Completed,
                "cancelled" => TaskStatus::Cancelled,
                _ => TaskStatus::Pending,
            },
            priority: match row.priority.as_str() {
                "low" => TaskPriority::Low,
                "medium" => TaskPriority::Medium,
                "high" => TaskPriority::High,
                "urgent" => TaskPriority::Urgent,
                _ => TaskPriority::Medium,
            },
            due_date: row.due_date.and_then(|d| d.parse().ok()),
            tags: serde_json::from_str(&row.tags).unwrap_or_default(),
            estimated_pomodoros: row.estimated_pomodoros,
            completed_pomodoros: row.completed_pomodoros,
            created_at: row.created_at.parse().unwrap_or_else(|_| Utc::now()),
            updated_at: row.updated_at.parse().unwrap_or_else(|_| Utc::now()),
        }
    }
}

impl From<SessionRow> for PomodoroSession {
    fn from(row: SessionRow) -> Self {
        Self {
            id: row.id,
            task_id: row.task_id,
            session_type: match row.session_type.as_str() {
                "work" => SessionType::Work,
                "short_break" => SessionType::ShortBreak,
                "long_break" => SessionType::LongBreak,
                _ => SessionType::Work,
            },
            state: match row.state.as_str() {
                "ready" => SessionState::Ready,
                "running" => SessionState::Running,
                "paused" => SessionState::Paused,
                "completed" => SessionState::Completed,
                _ => SessionState::Ready,
            },
            duration_minutes: row.duration_minutes,
            remaining_seconds: row.remaining_seconds,
            started_at: row.started_at.and_then(|d| d.parse().ok()),
            paused_at: row.paused_at.and_then(|d| d.parse().ok()),
            completed_at: row.completed_at.and_then(|d| d.parse().ok()),
            rating: row.rating,
            notes: row.notes,
            created_at: row.created_at.parse().unwrap_or_else(|_| Utc::now()),
            updated_at: row.updated_at.parse().unwrap_or_else(|_| Utc::now()),
        }
    }
}