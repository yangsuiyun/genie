// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod api;
mod models;
mod storage;
mod tray;
mod notifications;
mod startup;

use tauri::{
    CustomMenuItem, Manager, SystemTray, SystemTrayEvent, SystemTrayMenu, SystemTrayMenuItem,
    WindowBuilder, WindowUrl,
};
use storage::StorageManager;
use tray::TrayManager;
use notifications::NotificationManager;
use startup::StartupManager;

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
async fn get_tasks(storage: tauri::State<'_, StorageManager>) -> Result<Vec<models::Task>, String> {
    storage.get_all_tasks().await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn create_task(
    storage: tauri::State<'_, StorageManager>,
    task: models::CreateTaskRequest,
) -> Result<models::Task, String> {
    storage.create_task(task).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn update_task(
    storage: tauri::State<'_, StorageManager>,
    task_id: String,
    updates: models::UpdateTaskRequest,
) -> Result<models::Task, String> {
    storage.update_task(&task_id, updates).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn delete_task(
    storage: tauri::State<'_, StorageManager>,
    task_id: String,
) -> Result<(), String> {
    storage.delete_task(&task_id).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn start_pomodoro_session(
    storage: tauri::State<'_, StorageManager>,
    task_id: Option<String>,
    session_type: models::SessionType,
    duration_minutes: u32,
) -> Result<models::PomodoroSession, String> {
    storage
        .create_pomodoro_session(task_id, session_type, duration_minutes)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn update_pomodoro_session(
    storage: tauri::State<'_, StorageManager>,
    session_id: String,
    updates: models::UpdateSessionRequest,
) -> Result<models::PomodoroSession, String> {
    storage
        .update_pomodoro_session(&session_id, updates)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn get_pomodoro_sessions(
    storage: tauri::State<'_, StorageManager>,
    task_id: Option<String>,
    start_date: Option<String>,
    end_date: Option<String>,
) -> Result<Vec<models::PomodoroSession>, String> {
    storage
        .get_pomodoro_sessions(task_id, start_date, end_date)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn get_settings(storage: tauri::State<'_, StorageManager>) -> Result<models::Settings, String> {
    storage.get_settings().await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn update_settings(
    storage: tauri::State<'_, StorageManager>,
    settings: models::Settings,
) -> Result<(), String> {
    storage.update_settings(settings).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn show_notification(
    notification_manager: tauri::State<'_, NotificationManager>,
    title: String,
    body: String,
    icon: Option<String>,
) -> Result<(), String> {
    notification_manager
        .show_notification(&title, &body, icon.as_deref())
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn schedule_notification(
    notification_manager: tauri::State<'_, NotificationManager>,
    title: String,
    body: String,
    delay_seconds: u64,
    icon: Option<String>,
) -> Result<String, String> {
    notification_manager
        .schedule_notification(&title, &body, delay_seconds, icon.as_deref())
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn cancel_notification(
    notification_manager: tauri::State<'_, NotificationManager>,
    notification_id: String,
) -> Result<(), String> {
    notification_manager
        .cancel_notification(&notification_id)
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
async fn set_startup_enabled(
    startup_manager: tauri::State<'_, StartupManager>,
    enabled: bool,
) -> Result<(), String> {
    if enabled {
        startup_manager.enable_startup().map_err(|e| e.to_string())
    } else {
        startup_manager.disable_startup().map_err(|e| e.to_string())
    }
}

#[tauri::command]
async fn is_startup_enabled(startup_manager: tauri::State<'_, StartupManager>) -> Result<bool, String> {
    startup_manager.is_startup_enabled().map_err(|e| e.to_string())
}

#[tauri::command]
async fn minimize_to_tray(app_handle: tauri::AppHandle) -> Result<(), String> {
    if let Some(window) = app_handle.get_window("main") {
        window.hide().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
async fn show_window(app_handle: tauri::AppHandle) -> Result<(), String> {
    if let Some(window) = app_handle.get_window("main") {
        window.show().map_err(|e| e.to_string())?;
        window.set_focus().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
async fn export_data(storage: tauri::State<'_, StorageManager>) -> Result<String, String> {
    storage.export_all_data().await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn import_data(
    storage: tauri::State<'_, StorageManager>,
    data: String,
) -> Result<(), String> {
    storage.import_data(&data).await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn sync_with_server(
    storage: tauri::State<'_, StorageManager>,
    api_base_url: String,
    auth_token: String,
) -> Result<models::SyncResult, String> {
    api::sync_data(&storage, &api_base_url, &auth_token)
        .await
        .map_err(|e| e.to_string())
}

fn create_system_tray() -> SystemTray {
    let quit = CustomMenuItem::new("quit".to_string(), "Quit");
    let show = CustomMenuItem::new("show".to_string(), "Show");
    let start_timer = CustomMenuItem::new("start_timer".to_string(), "Start Timer");
    let pause_timer = CustomMenuItem::new("pause_timer".to_string(), "Pause Timer");

    let tray_menu = SystemTrayMenu::new()
        .add_item(show)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(start_timer)
        .add_item(pause_timer)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(quit);

    SystemTray::new().with_menu(tray_menu)
}

async fn handle_system_tray_event(app: &tauri::AppHandle, event: SystemTrayEvent) {
    match event {
        SystemTrayEvent::LeftClick {
            position: _,
            size: _,
            ..
        } => {
            if let Some(window) = app.get_window("main") {
                if window.is_visible().unwrap_or(false) {
                    let _ = window.hide();
                } else {
                    let _ = window.show();
                    let _ = window.set_focus();
                }
            }
        }
        SystemTrayEvent::MenuItemClick { id, .. } => {
            match id.as_str() {
                "quit" => {
                    std::process::exit(0);
                }
                "show" => {
                    if let Some(window) = app.get_window("main") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                }
                "start_timer" => {
                    // Emit event to frontend to start timer
                    if let Some(window) = app.get_window("main") {
                        let _ = window.emit("tray-start-timer", ());
                    }
                }
                "pause_timer" => {
                    // Emit event to frontend to pause timer
                    if let Some(window) = app.get_window("main") {
                        let _ = window.emit("tray-pause-timer", ());
                    }
                }
                _ => {}
            }
        }
        _ => {}
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize storage
    let storage_manager = StorageManager::new().await?;

    // Initialize notification manager
    let notification_manager = NotificationManager::new().await?;

    // Initialize tray manager
    let tray_manager = TrayManager::new();

    // Initialize startup manager
    let startup_manager = StartupManager::new();

    let context = tauri::generate_context!();

    tauri::Builder::default()
        .manage(storage_manager)
        .manage(notification_manager)
        .manage(tray_manager)
        .manage(startup_manager)
        .system_tray(create_system_tray())
        .on_system_tray_event(handle_system_tray_event)
        .invoke_handler(tauri::generate_handler![
            get_tasks,
            create_task,
            update_task,
            delete_task,
            start_pomodoro_session,
            update_pomodoro_session,
            get_pomodoro_sessions,
            get_settings,
            update_settings,
            show_notification,
            schedule_notification,
            cancel_notification,
            set_startup_enabled,
            is_startup_enabled,
            minimize_to_tray,
            show_window,
            export_data,
            import_data,
            sync_with_server,
        ])
        .setup(|app| {
            // Create main window
            let window = WindowBuilder::new(
                app,
                "main",
                WindowUrl::App("index.html".into())
            )
            .title("Pomodoro - Task & Time Management")
            .inner_size(1200.0, 800.0)
            .min_inner_size(800.0, 600.0)
            .center()
            .resizable(true)
            .decorations(true)
            .transparent(false)
            .always_on_top(false)
            .skip_taskbar(false)
            .build()?;

            // Handle window close event (minimize to tray instead of quit)
            let app_handle = app.handle();
            window.on_window_event(move |event| {
                match event {
                    tauri::WindowEvent::CloseRequested { api, .. } => {
                        // Prevent the default close behavior
                        api.prevent_close();

                        // Hide the window instead
                        if let Some(window) = app_handle.get_window("main") {
                            let _ = window.hide();
                        }
                    }
                    _ => {}
                }
            });

            // Set up periodic tasks
            let app_handle = app.handle();
            tokio::spawn(async move {
                let mut interval = tokio::time::interval(std::time::Duration::from_secs(60));
                loop {
                    interval.tick().await;

                    // Emit periodic update event for frontend timers
                    if let Some(window) = app_handle.get_window("main") {
                        let _ = window.emit("periodic-update", ());
                    }
                }
            });

            Ok(())
        })
        .on_window_event(|event| match event.event() {
            tauri::WindowEvent::Focused(is_focused) => {
                if *is_focused {
                    // Window gained focus
                    println!("Window focused");
                }
            }
            _ => {}
        })
        .run(context)?;

    Ok(())
}