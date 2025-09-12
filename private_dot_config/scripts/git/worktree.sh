#!/usr/bin/env bash
# shellcheck disable=SC2155
# Git Worktree Management - Unified Function
# Consolidates worktree-create, worktree-switch, worktree-status, worktree-cleanup
# Usage: worktree <subcommand> [global-options] [subcommand-args]
#
# This function uses bash for compatibility with readarray

# Source the gum UI library
if [[ -f "$HOME/.config/shell/gum-ui.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.config/shell/gum-ui.sh"
else
    echo "Error: gum-ui.sh library not found" >&2
    exit 1
fi

# Global variables with defaults
WORKTREE_VERSION="1.0.0"
WORKTREE_VERBOSE=${WORKTREE_VERBOSE:-false}
WORKTREE_QUIET=${WORKTREE_QUIET:-false}
WORKTREE_PROJECT_OVERRIDE=""
WORKTREE_WORKSPACE_OVERRIDE=""

# =============================================================================
# SHARED FUNCTIONS LIBRARY
# =============================================================================

# Repository Management
_worktree_check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        if [[ "$WORKTREE_QUIET" != "true" ]]; then
            ui_error "Error: Not in a git repository"
        fi
        exit 1
    fi
    exit 0
}

_worktree_get_project_name() {
    # Priority: explicit override → environment → git repo name
    if [[ -n "$WORKTREE_PROJECT_OVERRIDE" ]]; then
        echo "$WORKTREE_PROJECT_OVERRIDE"
        exit 0
    fi
    
    if [[ -n "$WORKTREE_PROJECT" ]]; then
        echo "$WORKTREE_PROJECT"
        exit 0
    fi
    
    if _worktree_check_git_repo 2>/dev/null; then
        basename "$(git rev-parse --show-toplevel)"
        exit 0
    fi
    
    ui_error "Cannot determine project name - not in git repo and no override provided"
    exit 1
}

_worktree_get_workspace_dir() {
    local project="$1"
    local base_workspace
    
    # Priority: explicit override → environment → default
    if [[ -n "$WORKTREE_WORKSPACE_OVERRIDE" ]]; then
        base_workspace="$WORKTREE_WORKSPACE_OVERRIDE"
    elif [[ -n "$WORKTREE_WORKSPACE" ]]; then
        base_workspace="$WORKTREE_WORKSPACE"
    else
        base_workspace="$HOME/Workspaces"
    fi
    
    if [[ -n "$project" ]]; then
        echo "$base_workspace/$project"
    else
        echo "$base_workspace"
    fi
}

# Worktree Discovery & Analysis
_worktree_find_all() {
    local workspace_dir="$1"
    local worktree_path
    
    if [[ ! -d "$workspace_dir" ]]; then
        exit 1
    fi
    
    # Find all .git files/directories and extract worktree paths
    find "$workspace_dir" -name ".git" \( -type f -o -type d \) 2>/dev/null | while IFS= read -r git_path; do
        worktree_path=${git_path%/.git}
        if [[ -d "$worktree_path" ]]; then
            echo "$worktree_path"
        fi
    done
}

_worktree_find_all_global() {
    local base_workspace="$HOME/Workspaces"
    
    if [[ ! -d "$base_workspace" ]]; then
        exit 1
    fi
    
    # Find all worktrees across all projects
    find "$base_workspace" -name ".git" \( -type f -o -type d \) 2>/dev/null | while IFS= read -r git_path; do
        local worktree_path=${git_path%/.git}
        if [[ -d "$worktree_path" ]]; then
            echo "$worktree_path"
        fi
    done
}

_worktree_get_all_projects() {
    local base_workspace="$HOME/Workspaces"
    
    if [[ ! -d "$base_workspace" ]]; then
        exit 1
    fi
    
    # Find all project directories (directories containing worktrees)
    find "$base_workspace" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while IFS= read -r project_dir; do
        # Check if this directory contains worktrees
        if find "$project_dir" -name ".git" \( -type f -o -type d \) 2>/dev/null | grep -q .; then
            basename "$project_dir"
        fi
    done | sort -u
}

_worktree_get_git_status() {
    local worktree_path="$1"
    local original_pwd="$PWD"
    
    if ! cd "$worktree_path" 2>/dev/null; then
        echo "error"
        exit 1
    fi
    
    local status="clean"
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        status="dirty"
    elif git status --porcelain 2>/dev/null | grep -q .; then
        status="untracked"
    fi
    
    cd "$original_pwd" || exit 1
    echo "$status"
}

_worktree_get_branch_info() {
    local worktree_path="$1"
    local original_pwd="$PWD"
    
    if ! cd "$worktree_path" 2>/dev/null; then
        echo "unknown"
        exit 1
    fi
    
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    cd "$original_pwd" || exit 1
    echo "$current_branch"
}

_worktree_get_last_activity() {
    local worktree_path="$1"
    local last_activity
    last_activity=$(stat -c %Y "$worktree_path" 2>/dev/null || echo "0")
    date -d "@$last_activity" "+%Y-%m-%d" 2>/dev/null || echo "unknown"
}

# Mise Integration
_worktree_setup_mise() {
    local main_repo_path="$1"
    local worktree_path="$2"
    
    # Local mise config files to copy
    local local_mise_config_files=(
        ".mise.local.toml"
        "mise.local.toml"
    )
    
    # Copy local mise config files that exist
    for config_file in "${local_mise_config_files[@]}"; do
        if [[ -f "$main_repo_path/$config_file" ]]; then
            local config_dir
            config_dir=$(dirname "$worktree_path/$config_file")
            mkdir -p "$config_dir" 2>/dev/null || true
            cp -f "$main_repo_path/$config_file" "$worktree_path/$config_file" 2>/dev/null || true
        fi
    done
    
    # Copy local mise directories
    local local_mise_dirs=(".mise" "mise")
    for mise_dir in "${local_mise_dirs[@]}"; do
        if [[ -f "$main_repo_path/$mise_dir/config.local.toml" ]]; then
            mkdir -p "$worktree_path/$mise_dir" 2>/dev/null || true
            cp -f "$main_repo_path/$mise_dir/config.local.toml" "$worktree_path/$mise_dir/" 2>/dev/null || true
        fi
    done
    
    # Trust the directory if mise is available
    if command -v mise >/dev/null 2>&1; then
        ui_spin "Trusting mise directory..." \
            "cd '$worktree_path' && mise trust 2>/dev/null || true"
    fi
    
    exit 0
}

_worktree_cleanup_mise() {
    local worktree_path="$1"
    
    if command -v mise >/dev/null 2>&1 && [[ -d "$worktree_path" ]]; then
        local branch_name=$(basename "$worktree_path")
        ui_spin "Cleaning up mise trust for '$branch_name'..." \
            "cd '$worktree_path' && mise trust --untrust 2>/dev/null || true"
    fi
}

# Path & Directory Management
_worktree_build_path() {
    local project="$1"
    local branch="$2"
    local workspace_dir=$(_worktree_get_workspace_dir "$project")
    echo "$workspace_dir/$branch"
}

_worktree_ensure_directories() {
    local path="$1"
    mkdir -p "$path" 2>/dev/null || {
        ui_error "Failed to create directory: $path"
        exit 1
    }
}

_worktree_cleanup_empty_dirs() {
    local workspace_dir="$1"
    
    # Remove empty project directory if it exists
    if [[ -d "$workspace_dir" ]] && [[ -z "$(ls -A "$workspace_dir" 2>/dev/null)" ]]; then
        rmdir "$workspace_dir" 2>/dev/null && {
            [[ "$WORKTREE_VERBOSE" == "true" ]] && ui_info "Removed empty workspace directory"
        }
    fi
    
    # Remove empty parent workspace if it exists
    local parent_workspace=$(dirname "$workspace_dir")
    if [[ "$parent_workspace" == "$HOME/Workspaces" ]] && [[ -d "$parent_workspace" ]] && [[ -z "$(ls -A "$parent_workspace" 2>/dev/null)" ]]; then
        rmdir "$parent_workspace" 2>/dev/null && {
            [[ "$WORKTREE_VERBOSE" == "true" ]] && ui_info "Removed empty parent workspace directory"
        }
    fi
}

# Validation & Safety
_worktree_validate_branch_name() {
    local branch="$1"
    
    if [[ -z "$branch" ]]; then
        ui_error "Branch name cannot be empty"
        exit 1
    fi
    
    if [[ "$branch" =~ [[:space:]] ]]; then
        ui_error "Branch name cannot contain spaces"
        exit 1
    fi
    
    if [[ ${#branch} -gt 100 ]]; then
        ui_error "Branch name too long (max 100 characters)"
        exit 1
    fi
    
    exit 0
}

_worktree_check_current_location() {
    local worktree_path="$1"
    local current_dir="$PWD"
    
    # Check if current directory is within the worktree to be removed
    if [[ "$current_dir" == "$worktree_path"* ]]; then
        ui_warning "You are currently in the worktree being removed"
        exit 0  # Return 0 to indicate we ARE in the target
    fi
    
    exit 1  # Not in target worktree
}

# UI Formatting & Selection
_worktree_format_for_selection() {
    local worktree_path="$1"
    local rel_path=${worktree_path#"$HOME/Workspaces/"}
    local current_branch=$(_worktree_get_branch_info "$worktree_path")
    local status_info=$(_worktree_get_git_status "$worktree_path")
    local last_activity=$(_worktree_get_last_activity "$worktree_path")
    
    echo "$rel_path → $current_branch ($status_info) [last: $last_activity]|$worktree_path"
}

_worktree_format_for_global_selection() {
    local worktree_path="$1"
    local rel_path=${worktree_path#"$HOME/Workspaces/"}
    local project_name=$(echo "$rel_path" | cut -d'/' -f1)
    local branch_name=$(echo "$rel_path" | cut -d'/' -f2-)
    local current_branch=$(_worktree_get_branch_info "$worktree_path")
    local status_info=$(_worktree_get_git_status "$worktree_path")
    local last_activity=$(_worktree_get_last_activity "$worktree_path")
    
    echo "[$project_name] $branch_name → $current_branch ($status_info) [last: $last_activity]|$worktree_path"
}

_worktree_parse_selection() {
    local selection_string="$1"
    echo "$selection_string" | cut -d'|' -f2
}

# Logging & Debug
_worktree_log() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "debug")
            [[ "$WORKTREE_VERBOSE" == "true" ]] && echo "[DEBUG] $message" >&2
            ;;
        "info")
            [[ "$WORKTREE_QUIET" != "true" ]] && ui_info "$message"
            ;;
        "warning")
            [[ "$WORKTREE_QUIET" != "true" ]] && ui_warning "$message"
            ;;
        "error")
            ui_error "$message"
            ;;
    esac
}

# =============================================================================
# COMPLETION HELPERS
# =============================================================================

_worktree_complete_branches() {
    if _worktree_check_git_repo 2>/dev/null; then
        {
            git branch --format='%(refname:short)' 2>/dev/null
            git branch -r --format='%(refname:short)' 2>/dev/null | sed 's/origin\///'
        } | sort -u | grep -v '^HEAD$'
    fi
}

_worktree_complete_worktrees() {
    local workspace_dir project
    
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name 2>/dev/null)
        workspace_dir=$(_worktree_get_workspace_dir "$project")
    else
        workspace_dir=$(_worktree_get_workspace_dir)
    fi
    
    if [[ -d "$workspace_dir" ]]; then
        local worktree_paths=()
        readarray -t worktree_paths < <(_worktree_find_all "$workspace_dir" 2>/dev/null)
        
        for worktree_path in "${worktree_paths[@]}"; do
            local rel_path=${worktree_path#"$HOME/Workspaces/"}
            echo "$rel_path"
        done
    fi
}

# =============================================================================
# MAIN OPTION PARSING
# =============================================================================

_worktree_parse_global_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                WORKTREE_PROJECT_OVERRIDE="$2"
                shift 2
                ;;
            --workspace)
                WORKTREE_WORKSPACE_OVERRIDE="$2"
                shift 2
                ;;
            --verbose|-v)
                WORKTREE_VERBOSE="true"
                shift
                ;;
            --quiet|-q)
                WORKTREE_QUIET="true"
                shift
                ;;
            --help|-h)
                _worktree_cmd_help
                exit 2
                ;;
            --version)
                echo "worktree version $WORKTREE_VERSION"
                exit 2
                ;;
            --complete-branches)
                _worktree_complete_branches
                exit 2
                ;;
            --complete-worktrees)
                _worktree_complete_worktrees
                exit 2
                ;;
            -*)
                ui_error "Unknown option: $1"
                exit 1
                ;;
            *)
                # Non-option argument, pass back to caller
                break
                ;;
        esac
    done
    
    # Return remaining arguments
    echo "$@"
}

# =============================================================================
# SUBCOMMAND IMPLEMENTATIONS
# =============================================================================

_worktree_cmd_create() {
    local branch="$1"
    local project worktree_path main_repo_path is_global=false
    
    # Determine context (project-specific vs global)
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name) || exit 1
        main_repo_path=$(git rev-parse --show-toplevel)
    else
        is_global=true
        
        # For global mode, prompt for project selection
        project=$(_worktree_prompt_project_selection)
        if [[ -z "$project" ]]; then
            ui_error "Project selection required for global worktree creation"
            exit 1
        fi
        
        # Find the main repository for this project
        local project_workspace_dir=$(_worktree_get_workspace_dir "$project")
        if [[ ! -d "$project_workspace_dir" ]]; then
            ui_error "Project workspace not found: $project_workspace_dir"
            ui_info "Tip: Navigate to a git repository and run 'worktree create' to initialize the project"
            exit 1
        fi
        
        # Find the main repository (usually the first directory, or look for one without a branch name)
        local potential_main_repos=()
        readarray -t potential_main_repos < <(_worktree_find_all "$project_workspace_dir")
        
        if [[ ${#potential_main_repos[@]} -eq 0 ]]; then
            ui_error "No repositories found for project: $project"
            exit 1
        fi
        
        # Use the first available repository as the source
        main_repo_path="${potential_main_repos[0]}"
        ui_info "Using source repository: $main_repo_path"
    fi
    
    # Interactive branch selection if not provided
    if [[ -z "$branch" ]]; then
        if [[ "$is_global" == "true" ]]; then
            branch=$(_worktree_prompt_branch_global "$project" "$main_repo_path")
        else
            branch=$(_worktree_prompt_branch "$project")
        fi
        [[ -z "$branch" ]] && { 
            ui_error "Branch name required"
            exit 1
        }
    fi
    
    # Validate branch name
    _worktree_validate_branch_name "$branch" || exit 1
    
    # Build paths
    worktree_path=$(_worktree_build_path "$project" "$branch")
    
    # Check for existing worktree
    if [[ -d "$worktree_path" ]]; then
        ui_warning "Worktree already exists: $worktree_path"
        if ui_confirm "Switch to existing worktree?"; then
            cd "$worktree_path" || exit 1
            ui_success "Switched to existing worktree"
            exit 0
        else
            exit 1
        fi
    fi
    
    # Create workspace directory
    _worktree_ensure_directories "$(dirname "$worktree_path")" || exit 1
    
    # For global mode, need to navigate to source repo to create worktree
    local original_pwd="$PWD"
    if [[ "$is_global" == "true" ]]; then
        cd "$main_repo_path" || {
            ui_error "Failed to navigate to source repository: $main_repo_path"
            exit 1
        }
    fi
    
    # Create the worktree
    _worktree_log "info" "Creating worktree '$branch' at $worktree_path"
    if ui_spin "Creating worktree '$branch'..." \
        git worktree add "$worktree_path" "$branch"; then
        
        # Setup mise integration
        _worktree_setup_mise "$main_repo_path" "$worktree_path"
        
        # Return to original directory if we changed it
        if [[ "$is_global" == "true" ]]; then
            cd "$original_pwd" || exit 1
        fi
        
        if [[ "$is_global" == "true" ]]; then
            ui_box "✅ Global worktree created successfully!

📁 Location: $worktree_path
🌿 Branch: $branch
🛠️  Project: $project
🔗 Source: $main_repo_path"
        else
            ui_box "✅ Worktree created successfully!

📁 Location: $worktree_path
🌿 Branch: $branch
🛠️  Project: $project"
        fi

        # Optional: Switch to new worktree
        if ui_confirm "Switch to new worktree now?"; then
            cd "$worktree_path" || exit 1
            ui_success "Switched to: $(pwd)"
        fi
    else
        # Return to original directory if we changed it
        if [[ "$is_global" == "true" ]]; then
            cd "$original_pwd" || exit 1
        fi
        ui_error "Failed to create worktree"
        exit 1
    fi
}

_worktree_prompt_project_selection() {
    ui_action "🌍 Global worktree creation - Select project:"
    ui_spacer
    
    # Get all available projects
    local projects=()
    readarray -t projects < <(_worktree_get_all_projects)
    
    if [[ ${#projects[@]} -eq 0 ]]; then
        ui_warning "No projects found in workspace"
        exit 1
    fi
    
    # Show project options
    local selected_project=$(printf '%s\n' "${projects[@]}" | \
        ui_choose "Select project for new worktree:")
    
    echo "$selected_project"
}

_worktree_prompt_branch() {
    local project="$1"
    
    ui_action "📋 Creating worktree for project: $project"
    ui_spacer
    
    # Show available remote branches for reference
    if git branch -r --format='%(refname:short)' 2>/dev/null | grep -q .; then
        ui_success "Available remote branches:"
        git branch -r --format='%(refname:short)' | \
            sed 's/origin\///' | head -10 | while read -r branch_name; do
            ui_text "$branch_name" --indent 2
        done
        ui_spacer
    fi
    
    # Interactive input
    local branch=$(ui_input "Branch" "Enter branch name (new or existing)")
    echo "$branch"
}

_worktree_prompt_branch_global() {
    local project="$1"
    local main_repo_path="$2"
    
    ui_action "🌍 Creating worktree for project: $project"
    ui_spacer
    
    # Navigate to the source repo to get branch information
    local original_pwd="$PWD"
    if cd "$main_repo_path" 2>/dev/null; then
        # Show available remote branches for reference
        if git branch -r --format='%(refname:short)' 2>/dev/null | grep -q .; then
            ui_success "Available remote branches:"
            git branch -r --format='%(refname:short)' | \
                sed 's/origin\///' | head -10 | while read -r branch_name; do
                ui_text "$branch_name" --indent 2
            done
            ui_spacer
        fi
        cd "$original_pwd" || exit 1
    fi
    
    # Interactive input
    local branch=$(ui_input "Branch" "Enter branch name (new or existing)")
    echo "$branch"
}

_worktree_cmd_switch() {
    local project workspace_dir formatted_worktrees selected
    
    # Determine context (project-specific vs global)
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name)
        workspace_dir=$(_worktree_get_workspace_dir "$project")
        ui_action "📋 Switching worktrees for project: $project"
    else
        workspace_dir=$(_worktree_get_workspace_dir)
        ui_action "📋 Switching between all worktrees"
    fi
    
    # Check workspace exists
    if [[ ! -d "$workspace_dir" ]]; then
        ui_warning "No worktrees found in: $workspace_dir"
        ui_info "Tip: Create a worktree with 'worktree create <branch-name>'"
        exit 1
    fi
    
    # Discover and format worktrees
    local worktree_paths=()
    readarray -t worktree_paths < <(_worktree_find_all "$workspace_dir")
    
    if [[ ${#worktree_paths[@]} -eq 0 ]]; then
        ui_warning "No worktrees found"
        ui_info "Tip: Create a worktree with 'worktree create <branch-name>'"
        exit 1
    fi
    
    # Format for selection
    formatted_worktrees=()
    for worktree_path in "${worktree_paths[@]}"; do
        if [[ -z "$project" ]]; then
            # Global mode - include project information
            formatted_worktrees+=("$(_worktree_format_for_global_selection "$worktree_path")")
        else
            # Project-specific mode
            formatted_worktrees+=("$(_worktree_format_for_selection "$worktree_path")")
        fi
    done
    
    # User selection
    selected=$(printf '%s\n' "${formatted_worktrees[@]}" | \
        ui_choose "Select worktree to switch to:")
    
    if [[ -n "$selected" ]]; then
        local target_path=$(_worktree_parse_selection "$selected")
        cd "$target_path" || exit 1
        
        # Show success with context
        local current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local project_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")
        ui_box "✅ Switched to worktree

📁 $(pwd)
🌿 Branch: $current_branch
🛠️  Project: $project_name"
    else
        ui_info "No worktree selected"
    fi
}

_worktree_cmd_status() {
    local project workspace_dir worktree_data is_global=false
    
    # Determine context (project-specific vs global)
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name) || exit 1
        workspace_dir=$(_worktree_get_workspace_dir "$project")
        
        # Header information
        ui_box "📊 Worktree Status for: $project

📁 Main repository: $(git rev-parse --show-toplevel)
🌿 Current branch: $(git branch --show-current)
🗂️  Workspace: $workspace_dir"

        ui_spacer
        
        # Show git worktree list if available
        if git worktree list 2>/dev/null | grep -q "worktree"; then
            ui_info "Git worktrees (official):"
            git worktree list
            ui_spacer
        fi
    else
        is_global=true
        workspace_dir="$HOME/Workspaces"
        
        # Global header information
        ui_box "🌍 Global Worktree Status

🗂️  Workspace: $workspace_dir
📋 Showing all projects"
        
        ui_spacer
    fi
    
    # Check workspace directory
    if [[ ! -d "$workspace_dir" ]]; then
        if [[ "$is_global" == "true" ]]; then
            ui_info "No global workspace directory found"
        else
            ui_info "No workspace directory found"
        fi
        ui_info "Tip: Create your first worktree with 'worktree create <branch-name>'"
        exit 0
    fi
    
    # Collect detailed worktree data
    local worktree_paths=()
    if [[ "$is_global" == "true" ]]; then
        readarray -t worktree_paths < <(_worktree_find_all_global)
    else
        readarray -t worktree_paths < <(_worktree_find_all "$workspace_dir")
    fi
    
    if [[ ${#worktree_paths[@]} -eq 0 ]]; then
        ui_info "No worktrees found"
        exit 0
    fi
    
    # Build detailed information
    worktree_data=()
    for worktree_path in "${worktree_paths[@]}"; do
        local rel_path=${worktree_path#"$HOME/Workspaces/"}
        local dir_name=$(basename "$worktree_path")
        local branch_info=$(_worktree_get_branch_info "$worktree_path")
        local status_info=$(_worktree_get_git_status "$worktree_path")
        local last_activity=$(_worktree_get_last_activity "$worktree_path")
        
        # Check remote tracking
        local remote_status="local-only"
        local original_pwd="$PWD"
        if cd "$worktree_path" 2>/dev/null; then
            local current_branch=$(git branch --show-current 2>/dev/null)
            if git show-ref --verify --quiet "refs/remotes/origin/$current_branch" 2>/dev/null; then
                remote_status="tracked"
            fi
            cd "$original_pwd" || exit 1
        fi
        
        if [[ "$is_global" == "true" ]]; then
            local project_name=$(echo "$rel_path" | cut -d'/' -f1)
            worktree_data+=("$project_name|$dir_name|$branch_info|$status_info|$remote_status|$last_activity|$worktree_path")
        else
            worktree_data+=("$dir_name|$branch_info|$status_info|$remote_status|$last_activity|$worktree_path")
        fi
    done
    
    # Display comprehensive table
    if [[ "$is_global" == "true" ]]; then
        _worktree_build_global_status_table worktree_data[@]
    else
        _worktree_build_status_table worktree_data[@]
    fi
    
    # Summary statistics
    local total_worktrees=${#worktree_data[@]}
    local clean_count=$(printf '%s\n' "${worktree_data[@]}" | grep -c "|clean|" || echo "0")
    local dirty_count=$(printf '%s\n' "${worktree_data[@]}" | grep -c "|dirty|" || echo "0")
    
    ui_spacer
    if [[ "$is_global" == "true" ]]; then
        local project_count=$(_worktree_get_all_projects | wc -l)
        ui_box "📊 Global Summary

Total projects: $project_count
Total worktrees: $total_worktrees
Clean: $clean_count
Dirty: $dirty_count

💡 Use 'worktree switch' to navigate between worktrees
💡 Use 'worktree cleanup' to clean up specific projects"
    else
        ui_box "📊 Summary

Total worktrees: $total_worktrees
Clean: $clean_count
Dirty: $dirty_count

💡 Use 'worktree switch' to navigate between worktrees
💡 Use 'worktree cleanup' to remove old worktrees"
    fi
}

_worktree_build_status_table() {
    local -n data_array=$1
    
    ui_subtitle "📋 Detailed worktree information:" --after 1
    
    # Table header
    printf "%-20s %-15s %-12s %-12s %-12s %s\n" \
        "DIRECTORY" "BRANCH" "STATUS" "REMOTE" "LAST_USED" "PATH"
    printf "%-20s %-15s %-12s %-12s %-12s %s\n" \
        "$(printf '%.0s─' {1..20})" \
        "$(printf '%.0s─' {1..15})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..30})"
    
    # Table data
    for entry in "${data_array[@]}"; do
        IFS='|' read -r dir_name branch_name status_info remote_status last_used path <<< "$entry"
        
        # Color coding for status
        case "$status_info" in
            "clean") status_display="● clean" ;;
            "dirty") status_display="● dirty" ;;
            "untracked") status_display="● untracked" ;;
            *) status_display="● $status_info" ;;
        esac
        
        # Color coding for remote status
        case "$remote_status" in
            "tracked") remote_display="tracked" ;;
            "local-only") remote_display="local-only" ;;
            *) remote_display="$remote_status" ;;
        esac
        
        printf "%-20s %-15s %-20s %-20s %-12s %s\n" \
            "$dir_name" "$branch_name" "$status_display" "$remote_display" "$last_used" "$path"
    done
}

_worktree_build_global_status_table() {
    local -n data_array=$1
    
    ui_subtitle "🌍 Global worktree information:" --after 1
    
    # Table header
    printf "%-15s %-20s %-15s %-12s %-12s %-12s %s\n" \
        "PROJECT" "DIRECTORY" "BRANCH" "STATUS" "REMOTE" "LAST_USED" "PATH"
    printf "%-15s %-20s %-15s %-12s %-12s %-12s %s\n" \
        "$(printf '%.0s─' {1..15})" \
        "$(printf '%.0s─' {1..20})" \
        "$(printf '%.0s─' {1..15})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..12})" \
        "$(printf '%.0s─' {1..30})"
    
    # Table data
    for entry in "${data_array[@]}"; do
        IFS='|' read -r project_name dir_name branch_name status_info remote_status last_used path <<< "$entry"
        
        # Color coding for status
        case "$status_info" in
            "clean") status_display="● clean" ;;
            "dirty") status_display="● dirty" ;;
            "untracked") status_display="● untracked" ;;
            *) status_display="● $status_info" ;;
        esac
        
        # Color coding for remote status
        case "$remote_status" in
            "tracked") remote_display="tracked" ;;
            "local-only") remote_display="local-only" ;;
            *) remote_display="$remote_status" ;;
        esac
        
        printf "%-15s %-20s %-15s %-20s %-20s %-12s %s\n" \
            "$project_name" "$dir_name" "$branch_name" "$status_display" "$remote_display" "$last_used" "$path"
    done
}

_worktree_cmd_cleanup() {
    local project workspace_dir worktree_info selected_items is_global=false
    
    # Determine context (project-specific vs global)
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name) || exit 1
        workspace_dir=$(_worktree_get_workspace_dir "$project")
        
        ui_action "🧹 Cleaning up worktrees for project: $project"
        
        # Prune stale references for current project
        ui_spin "Pruning stale worktree references..." \
            git worktree prune
    else
        is_global=true
        workspace_dir="$HOME/Workspaces"
        
        ui_action "🌍 Global worktree cleanup"
        ui_warning "⚠️  Operating on ALL projects in workspace"
    fi
    
    # Check workspace exists
    if [[ ! -d "$workspace_dir" ]]; then
        ui_success "No worktrees to clean up"
        exit 0
    fi
    
    # Discover worktrees with metadata
    local worktree_paths=()
    if [[ "$is_global" == "true" ]]; then
        readarray -t worktree_paths < <(_worktree_find_all_global)
    else
        readarray -t worktree_paths < <(_worktree_find_all "$workspace_dir")
    fi
    
    if [[ ${#worktree_paths[@]} -eq 0 ]]; then
        ui_success "No worktrees to clean up"
        exit 0
    fi
    
    # Build selection data with status information
    worktree_info=()
    for worktree_path in "${worktree_paths[@]}"; do
        local rel_path=${worktree_path#"$HOME/Workspaces/"}
        local branch_name=$(basename "$worktree_path")
        local last_activity=$(_worktree_get_last_activity "$worktree_path")
        
        # Check if branch still exists (need to cd to worktree for git commands)
        local branch_status="active"
        local original_pwd="$PWD"
        if cd "$worktree_path" 2>/dev/null; then
            local current_branch=$(git branch --show-current 2>/dev/null)
            if [[ -n "$current_branch" ]]; then
                if ! git show-ref --verify --quiet "refs/heads/$current_branch" && \
                   ! git show-ref --verify --quiet "refs/remotes/origin/$current_branch"; then
                    branch_status="stale"
                fi
            else
                branch_status="detached"
            fi
            cd "$original_pwd" || exit 1
        fi
        
        if [[ "$is_global" == "true" ]]; then
            local project_name=$(echo "$rel_path" | cut -d'/' -f1)
            worktree_info+=("[$project_name] $branch_name [$branch_status] (last: $last_activity)|$worktree_path")
        else
            worktree_info+=("$branch_name [$branch_status] (last: $last_activity)|$worktree_path")
        fi
    done
    
    # Show current state
    if [[ "$is_global" == "true" ]]; then
        ui_info "Global worktrees found:"
    else
        ui_info "Current worktrees:"
    fi
    printf '%s\n' "${worktree_info[@]}" | cut -d'|' -f1 | sed 's/^/  /'
    
    ui_warning "Select worktrees to remove (be careful!):"
    
    # Multi-selection for removal
    selected_items=$(printf '%s\n' "${worktree_info[@]}" | \
        ui_choose_multi "" 0 | cut -d'|' -f2)
    
    if [[ -z "$selected_items" ]]; then
        ui_info "No worktrees selected for removal"
        exit 0
    fi
    
    # Confirmation with details
    ui_warning "You are about to PERMANENTLY remove these worktrees:"
    while IFS= read -r line; do
        echo "  $line"
    done <<< "$selected_items"
    ui_spacer
    
    if ! ui_confirm "Are you sure you want to remove these worktrees?"; then
        ui_info "Operation cancelled"
        exit 0
    fi
    
    # Perform removal
    echo "$selected_items" | while IFS= read -r worktree_path; do
        if [[ -n "$worktree_path" ]]; then
            local rel_path=${worktree_path#"$HOME/Workspaces/"}
            local branch_name=$(basename "$worktree_path")
            
            # Safety check: not current directory
            if _worktree_check_current_location "$worktree_path"; then
                if [[ "$is_global" == "true" ]]; then
                    local project_name=$(echo "$rel_path" | cut -d'/' -f1)
                    ui_error "Cannot remove current worktree: [$project_name] $branch_name"
                else
                    ui_error "Cannot remove current worktree: $branch_name"
                fi
                continue
            fi
            
            # Clean up mise integration
            _worktree_cleanup_mise "$worktree_path"
            
            # For global cleanup, we need to navigate to the worktree to remove it
            local original_pwd="$PWD"
            if cd "$worktree_path" 2>/dev/null; then
                if [[ "$is_global" == "true" ]]; then
                    local project_name=$(echo "$rel_path" | cut -d'/' -f1)
                    if ui_spin "Removing worktree '[$project_name] $branch_name'..." \
                        git worktree remove "$worktree_path" --force; then
                        ui_success "Removed worktree: [$project_name] $branch_name"
                    else
                        ui_error "Failed to remove worktree: [$project_name] $branch_name"
                    fi
                else
                    if ui_spin "Removing worktree '$branch_name'..." \
                        git worktree remove "$worktree_path" --force; then
                        ui_success "Removed worktree: $branch_name"
                    else
                        ui_error "Failed to remove worktree: $branch_name"
                    fi
                fi
                cd "$original_pwd" || exit 1
            else
                # If we can't cd to the worktree, try direct removal
                if rm -rf "$worktree_path" 2>/dev/null; then
                    if [[ "$is_global" == "true" ]]; then
                        local project_name=$(echo "$rel_path" | cut -d'/' -f1)
                        ui_success "Force removed worktree directory: [$project_name] $branch_name"
                    else
                        ui_success "Force removed worktree directory: $branch_name"
                    fi
                else
                    if [[ "$is_global" == "true" ]]; then
                        local project_name=$(echo "$rel_path" | cut -d'/' -f1)
                        ui_error "Failed to remove worktree: [$project_name] $branch_name"
                    else
                        ui_error "Failed to remove worktree: $branch_name"
                    fi
                fi
            fi
        fi
    done
    
    # Cleanup empty directories
    if [[ "$is_global" == "true" ]]; then
        # For global cleanup, check each project directory
        local projects=()
        readarray -t projects < <(_worktree_get_all_projects 2>/dev/null)
        for project in "${projects[@]}"; do
            local project_workspace_dir=$(_worktree_get_workspace_dir "$project")
            _worktree_cleanup_empty_dirs "$project_workspace_dir"
        done
    else
        _worktree_cleanup_empty_dirs "$workspace_dir"
    fi
    
    ui_complete "Cleanup completed"
}

_worktree_cmd_list() {
    local project workspace_dir worktree_paths
    
    # Determine scope
    if _worktree_check_git_repo 2>/dev/null; then
        project=$(_worktree_get_project_name)
        workspace_dir=$(_worktree_get_workspace_dir "$project")
        echo "# Worktrees for project: $project"
    else
        workspace_dir=$(_worktree_get_workspace_dir)
        echo "# All worktrees"
    fi
    
    # Quick listing
    if [[ ! -d "$workspace_dir" ]]; then
        echo "No worktrees found"
        exit 0
    fi
    
    readarray -t worktree_paths < <(_worktree_find_all "$workspace_dir")
    
    if [[ ${#worktree_paths[@]} -eq 0 ]]; then
        echo "No worktrees found"
        exit 0
    fi
    
    # Simple format for scripting
    for worktree_path in "${worktree_paths[@]}"; do
        local rel_path=${worktree_path#"$HOME/Workspaces/"}
        local current_branch="unknown"
        local original_pwd="$PWD"
        
        if cd "$worktree_path" 2>/dev/null; then
            current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
            cd "$original_pwd" || exit 1 || exit 1
        fi
        
        echo "$rel_path → $current_branch"
    done
}

_worktree_cmd_help() {
    cat << 'EOF'
Git Worktree Management - Unified Interface

USAGE:
    worktree <subcommand> [global-options] [subcommand-args]

SUBCOMMANDS:
    create <branch>     Create new worktree with mise integration
    switch              Interactive worktree selection and switching  
    status              Comprehensive worktree status display
    cleanup             Interactive cleanup with safety checks
    list                Quick worktree listing (for scripts)
    help                Show this help information

OPERATION MODES:
    Project Mode:       When run inside a git repository, commands operate on that project
    Global Mode:        When run outside a git repository, commands operate on all projects

GLOBAL MODE FEATURES:
    • create:   Prompts for project selection, then creates worktree in chosen project
    • switch:   Shows all worktrees across all projects with project context
    • status:   Displays comprehensive status across all projects and worktrees
    • cleanup:  Allows cleanup of worktrees across multiple projects
    • list:     Lists all worktrees with project information

GLOBAL OPTIONS:
    --project <name>    Override automatic project detection
    --workspace <path>  Override default workspace directory ($HOME/Workspaces)
    --verbose, -v       Enable detailed operation logging
    --quiet, -q         Suppress non-essential output
    --help, -h          Show help information
    --version           Show version information

ENVIRONMENT VARIABLES:
    WORKTREE_WORKSPACE  Default workspace directory
    WORKTREE_PROJECT    Default project override

EXAMPLES:
    # Project-specific operations (inside git repo)
    worktree create feature-branch
    worktree status
    worktree cleanup
    
    # Global operations (outside git repo)
    worktree create              # Prompts for project selection
    worktree status             # Shows all projects and worktrees
    worktree switch             # Switch between worktrees across projects
    worktree cleanup            # Clean up worktrees from any project
    
    # Using overrides
    worktree --project myapp create hotfix
    worktree --workspace ~/Projects switch

For more information about a specific subcommand:
    worktree <subcommand> --help
EOF
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

# Parse global options first
remaining_args=$(_worktree_parse_global_options "$@")
exit_code=$?

if [[ $exit_code -eq 2 ]]; then
    # Special commands like --help, --version, completion handlers
    exit 0
elif [[ $exit_code -ne 0 ]]; then
    exit $exit_code
fi

# Parse remaining arguments into array
eval "set -- $remaining_args"

# Get subcommand
subcommand="$1"
if [[ $# -gt 0 ]]; then
    shift
fi

# Dispatch to subcommand handlers
case "$subcommand" in
    create)
        _worktree_cmd_create "$@"
        exit $?
        ;;
    switch)
        _worktree_cmd_switch "$@"
        exit $?
        ;;
    status)
        _worktree_cmd_status "$@"
        exit $?
        ;;
    cleanup)
        _worktree_cmd_cleanup "$@"
        exit $?
        ;;
    list)
        _worktree_cmd_list "$@"
        exit $?
        ;;
    help|"")
        _worktree_cmd_help
        exit 0
        ;;
    *)
        ui_error "Unknown subcommand: $subcommand"
        ui_info "Use 'worktree help' to see available commands"
        exit 1
        ;;
esac