#!/usr/bin/env bash

# Git Prune Branch - Safely remove branches with gone upstream
# Purpose: Interactive deletion of branches whose upstream has been deleted
# Requirements: git, gum

git-prune-branch() {
    # Note: Using standardized UI library which handles gum availability
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        ui_error "Not in a git repository"
        exit 1
    fi
    
    # Fetch remote updates with progress indication
    ui_spin "Fetching remote updates..." "git fetch -p"
    
    # Find branches with gone upstream
    local gone_branches=$(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}')
    
    if [[ -z "$gone_branches" ]]; then
        ui_success "No branches to prune - all local branches have valid upstreams"
        exit 0
    fi
    
    # Count branches to be deleted
    local branch_count=$(echo "$gone_branches" | wc -l)
    
    # Display branches that will be deleted
    ui_warning "Found $branch_count branch(es) with gone upstream:" --after 1
    echo "$gone_branches" | while read branch; do
        ui_error "  • $branch"
    done
    ui_spacer
    
    # Ask for confirmation
    if ui_confirm "Delete these branches?"; then
        echo "$gone_branches" | while read branch; do
            ui_action "Deleting branch: $branch" --before 1
            if git branch -D "$branch" 2>/dev/null; then
                ui_success "  Successfully deleted $branch"
            else
                ui_error "  Failed to delete $branch"
            fi
        done
        ui_complete "Branch pruning completed!" --before 1
    else
        ui_warning "Operation cancelled - no branches were deleted"
    fi
}
