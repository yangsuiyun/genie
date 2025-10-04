use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tauri::{AppHandle, Manager};
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration, Instant};
use uuid::Uuid;

use crate::models::{Notification, NotificationType};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScheduledNotification {
    pub id: String,
    pub title: String,
    pub body: String,
    pub icon: Option<String>,
    pub scheduled_time: DateTime<Utc>,
    pub notification_type: NotificationType,
    pub task_id: Option<String>,
    pub session_id: Option<String>,
}

pub struct NotificationManager {
    scheduled_notifications: Arc<Mutex<HashMap<String, ScheduledNotification>>>,
    app_handle: Option<AppHandle>,
}

impl NotificationManager {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Ok(Self {
            scheduled_notifications: Arc::new(Mutex::new(HashMap::new())),
            app_handle: None,
        })
    }

    pub fn set_app_handle(&mut self, app_handle: AppHandle) {
        self.app_handle = Some(app_handle);
    }

    pub async fn show_notification(
        &self,
        title: &str,
        body: &str,
        icon: Option<&str>,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Show immediate notification using Tauri's notification API
        if let Some(app) = &self.app_handle {
            let notification = tauri::api::notification::Notification::new(&app.config().tauri.bundle.identifier)
                .title(title)
                .body(body);

            let notification = if let Some(icon_path) = icon {
                notification.icon(icon_path)
            } else {
                notification
            };

            notification.show()?;

            // Also emit event to frontend for in-app notifications
            if let Some(window) = app.get_window("main") {
                let _ = window.emit("notification-received", serde_json::json!({
                    "title": title,
                    "body": body,
                    "icon": icon,
                    "timestamp": Utc::now().to_rfc3339()
                }));
            }
        }

        Ok(())
    }

    pub async fn schedule_notification(
        &self,
        title: &str,
        body: &str,
        delay_seconds: u64,
        icon: Option<&str>,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let notification_id = Uuid::new_v4().to_string();
        let scheduled_time = Utc::now() + chrono::Duration::seconds(delay_seconds as i64);

        let scheduled_notification = ScheduledNotification {
            id: notification_id.clone(),
            title: title.to_string(),
            body: body.to_string(),
            icon: icon.map(|s| s.to_string()),
            scheduled_time,
            notification_type: NotificationType::PomodoroComplete,
            task_id: None,
            session_id: None,
        };

        // Store the scheduled notification
        {
            let mut notifications = self.scheduled_notifications.lock().await;
            notifications.insert(notification_id.clone(), scheduled_notification.clone());
        }

        // Schedule the notification delivery
        let notifications = self.scheduled_notifications.clone();
        let app_handle = self.app_handle.clone();
        let notification_id_clone = notification_id.clone();

        tokio::spawn(async move {
            sleep(Duration::from_secs(delay_seconds)).await;

            // Check if notification is still scheduled (not cancelled)
            let notification = {
                let mut notifications = notifications.lock().await;
                notifications.remove(&notification_id_clone)
            };

            if let Some(notification) = notification {
                // Show the notification
                if let Some(app) = app_handle {
                    let tauri_notification = tauri::api::notification::Notification::new(
                        &app.config().tauri.bundle.identifier,
                    )
                    .title(&notification.title)
                    .body(&notification.body);

                    let tauri_notification = if let Some(icon_path) = &notification.icon {
                        tauri_notification.icon(icon_path)
                    } else {
                        tauri_notification
                    };

                    let _ = tauri_notification.show();

                    // Emit event to frontend
                    if let Some(window) = app.get_window("main") {
                        let _ = window.emit("scheduled-notification-delivered", serde_json::json!({
                            "id": notification.id,
                            "title": notification.title,
                            "body": notification.body,
                            "icon": notification.icon,
                            "type": notification.notification_type,
                            "timestamp": Utc::now().to_rfc3339()
                        }));
                    }
                }
            }
        });

        Ok(notification_id)
    }

    pub async fn cancel_notification(
        &self,
        notification_id: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut notifications = self.scheduled_notifications.lock().await;
        notifications.remove(notification_id);
        Ok(())
    }

    pub async fn schedule_pomodoro_complete_notification(
        &self,
        session_id: &str,
        task_title: &str,
        delay_seconds: u64,
        is_break: bool,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let (title, body) = if is_break {
            (
                "Break Complete! 🎯".to_string(),
                "Ready to start another focused work session?".to_string(),
            )
        } else {
            (
                "Pomodoro Complete! 🍅".to_string(),
                format!("Great work on \"{}\"! Time for a well-deserved break.", task_title),
            )
        };

        let notification_id = Uuid::new_v4().to_string();
        let scheduled_time = Utc::now() + chrono::Duration::seconds(delay_seconds as i64);

        let scheduled_notification = ScheduledNotification {
            id: notification_id.clone(),
            title,
            body,
            icon: Some("timer-complete".to_string()),
            scheduled_time,
            notification_type: if is_break {
                NotificationType::BreakComplete
            } else {
                NotificationType::PomodoroComplete
            },
            task_id: None,
            session_id: Some(session_id.to_string()),
        };

        // Store and schedule
        {
            let mut notifications = self.scheduled_notifications.lock().await;
            notifications.insert(notification_id.clone(), scheduled_notification.clone());
        }

        self.schedule_notification_delivery(scheduled_notification).await;

        Ok(notification_id)
    }

    pub async fn schedule_task_reminder_notification(
        &self,
        task_id: &str,
        task_title: &str,
        reminder_time: DateTime<Utc>,
        custom_message: Option<&str>,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let notification_id = Uuid::new_v4().to_string();

        let body = custom_message
            .map(|msg| msg.to_string())
            .unwrap_or_else(|| format!("Don't forget: {}", task_title));

        let scheduled_notification = ScheduledNotification {
            id: notification_id.clone(),
            title: "Task Reminder 📋".to_string(),
            body,
            icon: Some("task-reminder".to_string()),
            scheduled_time: reminder_time,
            notification_type: NotificationType::TaskReminder,
            task_id: Some(task_id.to_string()),
            session_id: None,
        };

        // Store and schedule
        {
            let mut notifications = self.scheduled_notifications.lock().await;
            notifications.insert(notification_id.clone(), scheduled_notification.clone());
        }

        self.schedule_notification_delivery(scheduled_notification).await;

        Ok(notification_id)
    }

    pub async fn schedule_task_due_notification(
        &self,
        task_id: &str,
        task_title: &str,
        due_time: DateTime<Utc>,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let notification_id = Uuid::new_v4().to_string();

        // Schedule notification 1 hour before due time
        let notification_time = due_time - chrono::Duration::hours(1);

        let scheduled_notification = ScheduledNotification {
            id: notification_id.clone(),
            title: "Task Due Soon ⏰".to_string(),
            body: format!("\"{}\" is due in 1 hour", task_title),
            icon: Some("task-due".to_string()),
            scheduled_time: notification_time,
            notification_type: NotificationType::TaskDue,
            task_id: Some(task_id.to_string()),
            session_id: None,
        };

        // Store and schedule
        {
            let mut notifications = self.scheduled_notifications.lock().await;
            notifications.insert(notification_id.clone(), scheduled_notification.clone());
        }

        self.schedule_notification_delivery(scheduled_notification).await;

        Ok(notification_id)
    }

    pub async fn schedule_daily_summary_notification(
        &self,
        completed_pomodoros: u32,
        completed_tasks: u32,
        total_focus_time_minutes: u32,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let notification_id = Uuid::new_v4().to_string();

        // Schedule for 8 PM today
        let now = Utc::now();
        let notification_time = now
            .date_naive()
            .and_hms_opt(20, 0, 0)
            .unwrap()
            .and_utc();

        let body = format!(
            "Today: {} pomodoros, {} tasks completed, {} minutes focused",
            completed_pomodoros, completed_tasks, total_focus_time_minutes
        );

        let scheduled_notification = ScheduledNotification {
            id: notification_id.clone(),
            title: "Daily Summary 📊".to_string(),
            body,
            icon: Some("daily-summary".to_string()),
            scheduled_time: notification_time,
            notification_type: NotificationType::DailySummary,
            task_id: None,
            session_id: None,
        };

        // Store and schedule
        {
            let mut notifications = self.scheduled_notifications.lock().await;
            notifications.insert(notification_id.clone(), scheduled_notification.clone());
        }

        self.schedule_notification_delivery(scheduled_notification).await;

        Ok(notification_id)
    }

    async fn schedule_notification_delivery(&self, notification: ScheduledNotification) {
        let notifications = self.scheduled_notifications.clone();
        let app_handle = self.app_handle.clone();
        let notification_id = notification.id.clone();

        tokio::spawn(async move {
            let now = Utc::now();
            if notification.scheduled_time > now {
                let delay = notification.scheduled_time - now;
                let delay_seconds = delay.num_seconds().max(0) as u64;
                sleep(Duration::from_secs(delay_seconds)).await;
            }

            // Check if notification is still scheduled (not cancelled)
            let notification = {
                let mut notifications = notifications.lock().await;
                notifications.remove(&notification_id)
            };

            if let Some(notification) = notification {
                if let Some(app) = app_handle {
                    Self::deliver_notification(&app, &notification).await;
                }
            }
        });
    }

    async fn deliver_notification(app: &AppHandle, notification: &ScheduledNotification) {
        // Show system notification
        let tauri_notification = tauri::api::notification::Notification::new(
            &app.config().tauri.bundle.identifier,
        )
        .title(&notification.title)
        .body(&notification.body);

        let tauri_notification = if let Some(icon_path) = &notification.icon {
            tauri_notification.icon(icon_path)
        } else {
            tauri_notification
        };

        let _ = tauri_notification.show();

        // Emit event to frontend
        if let Some(window) = app.get_window("main") {
            let _ = window.emit(
                "notification-delivered",
                serde_json::json!({
                    "id": notification.id,
                    "title": notification.title,
                    "body": notification.body,
                    "icon": notification.icon,
                    "type": notification.notification_type,
                    "task_id": notification.task_id,
                    "session_id": notification.session_id,
                    "timestamp": Utc::now().to_rfc3339()
                }),
            );
        }

        // Handle specific notification types
        match notification.notification_type {
            NotificationType::PomodoroComplete | NotificationType::BreakComplete => {
                if let Some(window) = app.get_window("main") {
                    let _ = window.emit("timer-session-complete", serde_json::json!({
                        "session_id": notification.session_id,
                        "is_break": matches!(notification.notification_type, NotificationType::BreakComplete)
                    }));
                }
            }
            NotificationType::TaskReminder | NotificationType::TaskDue => {
                if let Some(window) = app.get_window("main") {
                    let _ = window.emit("task-reminder-triggered", serde_json::json!({
                        "task_id": notification.task_id,
                        "reminder_type": notification.notification_type
                    }));
                }
            }
            NotificationType::DailySummary => {
                if let Some(window) = app.get_window("main") {
                    let _ = window.emit("daily-summary-notification", ());
                }
            }
        }
    }

    pub async fn cancel_all_notifications_for_task(
        &self,
        task_id: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut notifications = self.scheduled_notifications.lock().await;
        notifications.retain(|_, notification| {
            notification.task_id.as_ref() != Some(&task_id.to_string())
        });
        Ok(())
    }

    pub async fn cancel_all_notifications_for_session(
        &self,
        session_id: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let mut notifications = self.scheduled_notifications.lock().await;
        notifications.retain(|_, notification| {
            notification.session_id.as_ref() != Some(&session_id.to_string())
        });
        Ok(())
    }

    pub async fn get_scheduled_notifications(&self) -> Vec<ScheduledNotification> {
        let notifications = self.scheduled_notifications.lock().await;
        notifications.values().cloned().collect()
    }

    pub async fn clear_all_scheduled_notifications(&self) -> Result<(), Box<dyn std::error::Error>> {
        let mut notifications = self.scheduled_notifications.lock().await;
        notifications.clear();
        Ok(())
    }

    pub async fn show_permission_request(&self) -> Result<bool, Box<dyn std::error::Error>> {
        // Request notification permissions
        if let Some(app) = &self.app_handle {
            // Tauri handles permissions automatically, but we can check if they're granted
            // by attempting to show a test notification
            let test_notification = tauri::api::notification::Notification::new(
                &app.config().tauri.bundle.identifier,
            )
            .title("Notification Test")
            .body("Notifications are working correctly!");

            match test_notification.show() {
                Ok(_) => Ok(true),
                Err(_) => Ok(false),
            }
        } else {
            Ok(false)
        }
    }

    pub async fn update_app_badge(&self, count: u32) -> Result<(), Box<dyn std::error::Error>> {
        // Update app badge with pending task count or pomodoro count
        if let Some(app) = &self.app_handle {
            if let Some(window) = app.get_window("main") {
                let _ = window.emit("update-app-badge", serde_json::json!({
                    "count": count
                }));
            }
        }
        Ok(())
    }

    pub async fn show_critical_notification(
        &self,
        title: &str,
        body: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        // Show a high-priority notification that demands attention
        self.show_notification(title, body, Some("critical-alert")).await?;

        // Also flash tray icon and play sound if possible
        if let Some(app) = &self.app_handle {
            if let Some(window) = app.get_window("main") {
                let _ = window.emit("critical-notification", serde_json::json!({
                    "title": title,
                    "body": body,
                    "timestamp": Utc::now().to_rfc3339()
                }));
            }
        }

        Ok(())
    }
}