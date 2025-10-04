use reqwest::{Client, Method};
use serde_json::{json, Value};
use std::collections::HashMap;

use crate::models::{SyncResult, Task, PomodoroSession};
use crate::storage::StorageManager;

pub struct ApiClient {
    client: Client,
    base_url: String,
    auth_token: Option<String>,
}

impl ApiClient {
    pub fn new(base_url: String) -> Self {
        Self {
            client: Client::new(),
            base_url,
            auth_token: None,
        }
    }

    pub fn set_auth_token(&mut self, token: String) {
        self.auth_token = Some(token);
    }

    pub async fn request(
        &self,
        method: Method,
        endpoint: &str,
        body: Option<Value>,
    ) -> Result<Value, Box<dyn std::error::Error>> {
        let url = format!("{}{}", self.base_url, endpoint);
        let mut request = self.client.request(method, &url);

        // Add authentication header if available
        if let Some(ref token) = self.auth_token {
            request = request.header("Authorization", format!("Bearer {}", token));
        }

        // Add JSON body if provided
        if let Some(body) = body {
            request = request.json(&body);
        }

        let response = request.send().await?;
        let status = response.status();

        if status.is_success() {
            let response_body: Value = response.json().await?;
            Ok(response_body)
        } else {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            Err(format!("API request failed with status {}: {}", status, error_text).into())
        }
    }

    pub async fn get(&self, endpoint: &str) -> Result<Value, Box<dyn std::error::Error>> {
        self.request(Method::GET, endpoint, None).await
    }

    pub async fn post(&self, endpoint: &str, body: Value) -> Result<Value, Box<dyn std::error::Error>> {
        self.request(Method::POST, endpoint, Some(body)).await
    }

    pub async fn put(&self, endpoint: &str, body: Value) -> Result<Value, Box<dyn std::error::Error>> {
        self.request(Method::PUT, endpoint, Some(body)).await
    }

    pub async fn delete(&self, endpoint: &str) -> Result<Value, Box<dyn std::error::Error>> {
        self.request(Method::DELETE, endpoint, None).await
    }
}

pub async fn sync_data(
    storage: &StorageManager,
    api_base_url: &str,
    auth_token: &str,
) -> Result<SyncResult, Box<dyn std::error::Error>> {
    let mut api_client = ApiClient::new(api_base_url.to_string());
    api_client.set_auth_token(auth_token.to_string());

    let mut synced_tasks = 0;
    let mut synced_sessions = 0;
    let mut conflicts = 0;
    let mut errors = Vec::new();

    // Sync tasks
    match sync_tasks(storage, &api_client).await {
        Ok((tasks_synced, task_conflicts)) => {
            synced_tasks = tasks_synced;
            conflicts += task_conflicts;
        }
        Err(e) => {
            errors.push(format!("Task sync error: {}", e));
        }
    }

    // Sync pomodoro sessions
    match sync_pomodoro_sessions(storage, &api_client).await {
        Ok((sessions_synced, session_conflicts)) => {
            synced_sessions = sessions_synced;
            conflicts += session_conflicts;
        }
        Err(e) => {
            errors.push(format!("Session sync error: {}", e));
        }
    }

    // Sync settings
    if let Err(e) = sync_settings(storage, &api_client).await {
        errors.push(format!("Settings sync error: {}", e));
    }

    Ok(SyncResult {
        success: errors.is_empty(),
        synced_tasks,
        synced_sessions,
        conflicts,
        errors,
        last_sync: chrono::Utc::now(),
    })
}

async fn sync_tasks(
    storage: &StorageManager,
    api_client: &ApiClient,
) -> Result<(u32, u32), Box<dyn std::error::Error>> {
    let local_tasks = storage.get_all_tasks().await?;
    let mut synced_count = 0;
    let mut conflicts = 0;

    // Get remote tasks
    let remote_response = api_client.get("/sync/tasks").await?;
    let remote_tasks: Vec<Task> = if let Some(tasks_array) = remote_response.get("tasks") {
        serde_json::from_value(tasks_array.clone())?
    } else {
        Vec::new()
    };

    // Create maps for easier lookup
    let mut local_task_map: HashMap<String, &Task> = local_tasks
        .iter()
        .map(|task| (task.id.clone(), task))
        .collect();

    let remote_task_map: HashMap<String, &Task> = remote_tasks
        .iter()
        .map(|task| (task.id.clone(), task))
        .collect();

    // Sync remote tasks to local
    for remote_task in &remote_tasks {
        if let Some(local_task) = local_task_map.get(&remote_task.id) {
            // Compare timestamps to determine which is newer
            if remote_task.updated_at > local_task.updated_at {
                // Remote is newer, update local
                storage.update_task(
                    &remote_task.id,
                    crate::models::UpdateTaskRequest {
                        title: Some(remote_task.title.clone()),
                        description: remote_task.description.clone(),
                        status: Some(remote_task.status.clone()),
                        priority: Some(remote_task.priority.clone()),
                        due_date: remote_task.due_date,
                        tags: Some(remote_task.tags.clone()),
                        estimated_pomodoros: Some(remote_task.estimated_pomodoros),
                        completed_pomodoros: Some(remote_task.completed_pomodoros),
                    },
                ).await?;
                synced_count += 1;
            } else if local_task.updated_at > remote_task.updated_at {
                // Local is newer, upload to remote
                let task_json = serde_json::to_value(local_task)?;
                api_client.put(&format!("/tasks/{}", local_task.id), task_json).await?;
                synced_count += 1;
            } else {
                // Same timestamp, check if content differs
                let local_json = serde_json::to_value(local_task)?;
                let remote_json = serde_json::to_value(remote_task)?;
                if local_json != remote_json {
                    conflicts += 1;
                    // For now, prefer remote in case of conflicts
                    storage.update_task(
                        &remote_task.id,
                        crate::models::UpdateTaskRequest {
                            title: Some(remote_task.title.clone()),
                            description: remote_task.description.clone(),
                            status: Some(remote_task.status.clone()),
                            priority: Some(remote_task.priority.clone()),
                            due_date: remote_task.due_date,
                            tags: Some(remote_task.tags.clone()),
                            estimated_pomodoros: Some(remote_task.estimated_pomodoros),
                            completed_pomodoros: Some(remote_task.completed_pomodoros),
                        },
                    ).await?;
                }
            }
            // Remove from local map to track what's been processed
            local_task_map.remove(&remote_task.id);
        } else {
            // New remote task, create locally
            storage.create_task(crate::models::CreateTaskRequest {
                title: remote_task.title.clone(),
                description: remote_task.description.clone(),
                priority: Some(remote_task.priority.clone()),
                due_date: remote_task.due_date,
                tags: Some(remote_task.tags.clone()),
                estimated_pomodoros: Some(remote_task.estimated_pomodoros),
            }).await?;
            synced_count += 1;
        }
    }

    // Upload remaining local tasks that don't exist remotely
    for (_, local_task) in local_task_map {
        let task_json = serde_json::to_value(local_task)?;
        api_client.post("/tasks", task_json).await?;
        synced_count += 1;
    }

    Ok((synced_count, conflicts))
}

async fn sync_pomodoro_sessions(
    storage: &StorageManager,
    api_client: &ApiClient,
) -> Result<(u32, u32), Box<dyn std::error::Error>> {
    let local_sessions = storage.get_pomodoro_sessions(None, None, None).await?;
    let mut synced_count = 0;
    let mut conflicts = 0;

    // Get remote sessions
    let remote_response = api_client.get("/sync/pomodoro-sessions").await?;
    let remote_sessions: Vec<PomodoroSession> = if let Some(sessions_array) = remote_response.get("sessions") {
        serde_json::from_value(sessions_array.clone())?
    } else {
        Vec::new()
    };

    // Create maps for easier lookup
    let mut local_session_map: HashMap<String, &PomodoroSession> = local_sessions
        .iter()
        .map(|session| (session.id.clone(), session))
        .collect();

    let remote_session_map: HashMap<String, &PomodoroSession> = remote_sessions
        .iter()
        .map(|session| (session.id.clone(), session))
        .collect();

    // Sync remote sessions to local
    for remote_session in &remote_sessions {
        if let Some(local_session) = local_session_map.get(&remote_session.id) {
            // Compare timestamps to determine which is newer
            if remote_session.updated_at > local_session.updated_at {
                // Remote is newer, update local
                storage.update_pomodoro_session(
                    &remote_session.id,
                    crate::models::UpdateSessionRequest {
                        state: Some(remote_session.state.clone()),
                        remaining_seconds: Some(remote_session.remaining_seconds),
                        started_at: remote_session.started_at,
                        paused_at: remote_session.paused_at,
                        completed_at: remote_session.completed_at,
                        rating: remote_session.rating,
                        notes: remote_session.notes.clone(),
                    },
                ).await?;
                synced_count += 1;
            } else if local_session.updated_at > remote_session.updated_at {
                // Local is newer, upload to remote
                let session_json = serde_json::to_value(local_session)?;
                api_client.put(&format!("/pomodoro/sessions/{}", local_session.id), session_json).await?;
                synced_count += 1;
            } else {
                // Same timestamp, check if content differs
                let local_json = serde_json::to_value(local_session)?;
                let remote_json = serde_json::to_value(remote_session)?;
                if local_json != remote_json {
                    conflicts += 1;
                    // For now, prefer remote in case of conflicts
                    storage.update_pomodoro_session(
                        &remote_session.id,
                        crate::models::UpdateSessionRequest {
                            state: Some(remote_session.state.clone()),
                            remaining_seconds: Some(remote_session.remaining_seconds),
                            started_at: remote_session.started_at,
                            paused_at: remote_session.paused_at,
                            completed_at: remote_session.completed_at,
                            rating: remote_session.rating,
                            notes: remote_session.notes.clone(),
                        },
                    ).await?;
                }
            }
            local_session_map.remove(&remote_session.id);
        } else {
            // New remote session, create locally
            storage.create_pomodoro_session(
                remote_session.task_id.clone(),
                remote_session.session_type.clone(),
                remote_session.duration_minutes,
            ).await?;
            synced_count += 1;
        }
    }

    // Upload remaining local sessions that don't exist remotely
    for (_, local_session) in local_session_map {
        let session_json = serde_json::to_value(local_session)?;
        api_client.post("/pomodoro/sessions", session_json).await?;
        synced_count += 1;
    }

    Ok((synced_count, conflicts))
}

async fn sync_settings(
    storage: &StorageManager,
    api_client: &ApiClient,
) -> Result<(), Box<dyn std::error::Error>> {
    // Get local settings
    let local_settings = storage.get_settings().await?;

    // Get remote settings
    let remote_response = api_client.get("/sync/settings").await?;
    let remote_settings: crate::models::Settings = if let Some(settings) = remote_response.get("settings") {
        serde_json::from_value(settings.clone())?
    } else {
        // If no remote settings, upload local settings
        let settings_json = serde_json::to_value(&local_settings)?;
        api_client.post("/sync/settings", settings_json).await?;
        return Ok(());
    };

    // For settings, we'll use a simple last-write-wins strategy
    // In a more sophisticated implementation, you might want to merge specific settings
    // or ask the user to choose

    // For now, prefer remote settings
    storage.update_settings(remote_settings).await?;

    Ok(())
}

pub async fn upload_crash_report(
    api_base_url: &str,
    crash_info: &str,
    app_version: &str,
    os_info: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let api_client = ApiClient::new(api_base_url.to_string());

    let crash_report = json!({
        "crash_info": crash_info,
        "app_version": app_version,
        "os_info": os_info,
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "platform": "desktop-tauri"
    });

    api_client.post("/crashes", crash_report).await?;
    Ok(())
}

pub async fn check_for_updates(
    api_base_url: &str,
    current_version: &str,
) -> Result<Option<UpdateInfo>, Box<dyn std::error::Error>> {
    let api_client = ApiClient::new(api_base_url.to_string());

    let response = api_client.get(&format!("/updates/check?version={}&platform=desktop", current_version)).await?;

    if let Some(update_available) = response.get("update_available") {
        if update_available.as_bool().unwrap_or(false) {
            let update_info = UpdateInfo {
                version: response.get("version").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                download_url: response.get("download_url").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                release_notes: response.get("release_notes").and_then(|v| v.as_str()).unwrap_or("").to_string(),
                is_critical: response.get("is_critical").and_then(|v| v.as_bool()).unwrap_or(false),
            };
            return Ok(Some(update_info));
        }
    }

    Ok(None)
}

#[derive(Debug, Clone)]
pub struct UpdateInfo {
    pub version: String,
    pub download_url: String,
    pub release_notes: String,
    pub is_critical: bool,
}

impl UpdateInfo {
    pub fn to_json(&self) -> serde_json::Value {
        json!({
            "version": self.version,
            "download_url": self.download_url,
            "release_notes": self.release_notes,
            "is_critical": self.is_critical
        })
    }
}