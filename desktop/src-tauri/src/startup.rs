use std::env;
use std::fs;
use std::path::PathBuf;

#[cfg(target_os = "windows")]
use std::process::Command;

#[cfg(target_os = "macos")]
use std::process::Command;

pub struct StartupManager;

impl StartupManager {
    pub fn new() -> Self {
        Self
    }

    pub fn enable_startup(&self) -> Result<(), Box<dyn std::error::Error>> {
        match std::env::consts::OS {
            "windows" => self.enable_startup_windows(),
            "macos" => self.enable_startup_macos(),
            "linux" => self.enable_startup_linux(),
            _ => Err("Unsupported operating system".into()),
        }
    }

    pub fn disable_startup(&self) -> Result<(), Box<dyn std::error::Error>> {
        match std::env::consts::OS {
            "windows" => self.disable_startup_windows(),
            "macos" => self.disable_startup_macos(),
            "linux" => self.disable_startup_linux(),
            _ => Err("Unsupported operating system".into()),
        }
    }

    pub fn is_startup_enabled(&self) -> Result<bool, Box<dyn std::error::Error>> {
        match std::env::consts::OS {
            "windows" => self.is_startup_enabled_windows(),
            "macos" => self.is_startup_enabled_macos(),
            "linux" => self.is_startup_enabled_linux(),
            _ => Err("Unsupported operating system".into()),
        }
    }

    #[cfg(target_os = "windows")]
    fn enable_startup_windows(&self) -> Result<(), Box<dyn std::error::Error>> {
        let app_path = env::current_exe()?;
        let app_name = "Pomodoro";

        // Add to Windows Registry for startup
        let output = Command::new("reg")
            .args([
                "add",
                "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                "/v",
                app_name,
                "/t",
                "REG_SZ",
                "/d",
                &format!("\"{}\" --minimized", app_path.display()),
                "/f",
            ])
            .output()?;

        if output.status.success() {
            Ok(())
        } else {
            Err(format!(
                "Failed to enable startup: {}",
                String::from_utf8_lossy(&output.stderr)
            ).into())
        }
    }

    #[cfg(target_os = "windows")]
    fn disable_startup_windows(&self) -> Result<(), Box<dyn std::error::Error>> {
        let app_name = "Pomodoro";

        let output = Command::new("reg")
            .args([
                "delete",
                "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                "/v",
                app_name,
                "/f",
            ])
            .output()?;

        if output.status.success() {
            Ok(())
        } else {
            // Not an error if the key doesn't exist
            let stderr = String::from_utf8_lossy(&output.stderr);
            if stderr.contains("cannot find") || stderr.contains("not found") {
                Ok(())
            } else {
                Err(format!("Failed to disable startup: {}", stderr).into())
            }
        }
    }

    #[cfg(target_os = "windows")]
    fn is_startup_enabled_windows(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let app_name = "Pomodoro";

        let output = Command::new("reg")
            .args([
                "query",
                "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                "/v",
                app_name,
            ])
            .output()?;

        Ok(output.status.success())
    }

    #[cfg(not(target_os = "windows"))]
    fn enable_startup_windows(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("Windows startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "windows"))]
    fn disable_startup_windows(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("Windows startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "windows"))]
    fn is_startup_enabled_windows(&self) -> Result<bool, Box<dyn std::error::Error>> {
        Err("Windows startup management not available on this platform".into())
    }

    #[cfg(target_os = "macos")]
    fn enable_startup_macos(&self) -> Result<(), Box<dyn std::error::Error>> {
        let app_path = env::current_exe()?;
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let launch_agents_dir = home_dir.join("Library/LaunchAgents");

        // Create LaunchAgents directory if it doesn't exist
        fs::create_dir_all(&launch_agents_dir)?;

        let plist_path = launch_agents_dir.join("com.pomodoro.app.plist");
        let plist_content = format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pomodoro.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>{}</string>
        <string>--minimized</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>LaunchOnlyOnce</key>
    <true/>
</dict>
</plist>"#,
            app_path.display()
        );

        fs::write(&plist_path, plist_content)?;

        // Load the launch agent
        let output = Command::new("launchctl")
            .args(["load", &plist_path.to_string_lossy()])
            .output()?;

        if output.status.success() {
            Ok(())
        } else {
            Err(format!(
                "Failed to load launch agent: {}",
                String::from_utf8_lossy(&output.stderr)
            ).into())
        }
    }

    #[cfg(target_os = "macos")]
    fn disable_startup_macos(&self) -> Result<(), Box<dyn std::error::Error>> {
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let plist_path = home_dir.join("Library/LaunchAgents/com.pomodoro.app.plist");

        if plist_path.exists() {
            // Unload the launch agent
            let _ = Command::new("launchctl")
                .args(["unload", &plist_path.to_string_lossy()])
                .output();

            // Remove the plist file
            fs::remove_file(&plist_path)?;
        }

        Ok(())
    }

    #[cfg(target_os = "macos")]
    fn is_startup_enabled_macos(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let plist_path = home_dir.join("Library/LaunchAgents/com.pomodoro.app.plist");
        Ok(plist_path.exists())
    }

    #[cfg(not(target_os = "macos"))]
    fn enable_startup_macos(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("macOS startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "macos"))]
    fn disable_startup_macos(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("macOS startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "macos"))]
    fn is_startup_enabled_macos(&self) -> Result<bool, Box<dyn std::error::Error>> {
        Err("macOS startup management not available on this platform".into())
    }

    #[cfg(target_os = "linux")]
    fn enable_startup_linux(&self) -> Result<(), Box<dyn std::error::Error>> {
        let app_path = env::current_exe()?;
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let autostart_dir = home_dir.join(".config/autostart");

        // Create autostart directory if it doesn't exist
        fs::create_dir_all(&autostart_dir)?;

        let desktop_file_path = autostart_dir.join("pomodoro.desktop");
        let desktop_content = format!(
            r#"[Desktop Entry]
Type=Application
Name=Pomodoro
Comment=Pomodoro task and time management application
Icon=pomodoro
Exec={} --minimized
Terminal=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
Hidden=false"#,
            app_path.display()
        );

        fs::write(&desktop_file_path, desktop_content)?;

        // Make the file executable
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mut perms = fs::metadata(&desktop_file_path)?.permissions();
            perms.set_mode(0o755);
            fs::set_permissions(&desktop_file_path, perms)?;
        }

        Ok(())
    }

    #[cfg(target_os = "linux")]
    fn disable_startup_linux(&self) -> Result<(), Box<dyn std::error::Error>> {
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let desktop_file_path = home_dir.join(".config/autostart/pomodoro.desktop");

        if desktop_file_path.exists() {
            fs::remove_file(&desktop_file_path)?;
        }

        Ok(())
    }

    #[cfg(target_os = "linux")]
    fn is_startup_enabled_linux(&self) -> Result<bool, Box<dyn std::error::Error>> {
        let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
        let desktop_file_path = home_dir.join(".config/autostart/pomodoro.desktop");
        Ok(desktop_file_path.exists())
    }

    #[cfg(not(target_os = "linux"))]
    fn enable_startup_linux(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("Linux startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "linux"))]
    fn disable_startup_linux(&self) -> Result<(), Box<dyn std::error::Error>> {
        Err("Linux startup management not available on this platform".into())
    }

    #[cfg(not(target_os = "linux"))]
    fn is_startup_enabled_linux(&self) -> Result<bool, Box<dyn std::error::Error>> {
        Err("Linux startup management not available on this platform".into())
    }

    pub fn get_startup_info(&self) -> Result<StartupInfo, Box<dyn std::error::Error>> {
        let enabled = self.is_startup_enabled()?;
        let os = std::env::consts::OS.to_string();

        let method = match os.as_str() {
            "windows" => "Windows Registry".to_string(),
            "macos" => "macOS Launch Agents".to_string(),
            "linux" => "XDG Autostart".to_string(),
            _ => "Unknown".to_string(),
        };

        let location = self.get_startup_location()?;

        Ok(StartupInfo {
            enabled,
            os,
            method,
            location,
        })
    }

    fn get_startup_location(&self) -> Result<String, Box<dyn std::error::Error>> {
        match std::env::consts::OS {
            "windows" => Ok("HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run".to_string()),
            "macos" => {
                let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
                Ok(home_dir.join("Library/LaunchAgents/com.pomodoro.app.plist").to_string_lossy().to_string())
            }
            "linux" => {
                let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
                Ok(home_dir.join(".config/autostart/pomodoro.desktop").to_string_lossy().to_string())
            }
            _ => Ok("Unknown".to_string()),
        }
    }

    pub fn can_manage_startup(&self) -> bool {
        matches!(std::env::consts::OS, "windows" | "macos" | "linux")
    }

    pub fn get_startup_command(&self) -> Result<String, Box<dyn std::error::Error>> {
        let app_path = env::current_exe()?;
        Ok(format!("{} --minimized", app_path.display()))
    }

    pub fn set_startup_delay(&self, delay_seconds: u32) -> Result<(), Box<dyn std::error::Error>> {
        // Note: Startup delay implementation varies by platform
        // This is a placeholder for platform-specific delay mechanisms
        match std::env::consts::OS {
            "windows" => {
                // Windows: Could use Task Scheduler for delays
                // For now, we'll store the delay preference and handle it in the app
                Ok(())
            }
            "macos" => {
                // macOS: Could modify the plist with StartInterval
                // For now, we'll store the delay preference and handle it in the app
                Ok(())
            }
            "linux" => {
                // Linux: Could use systemd timer or modify desktop file
                // For now, we'll store the delay preference and handle it in the app
                Ok(())
            }
            _ => Err("Startup delay not supported on this platform".into()),
        }
    }

    pub fn validate_startup_entry(&self) -> Result<bool, Box<dyn std::error::Error>> {
        if !self.is_startup_enabled()? {
            return Ok(false);
        }

        let current_exe = env::current_exe()?;

        match std::env::consts::OS {
            "windows" => {
                // Check if registry entry points to current executable
                let output = Command::new("reg")
                    .args([
                        "query",
                        "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                        "/v",
                        "Pomodoro",
                    ])
                    .output()?;

                if output.status.success() {
                    let output_str = String::from_utf8_lossy(&output.stdout);
                    Ok(output_str.contains(&current_exe.to_string_lossy().as_ref()))
                } else {
                    Ok(false)
                }
            }
            "macos" => {
                // Check if plist file contains current executable path
                let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
                let plist_path = home_dir.join("Library/LaunchAgents/com.pomodoro.app.plist");

                if plist_path.exists() {
                    let content = fs::read_to_string(&plist_path)?;
                    Ok(content.contains(&current_exe.to_string_lossy().as_ref()))
                } else {
                    Ok(false)
                }
            }
            "linux" => {
                // Check if desktop file contains current executable path
                let home_dir = dirs::home_dir().ok_or("Could not find home directory")?;
                let desktop_file_path = home_dir.join(".config/autostart/pomodoro.desktop");

                if desktop_file_path.exists() {
                    let content = fs::read_to_string(&desktop_file_path)?;
                    Ok(content.contains(&current_exe.to_string_lossy().as_ref()))
                } else {
                    Ok(false)
                }
            }
            _ => Ok(false),
        }
    }

    pub fn fix_startup_entry(&self) -> Result<(), Box<dyn std::error::Error>> {
        // If startup is enabled but invalid, disable and re-enable to fix it
        if self.is_startup_enabled()? && !self.validate_startup_entry()? {
            self.disable_startup()?;
            self.enable_startup()?;
        }
        Ok(())
    }
}

#[derive(Debug, Clone)]
pub struct StartupInfo {
    pub enabled: bool,
    pub os: String,
    pub method: String,
    pub location: String,
}

impl StartupInfo {
    pub fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "enabled": self.enabled,
            "os": self.os,
            "method": self.method,
            "location": self.location
        })
    }
}