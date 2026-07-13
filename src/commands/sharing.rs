//! CLI commands for module sharing (upload/download).
//!
//! These commands provide non-interactive upload/download functionality
//! when a module name is specified directly.

use anyhow::{Context, Result};
use colored::*;
use std::io::{self, Write};
use std::process::{Command, Stdio};

use crate::config::{load_module, ConfigPaths};
use crate::module::ModuleManager;
use crate::sharing::git;

/// Upload a specific module by name to the community repository
pub fn upload(paths: &ConfigPaths, module_name: &str, json: bool) -> Result<()> {
    let module_manager = ModuleManager::new(paths.clone());

    // Resolve module path
    let resolved = module_manager
        .resolve_module_path(module_name)
        .context("Failed to resolve module path")?;

    let modules_dir = paths.modules_dir();

    // Determine actual module path (directory, Lua, or Nix file)
    let module_path = if modules_dir.join(&resolved).is_dir() {
        modules_dir.join(&resolved)
    } else if modules_dir.join(format!("{}.lua", &resolved)).exists() {
        modules_dir.join(format!("{}.lua", &resolved))
    } else if modules_dir.join(format!("{}.nix", &resolved)).exists() {
        modules_dir.join(format!("{}.nix", &resolved))
    } else if modules_dir.join(format!("{}.yaml", &resolved)).exists() {
        if json {
            println!(
                "{}",
                serde_json::json!({
                    "success": false,
                    "error": "Legacy YAML modules must be converted to directory format for upload"
                })
            );
        } else {
            eprintln!(
                "{} Legacy YAML modules must be converted to directory format for upload.",
                "Error:".red()
            );
            eprintln!("Convert by creating a directory with module.yaml inside.");
        }
        return Ok(());
    } else {
        anyhow::bail!("Module '{}' not found", module_name);
    };

    // Load and validate module
    let module = load_module(&module_path).context("Failed to load module")?;

    let metadata = match module.sharing_metadata() {
        Some(m) => m,
        None => {
            if json {
                println!(
                    "{}",
                    serde_json::json!({
                        "success": false,
                        "error": "Module missing required sharing metadata (author, version)"
                    })
                );
            } else {
                eprintln!(
                    "{} Module missing required sharing metadata.",
                    "Error:".red()
                );
                eprintln!("Add 'author' and 'version' fields to module.yaml or module.lua");
            }
            return Ok(());
        }
    };

    // Validate metadata
    if let Err(errors) = metadata.validate() {
        if json {
            println!(
                "{}",
                serde_json::json!({
                    "success": false,
                    "errors": errors
                })
            );
        } else {
            eprintln!("{} Module metadata validation failed:", "Error:".red());
            for err in errors {
                eprintln!("  - {}", err);
            }
        }
        return Ok(());
    }

    // Check git credentials (non-blocking; HTTPS can prompt on push)
    if !git::check_git_credentials()? && !json {
        eprintln!("{} Git credentials not configured.", "Warning:".yellow());
        eprintln!("  SSH: ssh-keygen -t ed25519 && ssh-add");
        eprintln!("  HTTPS: set a credential helper or use a PAT");
        eprintln!("  GitLab settings: https://gitlab.com/-/profile/keys");
        eprintln!("  Continuing; git may prompt for credentials.");
    }

    if !json {
        println!("{} Syncing repository...", "->".blue());
    }

    let use_ssh = git::has_ssh_key();
    let repo_dir = git::sync_repo(use_ssh).context("Failed to sync repository")?;

    if !json {
        println!("{} Staging module...", "->".blue());
    }

    let category = metadata.effective_category();
    git::stage_module_for_upload(&module_path, &resolved, category, &repo_dir)
        .context("Failed to stage module")?;

    if !json {
        println!("{} Pushing to remote...", "->".blue());
    }

    let message = format!(
        "Add {} by {} (v{})",
        resolved, metadata.author, metadata.version
    );
    git::commit_and_push(&repo_dir, &message, use_ssh).context("Failed to push to remote")?;

    if json {
        println!(
            "{}",
            serde_json::json!({
                "success": true,
                "module": resolved,
                "category": category,
                "version": metadata.version,
                "author": metadata.author
            })
        );
    } else {
        println!();
        println!(
            "{} Module '{}' uploaded successfully!",
            "OK".green(),
            resolved
        );
        println!("   Category: {}", category);
        println!("   Version:  {}", metadata.version);
        println!("   Author:   {}", metadata.author);
    }

    Ok(())
}

/// Interactive setup for Git credentials used by module uploads
pub fn setup_git(json: bool) -> Result<()> {
    if json {
        println!(
            "{}",
            serde_json::json!({
                "success": false,
                "error": "Interactive git setup is not available with --json"
            })
        );
        return Ok(());
    }

    println!("{}", "=== Module Upload Git Setup ===".blue().bold());
    println!();
    println!("Choose an authentication method:");
    println!("  1) SSH key");
    println!("  2) HTTPS (personal access token)");
    println!();

    let choice = loop {
        let input = prompt_line("Select 1 or 2")?;
        match input.as_str() {
            "1" => break 1,
            "2" => break 2,
            _ => println!("Please enter 1 or 2."),
        }
    };

    match choice {
        1 => setup_ssh()?,
        2 => setup_https()?,
        _ => unreachable!(),
    }

    println!();
    println!(
        "{}",
        "Setup complete. You can now run: dcli module upload".green()
    );
    Ok(())
}

fn setup_ssh() -> Result<()> {
    if git::has_ssh_key() {
        println!("{} SSH key detected.", "✓".green());
    } else {
        println!("{} No SSH key found.", "ℹ".blue());
        let generate = prompt_yes_no("Generate a new SSH key now?", true)?;
        if generate {
            let mut email = git_config_value("user.email")?;
            if email.is_empty() {
                email = prompt_line("Git email (used as key comment)")?;
            }
            println!("Launching ssh-keygen...");
            let status = Command::new("ssh-keygen")
                .args(["-t", "ed25519", "-C", &email])
                .status()
                .context("Failed to run ssh-keygen")?;
            if !status.success() {
                anyhow::bail!("ssh-keygen failed");
            }
        } else {
            println!("Skipping key generation.");
        }
    }

    if let Some(public_key) = read_public_key() {
        println!();
        println!("Public key (add to GitLab):");
        println!("{}", public_key);
    } else {
        println!("Could not locate SSH public key in ~/.ssh/");
    }

    println!("GitLab SSH keys: https://gitlab.com/-/profile/keys");
    Ok(())
}

fn setup_https() -> Result<()> {
    println!("GitLab PATs: https://gitlab.com/-/user_settings/personal_access_tokens");
    println!("Create a token with 'write_repository' scope.");
    println!();

    let username = prompt_line("GitLab username")?;
    let token = prompt_line("Personal access token (input will be visible)")?;

    if username.is_empty() || token.is_empty() {
        anyhow::bail!("Username and token are required");
    }

    Command::new("git")
        .args(["config", "--global", "credential.helper", "store"])
        .status()
        .context("Failed to configure git credential helper")?;

    let mut child = Command::new("git")
        .args(["credential", "approve"])
        .stdin(Stdio::piped())
        .spawn()
        .context("Failed to store git credentials")?;

    if let Some(stdin) = child.stdin.as_mut() {
        let payload = format!(
            "protocol=https\nhost=gitlab.com\nusername={}\npassword={}\n\n",
            username, token
        );
        stdin.write_all(payload.as_bytes())?;
    }

    let status = child.wait()?;
    if !status.success() {
        anyhow::bail!("Failed to store credentials via git credential");
    }

    println!("Credentials stored in ~/.git-credentials (git helper: store).");
    Ok(())
}

fn prompt_line(label: &str) -> Result<String> {
    print!("{}: ", label);
    io::stdout().flush()?;
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    Ok(input.trim().to_string())
}

fn prompt_yes_no(label: &str, default_yes: bool) -> Result<bool> {
    let suffix = if default_yes { "[Y/n]" } else { "[y/N]" };
    let input = prompt_line(&format!("{} {}", label, suffix))?;
    if input.is_empty() {
        return Ok(default_yes);
    }
    let first = input.chars().next().unwrap_or('n');
    Ok(matches!(first, 'y' | 'Y'))
}

fn git_config_value(key: &str) -> Result<String> {
    let output = Command::new("git")
        .args(["config", "--global", key])
        .output();

    Ok(output
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default()
        .trim()
        .to_string())
}

fn read_public_key() -> Option<String> {
    let home = dirs::home_dir()?;
    let ssh_dir = home.join(".ssh");
    let candidates = ["id_ed25519.pub", "id_rsa.pub", "id_ecdsa.pub"];
    for name in candidates {
        let path = ssh_dir.join(name);
        if path.exists() {
            if let Ok(content) = std::fs::read_to_string(path) {
                return Some(content.trim().to_string());
            }
        }
    }
    None
}

/// Download a specific module by name from the community repository
pub fn download(
    paths: &ConfigPaths,
    module_name: &str,
    category: Option<&str>,
    json: bool,
) -> Result<()> {
    if !json {
        println!("{} Syncing repository...", "->".blue());
    }

    let repo_dir = git::sync_repo(false).context("Failed to sync repository")?;

    let modules = git::list_remote_modules(&repo_dir).context("Failed to list remote modules")?;

    // Find the module
    let module = modules.iter().find(|m| {
        if let Some(cat) = category {
            m.category == cat && m.name == module_name
        } else {
            m.name == module_name
        }
    });

    let module = match module {
        Some(m) => m,
        None => {
            if json {
                println!(
                    "{}",
                    serde_json::json!({
                        "success": false,
                        "error": format!("Module '{}' not found in repository", module_name)
                    })
                );
            } else {
                eprintln!(
                    "{} Module '{}' not found in repository.",
                    "Error:".red(),
                    module_name
                );

                // Suggest similar modules
                let similar: Vec<_> = modules
                    .iter()
                    .filter(|m| m.name.contains(module_name) || module_name.contains(&m.name))
                    .take(3)
                    .collect();

                if !similar.is_empty() {
                    eprintln!();
                    eprintln!("Did you mean:");
                    for m in similar {
                        eprintln!("  - {}/{}", m.category, m.name);
                    }
                }
            }
            return Ok(());
        }
    };

    if !json {
        println!("{} Downloading '{}'...", "->".blue(), module.name);
    }

    // Download to local modules directory
    let target_path =
        git::download_module(module, &paths.modules_dir()).context("Failed to download module")?;

    if json {
        println!(
            "{}",
            serde_json::json!({
                "success": true,
                "module": module.name,
                "category": module.category,
                "path": target_path.display().to_string(),
                "author": module.author,
                "version": module.version
            })
        );
    } else {
        println!();
        println!(
            "{} Module '{}' downloaded successfully!",
            "OK".green(),
            module.name
        );
        println!("   Location: {}", target_path.display());
        if let Some(ref author) = module.author {
            println!("   Author:   {}", author);
        }
        if let Some(ref version) = module.version {
            println!("   Version:  {}", version);
        }
        println!();
        println!(
            "Enable with: {} module enable {}/{}",
            "dcli".cyan(),
            module.category,
            module.name
        );
    }

    Ok(())
}

/// List available modules in the community repository
#[allow(dead_code)]
pub fn list_remote(_paths: &ConfigPaths, category: Option<&str>, json: bool) -> Result<()> {
    let repo_dir = git::sync_repo(false).context("Failed to sync repository")?;

    let modules = git::list_remote_modules(&repo_dir).context("Failed to list remote modules")?;

    let filtered: Vec<_> = if let Some(cat) = category {
        modules.iter().filter(|m| m.category == cat).collect()
    } else {
        modules.iter().collect()
    };

    if json {
        let output: Vec<_> = filtered
            .iter()
            .map(|m| {
                serde_json::json!({
                    "name": m.name,
                    "category": m.category,
                    "description": m.description,
                    "author": m.author,
                    "version": m.version,
                    "tags": m.tags
                })
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&output)?);
    } else {
        if filtered.is_empty() {
            println!("No modules found.");
            return Ok(());
        }

        let mut current_category = "";
        for module in filtered {
            if module.category != current_category {
                if !current_category.is_empty() {
                    println!();
                }
                println!("{}", format!("[{}]", module.category).yellow().bold());
                current_category = &module.category;
            }

            let author = module
                .author
                .as_ref()
                .map(|a| format!(" by {}", a))
                .unwrap_or_default();
            let version = module
                .version
                .as_ref()
                .map(|v| format!(" v{}", v))
                .unwrap_or_default();

            println!(
                "  {} {}{}",
                module.name.cyan(),
                author.dimmed(),
                version.dimmed()
            );
            if !module.description.is_empty() {
                println!("    {}", module.description.dimmed());
            }
        }
    }

    Ok(())
}
