use anyhow::{Context, Result};
use colored::*;
use std::collections::HashSet;
use std::io::{self, Write};
use std::path::Path;
use std::process::Command;

use crate::config::{Config, ConfigPaths, PackageManagerType, PackageType};

/// Check if nix is installed
pub fn is_nix_installed() -> bool {
    which::which("nix").is_ok() || nix_binary_path().is_some()
}

/// Check if home-manager is installed
pub fn is_home_manager_installed() -> bool {
    which::which("home-manager").is_ok() || home_manager_binary_path().is_some()
}

fn home_dir() -> Option<std::path::PathBuf> {
    std::env::var("HOME").ok().map(std::path::PathBuf::from)
}

/// Resolve the path to the nix binary, checking common installation paths
fn nix_binary_path() -> Option<std::path::PathBuf> {
    let home = home_dir()?;
    let candidates = [
        home.join(".nix-profile/bin/nix"),
        std::path::PathBuf::from("/nix/var/nix/profiles/default/bin/nix"),
    ];
    candidates.into_iter().find(|p| p.exists())
}

/// Resolve the path to the home-manager binary, checking common installation paths
fn home_manager_binary_path() -> Option<std::path::PathBuf> {
    let home = home_dir()?;
    let candidates = [
        home.join(".nix-profile/bin/home-manager"),
    ];
    candidates.into_iter().find(|p| p.exists())
}

/// Get the home-manager command (PATH or fallback path)
fn home_manager_command() -> String {
    which::which("home-manager")
        .ok()
        .map(|p| p.to_string_lossy().to_string())
        .or_else(|| home_manager_binary_path().map(|p| p.to_string_lossy().to_string()))
        .unwrap_or_else(|| "home-manager".to_string())
}

/// Get the nix command (PATH or fallback path)
pub fn nix_command() -> String {
    which::which("nix")
        .ok()
        .map(|p| p.to_string_lossy().to_string())
        .or_else(|| nix_binary_path().map(|p| p.to_string_lossy().to_string()))
        .unwrap_or_else(|| "nix".to_string())
}

/// Check if nix-daemon systemd service is active
pub fn is_nix_daemon_running() -> bool {
    Command::new("systemctl")
        .args(["is-active", "nix-daemon"])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

/// Start the nix-daemon via systemctl
pub fn start_nix_daemon() -> Result<()> {
    let status = Command::new("sudo")
        .args(["systemctl", "start", "nix-daemon"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to start nix-daemon")?;

    if !status.success() {
        anyhow::bail!("Failed to start nix-daemon");
    }

    Ok(())
}

/// Install nix based on the package manager type
pub fn install_nix(pm_type: &PackageManagerType) -> Result<()> {
    match pm_type {
        PackageManagerType::Dnf => install_nix_fedora(),
        PackageManagerType::Pacman => install_nix_arch(),
        PackageManagerType::Apt => install_nix_debian(),
    }
}

/// Detect system architecture for nix flake
pub fn detect_system_arch() -> String {
    let arch = Command::new("uname")
        .arg("-m")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "x86_64".to_string());

    match arch.as_str() {
        "x86_64" => "x86_64-linux",
        "aarch64" | "arm64" => "aarch64-linux",
        "i686" | "i386" => "i686-linux",
        other => other,
    }
    .to_string()
}

/// Detect the current hostname
#[allow(dead_code)]
pub fn detect_hostname() -> String {
    // Try dcli config hostname first, then system hostname
    if let Ok(h) = std::env::var("DCLI_HOST") {
        return h;
    }
    hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .unwrap_or_else(|| "localhost".to_string())
}

/// Get the per-host home-manager directory for a given hostname
pub fn home_manager_host_dir(paths: &ConfigPaths, hostname: &str) -> std::path::PathBuf {
    paths.home_manager_dir().join("hosts").join(hostname)
}

/// Check if the per-host structure is being used (hosts/ directory exists)
pub fn use_per_host_structure(paths: &ConfigPaths) -> bool {
    paths.home_manager_dir().join("hosts").exists()
}

/// Install nix on Fedora via dnf
fn install_nix_fedora() -> Result<()> {
    println!("  {} Installing nix via dnf...", "→".blue());

    // Check and install libgit2 if missing
    check_libgit2_fedora()?;

    let status = Command::new("sudo")
        .args(["dnf", "install", "-y", "nix", "nix-daemon"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to install nix packages")?;

    if !status.success() {
        anyhow::bail!("Failed to install nix via dnf");
    }

    println!("  {} Enabling nix-daemon...", "→".blue());

    let status = Command::new("sudo")
        .args(["systemctl", "enable", "--now", "nix-daemon"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to enable nix-daemon")?;

    if !status.success() {
        anyhow::bail!("Failed to enable nix-daemon");
    }

    Ok(())
}

/// Check if libgit2 is installed on Fedora, install if missing
fn check_libgit2_fedora() -> Result<()> {
    // Check if libgit2 is already available
    let has_libgit2 = Command::new("ldconfig")
        .arg("-p")
        .output()
        .map(|out| {
            String::from_utf8_lossy(&out.stdout).contains("libgit2.so")
        })
        .unwrap_or(false);

    if !has_libgit2 {
        println!("  {} Installing libgit2 dependency...", "→".blue());

        let status = Command::new("sudo")
            .args(["dnf", "install", "-y", "libgit2"])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to install libgit2")?;

        if !status.success() {
            anyhow::bail!("Failed to install libgit2");
        }
    }

    Ok(())
}

/// Install nix on Arch via pacman
fn install_nix_arch() -> Result<()> {
    println!("  {} Installing nix via pacman...", "→".blue());

    let status = Command::new("sudo")
        .args(["pacman", "-S", "--needed", "--noconfirm", "nix"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to install nix package")?;

    if !status.success() {
        anyhow::bail!("Failed to install nix via pacman");
    }

    println!("  {} Enabling nix-daemon...", "→".blue());

    let status = Command::new("sudo")
        .args(["systemctl", "enable", "--now", "nix-daemon"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to enable nix-daemon")?;

    if !status.success() {
        anyhow::bail!("Failed to enable nix-daemon");
    }

    Ok(())
}

/// Install nix on Debian/Ubuntu via official installer script
fn install_nix_debian() -> Result<()> {
    println!("  {} Installing nix via official installer...", "→".blue());

    let status = Command::new("sh")
        .args([
            "-c",
            "curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install | sh -s -- --daemon",
        ])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to run nix installer")?;

    if !status.success() {
        anyhow::bail!("Failed to install nix via official installer");
    }

    println!("  {} Nix installed. You may need to log out and log back in for PATH changes to take effect.", "→".blue());

    Ok(())
}

/// Setup nix channels (nixpkgs + home-manager)
pub fn setup_channels(nixpkgs_channel: &str, hm_channel: &str) -> Result<()> {
    println!("  {} Setting up nix channels...", "→".blue());

    // Add nixpkgs channel
    println!("  {} Adding nixpkgs channel ({})...", "→".blue(), nixpkgs_channel);
    let status = Command::new("nix-channel")
        .args([
            "--add",
            &format!("https://nixos.org/channels/{}", nixpkgs_channel),
            "nixpkgs",
        ])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to add nixpkgs channel")?;

    if !status.success() {
        anyhow::bail!("Failed to add nixpkgs channel");
    }

    // Add home-manager channel
    let hm_url = if hm_channel.starts_with("http") {
        hm_channel.to_string()
    } else {
        format!("https://github.com/nix-community/home-manager/archive/{}.tar.gz", hm_channel)
    };

    println!("  {} Adding home-manager channel ({})...", "→".blue(), hm_channel);
    let status = Command::new("nix-channel")
        .args(["--add", &hm_url, "home-manager"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to add home-manager channel")?;

    if !status.success() {
        anyhow::bail!("Failed to add home-manager channel");
    }

    // Update channels
    println!("  {} Updating channels...", "→".blue());
    let status = Command::new("nix-channel")
        .arg("--update")
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to update channels")?;

    if !status.success() {
        anyhow::bail!("Failed to update channels");
    }

    Ok(())
}

/// Install home-manager via nix-shell
pub fn install_home_manager() -> Result<()> {
    println!("  {} Installing home-manager...", "→".blue());

    let status = Command::new("nix-shell")
        .args(["<home-manager>", "-A", "install"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to install home-manager")?;

    if !status.success() {
        anyhow::bail!("Failed to install home-manager");
    }

    Ok(())
}

/// Collect all nix packages from all enabled modules and config sources
pub fn collect_nix_packages(config: &Config, paths: &ConfigPaths) -> Result<Vec<String>> {
    let mut packages = Vec::new();
    let mut seen = HashSet::new();

    // Get declared packages from all sources
    let pkg_manager = crate::package::PackageManager::new(paths.clone());
    let declared = pkg_manager.get_declared_packages(config)?;

    for pkg in declared {
        if matches!(pkg.package_type, PackageType::Nix) {
            if seen.insert(pkg.name.clone()) {
                packages.push(pkg.name);
            }
        }
    }

    Ok(packages)
}

/// Generate dcli-packages.nix file
pub fn generate_dcli_packages_nix(packages: &[String], output_path: &Path) -> Result<()> {
    let mut content = String::from("{ pkgs, ... }:\n{\n  home.packages = with pkgs; [\n");

    for pkg in packages {
        content.push_str(&format!("    {}\n", pkg));
    }

    content.push_str("  ];\n}\n");

    std::fs::write(output_path, &content)
        .with_context(|| format!("Failed to write {}", output_path.display()))?;

    Ok(())
}

/// Generate shared home.nix template with per-host support (for new per-host structure)
pub fn generate_shared_home_nix(output_path: &Path) -> Result<()> {
    if output_path.exists() {
        return Ok(());
    }

    let content = r#"{ config, pkgs, lib, hostname, ... }:
{
  imports =
    [ ./hosts/${hostname}/dcli-packages.nix ]
    ++ lib.optionals (builtins.pathExists ./hosts/${hostname}/packages.nix) [
      ./hosts/${hostname}/packages.nix
    ];

  programs.home-manager.enable = true;
  news.display = "silent";

  home.username = "changeme";
  home.homeDirectory = "/home/changeme";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  home.sessionVariables = {
    # EDITOR = "nvim";
  };
}
"#;

    std::fs::write(output_path, content)
        .with_context(|| format!("Failed to write {}", output_path.display()))?;

    Ok(())
}

/// Generate home.nix template (legacy flat structure)
pub fn generate_home_nix_template(username: &str, home_dir: &str, output_path: &Path) -> Result<()> {
    if output_path.exists() {
        return Ok(());
    }

    let content = format!(
        r#"{{ config, pkgs, ... }}:

{{
  home.username = "{}";
  home.homeDirectory = "{}";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;

  imports = [
    ./dcli-packages.nix
    # Add your own imports here:
    # ./packages.nix
    # ./dev.nix
  ];

  # Home Manager can also manage your environment variables
  home.sessionVariables = {{
    # EDITOR = "nvim";
  }};

  programs.home-manager.enable = true;

  # Suppress home-manager news
  news.display = "silent";
}}
"#,
        username, home_dir
    );

    std::fs::write(output_path, &content)
        .with_context(|| format!("Failed to write {}", output_path.display()))?;

    Ok(())
}

/// Generate per-host flake.nix that discovers hosts from subdirectories
pub fn generate_per_host_flake_nix(system_arch: &str, output_path: &Path) -> Result<()> {
    let content = format!(
        r#"{{ description = "Home Manager configuration managed by dcli"; inputs = {{
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
}}; outputs = {{ self, nixpkgs, home-manager, ... }}:
  let
    system = "{system_arch}";
    pkgs = import nixpkgs {{
      inherit system;
      config.allowUnfree = true;
    }};
    hosts = builtins.readDir ./hosts;
    mkHost = hostname: home-manager.lib.homeManagerConfiguration {{
      inherit pkgs;
      extraSpecialArgs = {{ inherit hostname; }};
      modules = [ ./home.nix ];
    }};
  in {{
    homeConfigurations = builtins.mapAttrs (name: _: mkHost name) hosts;
  }}; }}
"#,
        system_arch = system_arch,
    );

    std::fs::write(output_path, &content)
        .with_context(|| format!("Failed to write {}", output_path.display()))?;

    Ok(())
}

/// Generate flake.nix for single host (legacy flat structure)
#[allow(dead_code)]
pub fn generate_flake_nix(username: &str, system_arch: &str, output_path: &Path) -> Result<()> {
    let content = format!(
        r#"{{ description = "Home Manager configuration managed by dcli"; inputs = {{
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
}}; outputs = {{ self, nixpkgs, home-manager, ... }}:
  let
    system = "{system_arch}";
    pkgs = import nixpkgs {{
      inherit system;
      config.allowUnfree = true;
    }};
  in {{
    homeConfigurations."{username}" = home-manager.lib.homeManagerConfiguration {{
      inherit pkgs;
      modules = [ ./home.nix ];
    }};
  }}; }}
"#,
        system_arch = system_arch,
        username = username,
    );

    std::fs::write(output_path, &content)
        .with_context(|| format!("Failed to write {}", output_path.display()))?;

    Ok(())
}

/// Generate flake.lock by running nix flake lock
pub fn generate_flake_lock(paths: &ConfigPaths) -> Result<()> {
    let hm_dir = paths.home_manager_dir();
    let flake_nix = hm_dir.join("flake.nix");

    if !flake_nix.exists() {
        anyhow::bail!("flake.nix not found at {}", flake_nix.display());
    }

    println!("  {} Running nix flake lock...", "→".blue());

    let status = Command::new(nix_command())
        .args(["flake", "lock"])
        .current_dir(&hm_dir)
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to run nix flake lock")?;

    if !status.success() {
        anyhow::bail!("nix flake lock failed");
    }

    println!("  {} Generated flake.lock", "✓".green());

    Ok(())
}

/// Run home-manager switch
pub fn home_manager_switch(paths: &ConfigPaths, config: &Config) -> Result<()> {
    let hm_dir = paths.home_manager_dir();
    let home_nix = hm_dir.join("home.nix");

    if !home_nix.exists() {
        anyhow::bail!("home.nix not found at {}", home_nix.display());
    }

    println!();
    println!("{}", "=== Home Manager Switch ===".blue().bold());
    println!();

    let status = if config.nix.flake_enabled {
        let flake_nix = hm_dir.join("flake.nix");
        if !flake_nix.exists() {
            anyhow::bail!("flake.nix not found at {}. Run 'dcli init --nix-init' to set up flakes.", flake_nix.display());
        }

        // Use the hostname from dcli config for the flake target
        let flake_target = if use_per_host_structure(paths) {
            config.host.clone()
        } else {
            std::env::var("USER")
                .or_else(|_| std::env::var("LOGNAME"))
                .unwrap_or_else(|_| "user".to_string())
        };

        Command::new(home_manager_command())
            .args([
                "switch",
                "--flake",
                &format!("{}#{}", hm_dir.to_str().unwrap(), flake_target),
            ])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run home-manager switch")?
    } else {
        Command::new(home_manager_command())
            .args(["switch", "-f", home_nix.to_str().unwrap()])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run home-manager switch")?
    };

    if !status.success() {
        anyhow::bail!("home-manager switch failed");
    }

    println!();
    println!("{}", "✓ Home Manager switch complete!".green());

    Ok(())
}

/// Update nix channels/flake inputs and run home-manager switch
pub fn home_manager_update(paths: &ConfigPaths, config: &Config) -> Result<()> {
    if config.nix.flake_enabled {
        println!("{}", "=== Updating Flake Inputs ===".blue().bold());
        println!();

        let hm_dir = paths.home_manager_dir();
        let status = Command::new(nix_command())
            .args(["flake", "update"])
            .current_dir(&hm_dir)
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to run nix flake update")?;

        if !status.success() {
            anyhow::bail!("nix flake update failed");
        }
    } else {
        println!("{}", "=== Updating Nix Channels ===".blue().bold());
        println!();

        let status = Command::new("nix-channel")
            .arg("--update")
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context("Failed to update nix channels")?;

        if !status.success() {
            anyhow::bail!("Failed to update nix channels");
        }
    }

    println!();
    home_manager_switch(paths, config)
}

/// Search nixpkgs for a package
pub fn nix_search(query: &str) -> Result<()> {
    let status = Command::new(nix_command())
        .args(["search", "nixpkgs", query])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to run nix search")?;

    if !status.success() {
        anyhow::bail!("nix search failed");
    }

    Ok(())
}

/// Get the list of packages installed via nix profile
pub fn get_nix_profile_packages() -> Result<Vec<String>> {
    // Try JSON output first (nix 2.18+, format varies by version)
    let json_output = Command::new("nix")
        .args(["profile", "list", "--json"])
        .output();

    if let Ok(output) = json_output {
        if output.status.success() {
            let stdout = String::from_utf8_lossy(&output.stdout);

            // Try parsing as a map first (nix 2.24+): {"elements": {"pkgname": {...}}, "version": 3}
            if let Ok(map) = serde_json::from_str::<serde_json::Value>(&stdout) {
                if let Some(elements) = map.get("elements").and_then(|e| e.as_object()) {
                    // New format: elements object keys are the package names directly!
                    let packages: Vec<String> = elements.keys().cloned().collect();
                    return Ok(packages);
                }
            }

            // Fall back to old array format (nix 2.18 - 2.23): [...]
            if let Ok(entries) = serde_json::from_str::<Vec<serde_json::Value>>(&stdout) {
                let mut packages = Vec::new();
                for entry in entries {
                    let name = entry
                        // 1. Try "attrPath" first (e.g., "legacyPackages.x86_64-linux.fastfetch")
                        .get("attrPath").and_then(|a| a.as_str())
                            .and_then(|p| p.rsplit('.').next())
                            .map(|s| s.to_string())
                        // 2. Fall back to "url" (e.g., "flake:nixpkgs#fastfetch")
                        .or_else(|| entry.get("url").and_then(|u| u.as_str())
                            .and_then(|u| u.rsplit('#').next())
                            .map(|s| s.to_string()))
                        // 3. Fall back to "name" field, stripping any version suffix
                        //    (e.g., "fastfetch-2.2.0" -> "fastfetch")
                        .or_else(|| entry.get("name").and_then(|n| n.as_str())
                            .map(|n| strip_nix_package_version(n)))
                        // 4. Fall back to extracting store path basename
                        .or_else(|| entry.get("storePaths")
                            .and_then(|s| s.as_array())
                            .and_then(|arr| arr.first())
                            .and_then(|v| v.as_str())
                            .and_then(|p| p.rsplit('/').next())
                            .map(|s| s.to_string()));

                    if let Some(name) = name {
                        packages.push(name);
                    }
                }
                return Ok(packages);
            }
        }
    }

    // Fallback: parse non-JSON output from older nix versions
    let output = Command::new("nix")
        .args(["profile", "list"])
        .output()
        .context("Failed to run nix profile list")?;

    if !output.status.success() {
        return Ok(Vec::new()); // nix profile not initialized or no packages
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut packages = Vec::new();

    for line in stdout.lines() {
        // Text format: "Name:               package-name"
        // Note: nix only outputs ANSI codes on TTY; piped output has plain text
        if line.starts_with("Name:") {
            let name = line.split(':').nth(1).unwrap_or("").trim();
            let cleaned = strip_nix_package_version(name);
            if !cleaned.is_empty() {
                packages.push(cleaned);
            }
        }
    }

    Ok(packages)
}

/// Strip version suffix from a nix package name
/// e.g., "fastfetch-2.2.0" -> "fastfetch",  "hello-2.12.1" -> "hello"
fn strip_nix_package_version(name: &str) -> String {
    let name = name.trim();
    if let Some(hyphen_pos) = name.rfind('-') {
        let suffix = &name[hyphen_pos + 1..];
        if suffix.starts_with(|c: char| c.is_ascii_digit()) {
            return name[..hyphen_pos].to_string();
        }
    }
    name.to_string()
}

#[allow(dead_code)]
/// Check if a nix package (attr) is already installed via nix profile
pub fn is_nix_profile_package_installed(pkg_attr: &str) -> bool {
    match get_nix_profile_packages() {
        Ok(packages) => packages.iter().any(|p| p == pkg_attr),
        Err(_) => false,
    }
}

/// Install nix packages via nix profile (standalone, no home-manager)
pub fn nix_profile_install_packages(packages: &[&str], json: bool) -> Result<Vec<String>> {
    let mut installed = Vec::new();
    let mut failed = Vec::new();

    for pkg in packages {
        if !json {
            println!("  {} Installing nix package: {}", "→".blue(), pkg);
        }

        let status = Command::new("nix")
            .arg("profile")
            .arg("add")
            .arg(format!("nixpkgs#{}", pkg))
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to run nix profile add for {}", pkg))?;

        if status.success() {
            installed.push(pkg.to_string());
            if !json {
                println!("  {} Installed {}", "✓".green(), pkg);
            }
        } else {
            failed.push(pkg.to_string());
            if !json {
                println!("  {} Failed to install {}", "!".yellow(), pkg);
            }
        }
    }

    if !failed.is_empty() {
        eprintln!("⚠ Some nix packages failed to install: {}", failed.join(", "));
    }

    Ok(installed)
}

/// Remove nix packages from nix profile
pub fn nix_profile_remove_packages(packages: &[&str], json: bool) -> Result<()> {
    for pkg in packages {
        if !json {
            println!("  {} Removing nix package: {}", "→".blue(), pkg);
        }

        let status = Command::new("nix")
            .args(["profile", "remove", pkg])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .context(format!("Failed to run nix profile remove for {}", pkg))?;

        if status.success() {
            if !json {
                println!("  {} Removed {}", "✓".green(), pkg);
            }
        } else {
            if !json {
                println!("  {} Failed to remove {}", "!".yellow(), pkg);
            }
        }
    }

    Ok(())
}

/// Upgrade all nix profile packages
pub fn nix_profile_upgrade(json: bool) -> Result<bool> {
    if !json {
        println!("  {} Upgrading nix profile packages...", "→".blue());
    }

    // Use --all to upgrade all packages in the profile (not just the default set)
    let status = Command::new("nix")
        .args(["profile", "upgrade", "--all"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .status()
        .context("Failed to run nix profile upgrade")?;

    Ok(status.success())
}

/// Show nix/home-manager status
pub fn nix_status(paths: &ConfigPaths, config: &Config) -> Result<NixStatus> {
    let nix_installed = is_nix_installed();
    let nix_version = if nix_installed {
        Command::new(nix_command())
            .arg("--version")
            .output()
            .ok()
            .and_then(|out| String::from_utf8(out.stdout).ok())
            .map(|s| s.trim().to_string())
    } else {
        None
    };

    let daemon_running = is_nix_daemon_running();
    let hm_installed = is_home_manager_installed();
    let hm_version = if hm_installed {
        Command::new(home_manager_command())
            .arg("--version")
            .output()
            .ok()
            .and_then(|out| String::from_utf8(out.stdout).ok())
            .map(|s| s.trim().to_string())
    } else {
        None
    };

    let hm_dir = paths.home_manager_dir();
    let per_host = use_per_host_structure(paths);
    let home_nix_exists = hm_dir.join("home.nix").exists();
    let flake_nix_exists = hm_dir.join("flake.nix").exists();
    let file_exists = |p: std::path::PathBuf| p.exists();
    let current_dcli_exists = if per_host {
        file_exists(home_manager_host_dir(paths, &config.host).join("dcli-packages.nix"))
    } else {
        file_exists(hm_dir.join("dcli-packages.nix"))
    };

    Ok(NixStatus {
        nix_installed,
        nix_version,
        daemon_running,
        hm_installed,
        hm_version,
        home_nix_exists,
        dcli_packages_exists: current_dcli_exists,
        flake_enabled: config.nix.flake_enabled,
        flake_nix_exists,
        per_host_structure: per_host,
    })
}

#[derive(Debug)]
#[allow(dead_code)]
pub struct NixStatus {
    pub nix_installed: bool,
    pub nix_version: Option<String>,
    pub daemon_running: bool,
    pub hm_installed: bool,
    pub hm_version: Option<String>,
    pub home_nix_exists: bool,
    pub dcli_packages_exists: bool,
    pub flake_enabled: bool,
    pub flake_nix_exists: bool,
    pub per_host_structure: bool,
}

/// Migrate existing home-manager config to dcli management
pub fn migrate_existing_hm(paths: &ConfigPaths) -> Result<bool> {
    let old_hm_dir = dirs::home_dir()
        .map(|h| h.join(".config/home-manager"))
        .unwrap_or_default();
    let old_home_nix = old_hm_dir.join("home.nix");

    if !old_home_nix.exists() {
        return Ok(false);
    }

    println!();
    println!(
        "{} Existing home-manager config found at ~/.config/home-manager/home.nix",
        "→".blue()
    );
    print!("Migrate it to dcli management? [Y/n] ");
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    let choice = input.trim().to_lowercase();

    if choice == "n" {
        return Ok(false);
    }

    // Create dcli home-manager directory
    std::fs::create_dir_all(paths.home_manager_dir())
        .context("Failed to create home-manager directory")?;

    // Copy existing home.nix
    let new_home_nix = paths.home_manager_dir().join("home.nix");
    std::fs::copy(&old_home_nix, &new_home_nix)
        .context("Failed to copy home.nix")?;

    println!("  {} Copied home.nix to {}", "✓".green(), new_home_nix.display());

    // Create empty dcli-packages.nix
    let dcli_packages = paths.home_manager_dir().join("dcli-packages.nix");
    generate_dcli_packages_nix(&[], &dcli_packages)?;
    println!("  {} Created {}", "✓".green(), dcli_packages.display());

    // Add imports to migrated home.nix if not already present
    let content = std::fs::read_to_string(&new_home_nix)?;
    if !content.contains("dcli-packages.nix") {
        let updated = content.replacen(
            "{ config, pkgs, ... }:\n{",
            "{ config, pkgs, ... }:\n{\n  imports = [\n    ./dcli-packages.nix\n  ];\n",
            1,
        );
        std::fs::write(&new_home_nix, updated)?;
        println!("  {} Added dcli-packages.nix import to home.nix", "✓".green());
    }

    Ok(true)
}
