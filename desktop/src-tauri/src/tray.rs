use std::collections::HashMap;
use tauri::{
    AppHandle, CustomMenuItem, Manager, SystemTray, SystemTrayEvent, SystemTrayMenu,
    SystemTrayMenuItem, SystemTraySubmenu,
};

pub struct TrayManager {
    menu_items: HashMap<String, String>,
}

impl TrayManager {
    pub fn new() -> Self {
        Self {
            menu_items: HashMap::new(),
        }
    }

    pub fn create_system_tray() -> SystemTray {
        let show_hide = CustomMenuItem::new("show_hide".to_string(), "Show/Hide Window");
        let separator1 = SystemTrayMenuItem::Separator;

        // Timer controls
        let start_work = CustomMenuItem::new("start_work".to_string(), "Start Work Session");
        let start_short_break = CustomMenuItem::new("start_short_break".to_string(), "Start Short Break");
        let start_long_break = CustomMenuItem::new("start_long_break".to_string(), "Start Long Break");
        let pause_resume = CustomMenuItem::new("pause_resume".to_string(), "Pause/Resume Timer");
        let stop_timer = CustomMenuItem::new("stop_timer".to_string(), "Stop Timer");

        let timer_submenu = SystemTraySubmenu::new(
            "Timer",
            SystemTrayMenu::new()
                .add_item(start_work)
                .add_item(start_short_break)
                .add_item(start_long_break)
                .add_native_item(SystemTrayMenuItem::Separator)
                .add_item(pause_resume)
                .add_item(stop_timer),
        );

        // Quick actions
        let new_task = CustomMenuItem::new("new_task".to_string(), "New Task");
        let view_tasks = CustomMenuItem::new("view_tasks".to_string(), "View Tasks");
        let view_stats = CustomMenuItem::new("view_stats".to_string(), "View Statistics");

        let quick_actions_submenu = SystemTraySubmenu::new(
            "Quick Actions",
            SystemTrayMenu::new()
                .add_item(new_task)
                .add_item(view_tasks)
                .add_item(view_stats),
        );

        // Settings
        let preferences = CustomMenuItem::new("preferences".to_string(), "Preferences");
        let about = CustomMenuItem::new("about".to_string(), "About");
        let separator2 = SystemTrayMenuItem::Separator;
        let quit = CustomMenuItem::new("quit".to_string(), "Quit Pomodoro");

        let tray_menu = SystemTrayMenu::new()
            .add_item(show_hide)
            .add_native_item(separator1)
            .add_submenu(timer_submenu)
            .add_submenu(quick_actions_submenu)
            .add_native_item(separator2)
            .add_item(preferences)
            .add_item(about)
            .add_native_item(SystemTrayMenuItem::Separator)
            .add_item(quit);

        SystemTray::new().with_menu(tray_menu)
    }

    pub async fn handle_system_tray_event(app: &AppHandle, event: SystemTrayEvent) {
        match event {
            SystemTrayEvent::LeftClick { position: _, size: _, .. } => {
                Self::toggle_window_visibility(app).await;
            }
            SystemTrayEvent::RightClick { position: _, size: _, .. } => {
                // Right click will show the context menu automatically
            }
            SystemTrayEvent::DoubleClick { position: _, size: _, .. } => {
                Self::show_window(app).await;
            }
            SystemTrayEvent::MenuItemClick { id, .. } => {
                Self::handle_menu_click(app, &id).await;
            }
            _ => {}
        }
    }

    async fn toggle_window_visibility(app: &AppHandle) {
        if let Some(window) = app.get_window("main") {
            match window.is_visible() {
                Ok(true) => {
                    let _ = window.hide();
                }
                _ => {
                    let _ = window.show();
                    let _ = window.set_focus();
                    let _ = window.unminimize();
                }
            }
        }
    }

    async fn show_window(app: &AppHandle) {
        if let Some(window) = app.get_window("main") {
            let _ = window.show();
            let _ = window.set_focus();
            let _ = window.unminimize();
        }
    }

    async fn handle_menu_click(app: &AppHandle, menu_id: &str) {
        match menu_id {
            "show_hide" => {
                Self::toggle_window_visibility(app).await;
            }
            "start_work" => {
                Self::emit_timer_event(app, "start-work-session").await;
            }
            "start_short_break" => {
                Self::emit_timer_event(app, "start-short-break").await;
            }
            "start_long_break" => {
                Self::emit_timer_event(app, "start-long-break").await;
            }
            "pause_resume" => {
                Self::emit_timer_event(app, "pause-resume-timer").await;
            }
            "stop_timer" => {
                Self::emit_timer_event(app, "stop-timer").await;
            }
            "new_task" => {
                Self::show_window(app).await;
                Self::emit_ui_event(app, "show-new-task-dialog").await;
            }
            "view_tasks" => {
                Self::show_window(app).await;
                Self::emit_ui_event(app, "navigate-to-tasks").await;
            }
            "view_stats" => {
                Self::show_window(app).await;
                Self::emit_ui_event(app, "navigate-to-statistics").await;
            }
            "preferences" => {
                Self::show_window(app).await;
                Self::emit_ui_event(app, "show-preferences").await;
            }
            "about" => {
                Self::emit_ui_event(app, "show-about-dialog").await;
            }
            "quit" => {
                std::process::exit(0);
            }
            _ => {
                println!("Unknown menu item clicked: {}", menu_id);
            }
        }
    }

    async fn emit_timer_event(app: &AppHandle, event_name: &str) {
        if let Some(window) = app.get_window("main") {
            let _ = window.emit(event_name, ());
        }
    }

    async fn emit_ui_event(app: &AppHandle, event_name: &str) {
        if let Some(window) = app.get_window("main") {
            let _ = window.emit(event_name, ());
        }
    }

    pub fn update_timer_status(&mut self, app: &AppHandle, is_running: bool, session_type: Option<&str>) {
        let pause_resume_text = if is_running { "Pause Timer" } else { "Resume Timer" };

        if let Some(window) = app.get_window("main") {
            // Update the tray menu item text
            // Note: Tauri doesn't support dynamic menu updates easily,
            // so we emit an event to update the UI state instead
            let _ = window.emit("tray-timer-status-changed", serde_json::json!({
                "is_running": is_running,
                "session_type": session_type,
                "pause_resume_text": pause_resume_text
            }));
        }
    }

    pub fn update_task_count(&mut self, app: &AppHandle, pending_tasks: u32, completed_today: u32) {
        if let Some(window) = app.get_window("main") {
            let _ = window.emit("tray-task-count-changed", serde_json::json!({
                "pending_tasks": pending_tasks,
                "completed_today": completed_today
            }));
        }
    }

    pub fn show_tray_notification(&self, title: &str, body: &str) {
        // For system tray notifications, we can use the system's notification system
        // This would integrate with the NotificationManager
        println!("Tray notification: {} - {}", title, body);
    }

    pub fn set_tray_icon(&self, app: &AppHandle, icon_path: &str) {
        if let Some(tray) = app.tray_handle() {
            // Update tray icon based on timer state
            // Note: Icon updates would require the icon files to be bundled
            let _ = tray.set_icon(tauri::Icon::Raw(include_bytes!("../icons/icon.png").to_vec()));
        }
    }

    pub fn set_tray_tooltip(&self, app: &AppHandle, tooltip: &str) {
        if let Some(tray) = app.tray_handle() {
            let _ = tray.set_tooltip(tooltip);
        }
    }

    pub fn update_tray_for_timer_state(
        &mut self,
        app: &AppHandle,
        is_running: bool,
        session_type: Option<&str>,
        remaining_time: Option<&str>,
    ) {
        // Update tooltip with current timer info
        let tooltip = if is_running {
            if let (Some(session), Some(time)) = (session_type, remaining_time) {
                format!("Pomodoro - {} session: {} remaining", session, time)
            } else {
                "Pomodoro - Timer running".to_string()
            }
        } else {
            "Pomodoro - Timer stopped".to_string()
        };

        self.set_tray_tooltip(app, &tooltip);

        // Update timer status for menu items
        self.update_timer_status(app, is_running, session_type);

        // Change icon based on state (work vs break vs stopped)
        let icon_name = match (is_running, session_type) {
            (true, Some("work")) => "timer-work",
            (true, Some("short_break")) => "timer-break",
            (true, Some("long_break")) => "timer-break",
            (true, _) => "timer-running",
            (false, _) => "timer-stopped",
        };

        // Note: Icon switching would be implemented here with actual icon files
        println!("Would switch tray icon to: {}", icon_name);
    }

    pub fn flash_tray_icon(&self, app: &AppHandle) {
        // Flash the tray icon to get user attention
        // This could be implemented with a timer that switches between icons
        if let Some(tray) = app.tray_handle() {
            // Implementation would flash the icon
            println!("Flashing tray icon for attention");
        }
    }

    pub fn add_recent_task_to_menu(&mut self, app: &AppHandle, task_id: &str, task_title: &str) {
        // Store recent task for dynamic menu updates
        self.menu_items.insert(
            format!("recent_task_{}", task_id),
            task_title.to_string(),
        );

        // Emit event to update UI with recent tasks
        if let Some(window) = app.get_window("main") {
            let _ = window.emit("tray-recent-task-added", serde_json::json!({
                "task_id": task_id,
                "task_title": task_title
            }));
        }
    }

    pub fn remove_task_from_menu(&mut self, app: &AppHandle, task_id: &str) {
        self.menu_items.remove(&format!("recent_task_{}", task_id));

        if let Some(window) = app.get_window("main") {
            let _ = window.emit("tray-recent-task-removed", serde_json::json!({
                "task_id": task_id
            }));
        }
    }

    pub fn show_timer_complete_actions(&self, app: &AppHandle, session_type: &str) {
        // Show context-specific actions when timer completes
        let next_action = match session_type {
            "work" => "Start Break",
            "short_break" | "long_break" => "Start Work Session",
            _ => "Start Session",
        };

        if let Some(window) = app.get_window("main") {
            let _ = window.emit("tray-timer-complete", serde_json::json!({
                "completed_session": session_type,
                "next_action": next_action
            }));
        }
    }
}