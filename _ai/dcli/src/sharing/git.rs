//! Git operations for module sharing repository.
//!
//! Handles cloning, pulling, staging, committing, and pushing modules
//! to the community modules repository.

use anyhow::{Context, Result};
use std::path::{Path, PathBuf};
use std::process::Command;
use walkdir::WalkDir;

use super::VALID_CATEGORIES;
use crate::config::load_module;

/// GitLab repository URL (HTTPS for cloning/pulling)
const MODULES_REPO_HTTPS: &str = "https://gitlab.com/theblackdon/dcli-modules.git";

/// GitLab repository URL (SSH for pushing)
const MODULES_REPO_SSH: &str = "git@gitlab.com:theblackdon/dcli-modules.git";

/// Information about a remote module in the repository
#[derive(Debug, Clone)]
pub struct RemoteModuleInfo {
    /// Module name (directory name)
    pub name: String,

    /// Category the module is in
    pub category: String,

    /// Module description
    pub description: String,

    /// Module author (if available)
    pub author: Option<String>,

    /// Module version (if available)
    pub version: Option<String>,

    /// Tags for searching
    pub tags: Vec<String>,

    /// Path to the module in the cached repository
    pub path: PathBuf,
}

/// Get the cache directory for the shared modules repository
pub fn get_cache_dir() -> Result<PathBuf> {
    let cache_dir = dirs::cache_dir()
        .context("Could not determine cache directory")?
        .join("dcli")
        .join("shared-modules");
    Ok(cache_dir)
}

/// Check if SSH keys exist for git operations.
pub fn has_ssh_key() -> bool {
    let home = dirs::home_dir();
    home.as_ref()
        .map(|h| {
            h.join(".ssh").join("id_rsa").exists()
                || h.join(".ssh").join("id_ed25519").exists()
                || h.join(".ssh").join("id_ecdsa").exists()
        })
        .unwrap_or(false)
}

/// Check if git credentials are configured for pushing
///
/// Checks for:
/// - SSH keys (id_rsa, id_ed25519)
/// - Git credential helper configuration (HTTPS)
pub fn check_git_credentials() -> Result<bool> {
    if has_ssh_key() {
        return Ok(true);
    }

    // Check for credential helper
    let output = Command::new("git")
        .args(["config", "--global", "credential.helper"])
        .output();

    let has_cred_helper = output
        .map(|o| o.status.success() && !o.stdout.is_empty())
        .unwrap_or(false);

    Ok(has_cred_helper)
}

/// Clone or update the shared modules repository
///
/// - If the repository doesn't exist, clones it
/// - If it exists, pulls the latest changes
///
/// `use_ssh`: Use SSH URL (required for pushing), otherwise HTTPS
pub fn sync_repo(use_ssh: bool) -> Result<PathBuf> {
    let cache_dir = get_cache_dir()?;
    let repo_dir = cache_dir.join("dcli-modules");

    std::fs::create_dir_all(&cache_dir).context("Failed to create cache directory")?;

    if repo_dir.exists() {
        // Pull latest changes
        let output = Command::new("git")
            .args(["pull", "--ff-only"])
            .current_dir(&repo_dir)
            .output()
            .context("Failed to run git pull")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            // Try to recover if local branch tracks a missing ref (e.g., main/master mismatch)
            let _ = Command::new("git")
                .args(["fetch", "origin", "--prune"])
                .current_dir(&repo_dir)
                .output();
            let _ = Command::new("git")
                .args(["remote", "set-head", "origin", "-a"])
                .current_dir(&repo_dir)
                .output();

            if let Ok(head_output) = Command::new("git")
                .args(["symbolic-ref", "refs/remotes/origin/HEAD"])
                .current_dir(&repo_dir)
                .output()
            {
                if head_output.status.success() {
                    if let Ok(head_ref) = String::from_utf8(head_output.stdout) {
                        if let Some(branch) = head_ref.trim().rsplit('/').next() {
                            let _ = Command::new("git")
                                .args(["checkout", "-B", branch, &format!("origin/{}", branch)])
                                .current_dir(&repo_dir)
                                .output();
                            let _ = Command::new("git")
                                .args([
                                    "branch",
                                    "--set-upstream-to",
                                    &format!("origin/{}", branch),
                                ])
                                .current_dir(&repo_dir)
                                .output();
                            let retry = Command::new("git")
                                .args(["pull", "--ff-only"])
                                .current_dir(&repo_dir)
                                .output();
                            if let Ok(retry_output) = retry {
                                if retry_output.status.success() {
                                    return Ok(repo_dir);
                                }
                            }
                        }
                    }
                }
            }

            // Don't fail on pull errors, might be offline
            eprintln!("Warning: Failed to update repository: {}", stderr.trim());
        }
    } else {
        // Clone repository
        let url = if use_ssh {
            MODULES_REPO_SSH
        } else {
            MODULES_REPO_HTTPS
        };

        let output = Command::new("git")
            .args(["clone", url, repo_dir.to_str().unwrap()])
            .output()
            .context("Failed to run git clone")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to clone repository: {}", stderr.trim());
        }
    }

    Ok(repo_dir)
}

/// Stage a module for upload by copying it to the repository
///
/// Returns the path where the module was staged
pub fn stage_module_for_upload(
    local_module_path: &Path,
    module_name: &str,
    category: &str,
    repo_dir: &Path,
) -> Result<PathBuf> {
    let repo_module_name = if local_module_path.is_dir() {
        local_module_path
            .file_name()
            .and_then(|s| s.to_str())
            .unwrap_or(module_name)
    } else {
        local_module_path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or(module_name)
    };
    let target_dir = repo_dir.join(category).join(repo_module_name);
    let legacy_target_dir = repo_dir.join(category).join(module_name);

    // Remove existing if present (for updates)
    if target_dir.exists() {
        std::fs::remove_dir_all(&target_dir).context("Failed to remove existing module")?;
    }
    if legacy_target_dir != target_dir && legacy_target_dir.exists() {
        std::fs::remove_dir_all(&legacy_target_dir)
            .context("Failed to remove existing module at legacy path")?;
    }

    // Create category directory if needed
    if let Some(parent) = target_dir.parent() {
        std::fs::create_dir_all(parent).context("Failed to create category directory")?;
    }

    // Copy module
    if local_module_path.is_dir() {
        copy_dir_recursive(local_module_path, &target_dir)?;
    } else {
        // Single file module (Lua) - create directory and copy
        std::fs::create_dir_all(&target_dir)?;
        let filename = local_module_path
            .file_name()
            .context("Invalid module path")?;
        std::fs::copy(local_module_path, target_dir.join(filename))
            .context("Failed to copy module file")?;
    }

    Ok(target_dir)
}

/// Commit and push changes to the remote repository
pub fn commit_and_push(repo_dir: &Path, message: &str, use_ssh: bool) -> Result<()> {
    let remote_url = if use_ssh {
        MODULES_REPO_SSH
    } else {
        MODULES_REPO_HTTPS
    };

    let _ = Command::new("git")
        .args(["remote", "set-url", "origin", remote_url])
        .current_dir(repo_dir)
        .output();

    // Git add
    let add_output = Command::new("git")
        .args(["add", "."])
        .current_dir(repo_dir)
        .output()
        .context("Failed to run git add")?;

    if !add_output.status.success() {
        let stderr = String::from_utf8_lossy(&add_output.stderr);
        anyhow::bail!("Failed to stage changes: {}", stderr.trim());
    }

    // Git commit
    let commit_output = Command::new("git")
        .args(["commit", "-m", message])
        .current_dir(repo_dir)
        .output()
        .context("Failed to run git commit")?;

    if !commit_output.status.success() {
        let stderr = String::from_utf8_lossy(&commit_output.stderr);
        let stdout = String::from_utf8_lossy(&commit_output.stdout);

        // Check if nothing to commit
        if stderr.contains("nothing to commit") || stdout.contains("nothing to commit") {
            anyhow::bail!("No changes to commit (module may already be up to date)");
        }
        anyhow::bail!("Failed to commit: {}", stderr.trim());
    }

    // Git push
    let push_output = Command::new("git")
        .args(["push"])
        .current_dir(repo_dir)
        .output()
        .context("Failed to run git push")?;

    if !push_output.status.success() {
        let stderr = String::from_utf8_lossy(&push_output.stderr);
        anyhow::bail!(
            "Failed to push to remote: {}\n\n\
             Make sure you have:\n\
             1. Write access to the repository\n\
             2. Git credentials configured\n\
             3. SSH: ssh-keygen -t ed25519 && ssh-add\n\
             4. HTTPS: configure a credential helper or use a PAT\n\
             5. Add your key or token in GitLab settings",
            stderr.trim()
        );
    }

    Ok(())
}

/// List all modules in the remote repository
pub fn list_remote_modules(repo_dir: &Path) -> Result<Vec<RemoteModuleInfo>> {
    let mut modules = Vec::new();

    for category in VALID_CATEGORIES {
        let category_dir = repo_dir.join(category);
        if !category_dir.exists() {
            continue;
        }

        for entry in WalkDir::new(&category_dir)
            .min_depth(1)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            if !entry.file_type().is_dir() {
                continue;
            }

            let path = entry.path();
            let name = entry.file_name().to_string_lossy();
            if name.starts_with('.') {
                continue;
            }

            // Only consider directories that define a module
            if !path.join("module.yaml").exists()
                && !path.join("module.lua").exists()
                && !path.join("module.nix").exists()
            {
                continue;
            }

            // Compute module name relative to category (supports nested modules)
            let rel_path = match path.strip_prefix(&category_dir) {
                Ok(p) => p.to_string_lossy().to_string(),
                Err(_) => continue,
            };

            // Try to load module metadata
            if let Ok(module) = load_module(path) {
                let metadata = module.sharing_metadata();
                let author = metadata.as_ref().and_then(|m| {
                    let trimmed = m.author.trim();
                    if trimmed.is_empty() {
                        None
                    } else {
                        Some(trimmed.to_string())
                    }
                });

                modules.push(RemoteModuleInfo {
                    name: rel_path,
                    category: category.to_string(),
                    description: module.description().to_string(),
                    author,
                    version: metadata.as_ref().map(|m| m.version.clone()),
                    tags: metadata
                        .as_ref()
                        .map(|m| m.tags.clone())
                        .unwrap_or_default(),
                    path: path.to_path_buf(),
                });
            }
        }
    }

    // Sort by category then name
    modules.sort_by(|a, b| {
        a.category
            .cmp(&b.category)
            .then_with(|| a.name.cmp(&b.name))
    });

    Ok(modules)
}

/// Recursively copy a directory
pub fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<()> {
    std::fs::create_dir_all(dst)?;

    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());

        // Skip .git directories and other hidden files
        if entry
            .file_name()
            .to_str()
            .map(|n| n.starts_with('.'))
            .unwrap_or(false)
        {
            continue;
        }

        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }

    Ok(())
}

/// Download a specific module from the repository to a local path
pub fn download_module(remote_module: &RemoteModuleInfo, target_dir: &Path) -> Result<PathBuf> {
    let dest = target_dir
        .join(&remote_module.category)
        .join(&remote_module.name);

    // Create parent directories
    if let Some(parent) = dest.parent() {
        std::fs::create_dir_all(parent)?;
    }

    // Remove existing if present
    if dest.exists() {
        std::fs::remove_dir_all(&dest)?;
    }

    // Copy module
    copy_dir_recursive(&remote_module.path, &dest)?;

    Ok(dest)
}
