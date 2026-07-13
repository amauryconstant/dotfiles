use anyhow::{Context, Result};
use std::collections::HashMap;
use std::process::Command;

use super::PkgBackend;

/// Apt backend for Debian/Ubuntu-based distros
pub struct AptBackend;

impl AptBackend {
    pub fn new() -> Self {
        Self
    }
}

impl PkgBackend for AptBackend {
    fn install_packages_batch(&self, packages: &[&str]) -> Result<bool> {
        let status = Command::new("sudo")
            .arg("apt")
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
            .args(["apt", "install", package])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to install package: {}", package))?;

        Ok(status.success())
    }

    fn remove_packages_batch(&self, packages: &[&str]) -> Result<bool> {
        let status = Command::new("sudo")
            .arg("apt")
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
            .args(["apt", "remove", package])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to remove package: {}", package))?;

        Ok(status.success())
    }

    fn refresh_db(&self) -> Result<()> {
        let status = Command::new("sudo")
            .args(["apt", "update"])
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
        // apt update && apt upgrade -y
        let update_status = Command::new("sudo")
            .args(["apt", "update"])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run apt update")?;

        if !update_status.success() {
            return Ok(false);
        }

        let upgrade_status = Command::new("sudo")
            .args(["apt", "upgrade", "-y"])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run apt upgrade")?;

        Ok(upgrade_status.success())
    }

    fn get_installed_packages(&self) -> Result<HashMap<String, String>> {
        let output = Command::new("dpkg-query")
            .args(["-W", "-f", "${Package} ${Version}\n"])
            .output()
            .context("Failed to run dpkg-query")?;

        if !output.status.success() {
            anyhow::bail!("dpkg-query failed");
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
        let output = Command::new("apt-mark")
            .args(["showmanual"])
            .output()
            .context("Failed to run apt-mark showmanual")?;

        if !output.status.success() {
            anyhow::bail!("apt-mark showmanual failed");
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout.lines().map(|s| s.to_string()).collect())
    }

    fn get_all_packages(&self) -> Result<Vec<String>> {
        let output = Command::new("dpkg-query")
            .args(["-W", "-f", "${Package}\n"])
            .output()
            .context("Failed to run dpkg-query")?;

        if !output.status.success() {
            anyhow::bail!("dpkg-query failed");
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout.lines().map(|s| s.to_string()).collect())
    }

    fn is_installed(&self, package: &str) -> bool {
        Command::new("dpkg-query")
            .args(["-W", "-f", "${Status}", package])
            .output()
            .map(|out| {
                out.status.success()
                    && String::from_utf8_lossy(&out.stdout).contains("install ok installed")
            })
            .unwrap_or(false)
    }

    fn get_package_version(&self, package: &str) -> Result<Option<String>> {
        let output = Command::new("dpkg-query")
            .args(["-W", "-f", "${Version}", package])
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
        Command::new("apt-cache")
            .args(["show", package])
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
        let output = Command::new("apt-cache")
            .args(["pkgnames"])
            .output()
            .context("Failed to list available packages")?;

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout.lines().map(|s| s.to_string()).collect())
    }

    fn package_info_command(&self) -> &str {
        "apt-cache"
    }

    fn compare_versions(&self, v1: &str, v2: &str) -> i32 {
        // dpkg --compare-versions v1 lt v2
        let lt_result = Command::new("dpkg")
            .args(["--compare-versions", v1, "lt", v2])
            .status();

        match lt_result {
            Ok(status) if status.success() => return -1, // v1 < v2
            _ => {}
        }

        let eq_result = Command::new("dpkg")
            .args(["--compare-versions", v1, "eq", v2])
            .status();

        match eq_result {
            Ok(status) if status.success() => 0, // v1 == v2
            _ => 1,                              // v1 > v2
        }
    }

    fn name(&self) -> &str {
        "apt"
    }

    fn install_deb_packages(&self, deb_paths: &[&str]) -> Result<bool> {
        // Use dpkg to install .deb files, then apt-get install -f to fix dependencies
        let status = Command::new("sudo")
            .arg("dpkg")
            .arg("-i")
            .args(deb_paths)
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to install .deb packages")?;

        if !status.success() {
            // Try to fix broken dependencies
            let fix_status = Command::new("sudo")
                .args(["apt-get", "install", "-f", "-y"])
                .stdin(std::process::Stdio::inherit())
                .stdout(std::process::Stdio::inherit())
                .stderr(std::process::Stdio::inherit())
                .status()
                .context("Failed to fix dependencies after .deb installation")?;

            return Ok(fix_status.success());
        }

        Ok(status.success())
    }
}
