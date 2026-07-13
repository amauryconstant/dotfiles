use anyhow::{Context, Result};
use std::collections::HashMap;
use std::process::Command;

use super::PkgBackend;

/// DNF backend for Fedora/RHEL-based distros
pub struct DnfBackend;

impl DnfBackend {
    pub fn new() -> Self {
        Self
    }
}

impl PkgBackend for DnfBackend {
    fn install_packages_batch(&self, packages: &[&str]) -> Result<bool> {
        let status = Command::new("sudo")
            .arg("dnf")
            .arg("install")
            .arg("-y")
            .args(packages)
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to install packages")?;

        Ok(status.success())
    }

    fn install_interactive(&self, package: &str) -> Result<bool> {
        let status = Command::new("sudo")
            .args(["dnf", "install", package])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to install package: {}", package))?;

        Ok(status.success())
    }

    fn remove_packages_batch(&self, packages: &[&str]) -> Result<bool> {
        let status = Command::new("sudo")
            .arg("dnf")
            .arg("remove")
            .arg("-y")
            .args(packages)
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to remove packages")?;

        Ok(status.success())
    }

    fn remove_interactive(&self, package: &str) -> Result<bool> {
        let status = Command::new("sudo")
            .args(["dnf", "remove", package])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to remove package: {}", package))?;

        Ok(status.success())
    }

    fn refresh_db(&self) -> Result<()> {
        let status = Command::new("sudo")
            .args(["dnf", "makecache"])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to refresh package database")?;

        if !status.success() {
            anyhow::bail!("Package database refresh failed");
        }

        Ok(())
    }

    fn system_update(&self, _devel: bool) -> Result<bool> {
        let upgrade_status = Command::new("sudo")
            .args(["dnf", "upgrade", "-y"])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run dnf upgrade")?;

        Ok(upgrade_status.success())
    }

    fn get_installed_packages(&self) -> Result<HashMap<String, String>> {
        let output = Command::new("rpm")
            .args(["-qa", "--qf", "%{NAME} %{VERSION}\n"])
            .output()
            .context("Failed to run rpm -qa")?;

        if !output.status.success() {
            anyhow::bail!("rpm -qa failed");
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut packages = HashMap::new();

        for line in stdout.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() == 2 {
                packages.insert(parts[0].to_string(), parts[1].to_string());
            }
        }

        Ok(packages)
    }

    fn get_explicit_packages(&self) -> Result<Vec<String>> {
        let output = Command::new("dnf")
            .args(["repoquery", "--userinstalled", "--qf", "%{name}\n"])
            .output()
            .context("Failed to run dnf repoquery --userinstalled")?;

        if !output.status.success() {
            anyhow::bail!("dnf repoquery --userinstalled failed");
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        let packages = stdout
            .lines()
            .map(|line| line.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect();

        Ok(packages)
    }

    fn get_all_packages(&self) -> Result<Vec<String>> {
        let output = Command::new("rpm")
            .args(["-qa", "--qf", "%{NAME}\n"])
            .output()
            .context("Failed to run rpm -qa")?;

        if !output.status.success() {
            anyhow::bail!("rpm -qa failed");
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout.lines().map(|s| s.to_string()).collect())
    }

    fn is_installed(&self, package: &str) -> bool {
        Command::new("rpm")
            .args(["-q", package])
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    }

    fn get_package_version(&self, package: &str) -> Result<Option<String>> {
        let output = Command::new("rpm")
            .args(["-q", "--qf", "%{VERSION}", package])
            .output();

        match output {
            Ok(out) if out.status.success() => {
                let version = String::from_utf8_lossy(&out.stdout).trim().to_string();
                if version.is_empty() {
                    Ok(None)
                } else {
                    Ok(Some(version))
                }
            }
            _ => Ok(None),
        }
    }

    fn is_available(&self, package: &str) -> bool {
        Command::new("dnf")
            .args(["info", package])
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    }

    fn check_package_exists(&self, package: &str) -> bool {
        self.is_available(package)
    }

    fn list_available_packages(&self) -> Result<Vec<String>> {
        let output = Command::new("dnf")
            .args(["list", "available"])
            .output()
            .context("Failed to list available packages")?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut packages = Vec::new();

        for line in stdout.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with("Available Packages") {
                continue;
            }
            let parts: Vec<&str> = trimmed.split_whitespace().collect();
            if !parts.is_empty() {
                packages.push(parts[0].to_string());
            }
        }

        Ok(packages)
    }

    fn package_info_command(&self) -> &str {
        "dnf"
    }

    fn compare_versions(&self, v1: &str, v2: &str) -> i32 {
        if v1 == v2 {
            0
        } else if v1 < v2 {
            -1
        } else {
            1
        }
    }

    fn name(&self) -> &str {
        "dnf"
    }
}
