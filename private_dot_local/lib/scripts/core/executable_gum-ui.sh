#!/usr/bin/env bash

# Standardized Gum UI Library
# Purpose: Consistent, reusable UI functions for all shell scripts
# Requirements: gum (optional - provides fallbacks)
# Color scheme: Theme-aware (loaded from active theme)

# Load theme colors with fallback
if [ -f "$HOME/.config/themes/current/colors.sh" ]; then
    . "$HOME/.config/themes/current/colors.sh"
else
    # Fallback to Rose Pine Dawn defaults
    readonly BG_PRIMARY="#faf4ed"
    readonly FG_PRIMARY="#575279"
    readonly FG_SECONDARY="#797593"
    readonly FG_MUTED="#9893a5"
    readonly ACCENT_PRIMARY="#907aa9"
    readonly ACCENT_SUCCESS="#286983"
    readonly ACCENT_ERROR="#b4637a"
    readonly ACCENT_WARNING="#ea9d34"
    readonly ACCENT_URGENT_SECONDARY="#ea9d34"

    echo "⚠️  Warning: Theme colors not found, using fallback" >&2
fi

# Check gum availability and warn once if missing
_check_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        if [ -z "$GUM_WARNING_SHOWN" ]; then
            echo "⚠️  Warning: gum not found - UI functions will use basic fallbacks" >&2
            echo "   Install with: pacman -S gum" >&2
            export GUM_WARNING_SHOWN=1
        fi
        return 1
    fi
    return 0
}

# =============================================================================
# CORE RENDERING ENGINE
# =============================================================================

# Parse universal parameters - used by all UI functions
_parse_ui_params() {
    before=0
    after=0
    indent=0
    newline=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --newline|--nl) 
                newline=true
                shift 
                ;;
            --indent) 
                if [[ -n "$2" && "$2" != --* ]]; then
                    indent="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --before) 
                if [[ -n "$2" && "$2" != --* ]]; then
                    before="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --after) 
                if [[ -n "$2" && "$2" != --* ]]; then
                    after="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            *) 
                shift 
                ;;
        esac
    done
}

# Apply spacing based on parsed parameters
_apply_spacing() {
    local timing="$1" # "before" or "after"
    
    if [[ "$timing" == "before" ]]; then
        [ "$before" -gt 0 ] && printf '\n%.0s' $(seq 1 "$before")
    elif [[ "$timing" == "after" ]]; then
        [ "$newline" = true ] && echo
        [ "$after" -gt 0 ] && printf '\n%.0s' $(seq 1 "$after")
    fi
}

# Central rendering function with flexible parameter support
_ui_render() {
    local message="$1"
    local icon="$2"
    local color="$3"
    shift 3
    
    # Parse universal parameters
    _parse_ui_params "$@"
    
    # Apply before spacing
    _apply_spacing "before"
    
    # Build indented message
    local prefix=""
    [ "$indent" -gt 0 ] && printf -v prefix "%*s" "$indent" ""
    local full_message="${prefix}${icon}${message}"
    
    # Render with gum or fallback
    if _check_gum; then
        gum style --foreground "$color" "$full_message"
    else
        echo "$full_message"
    fi
    
    # Apply after spacing
    _apply_spacing "after"
}

# Helper function for subtitle rendering
_ui_render_subtitle() {
    local message="$1"
    if _check_gum; then
        gum style --foreground "$ACCENT_PRIMARY" --border rounded --padding "0 2" "$message"
    else
        echo
        echo "--- $message ---"
    fi
}

# Helper function for box rendering
_ui_render_box() {
    local content="$1"
    local border_color="$2"
    
    if _check_gum; then
        if [ -n "$border_color" ]; then
            gum style --border rounded --border-foreground "$border_color" --padding "1 2" --margin "1 0" "$content"
        else
            gum style --border rounded --padding "1 2" --margin "1 0" "$content"
        fi
    else
        echo
        echo "┌─────────────────────────────────────────────────────────────┐"
        echo "│ $content"
        echo "└─────────────────────────────────────────────────────────────┘"
        echo
    fi
}

# =============================================================================
# STATUS FUNCTIONS
# =============================================================================

# Display success message with green checkmark
ui_success() { _ui_render "$1" "✅ " "$ACCENT_SUCCESS" "${@:2}"; }

# Display error message with red X
ui_error() { _ui_render "$1" "❌ " "$ACCENT_ERROR" "${@:2}"; }

# Display warning message with yellow triangle
ui_warning() { _ui_render "$1" "⚠️  " "$ACCENT_WARNING" "${@:2}"; }

# Display info message with blue info icon
ui_info() { _ui_render "$1" "ℹ️  " "$ACCENT_PRIMARY" "${@:2}"; }

# Display step/process message with clipboard icon
ui_step() { _ui_render "$1" "📋 " "$ACCENT_PRIMARY" "${@:2}"; }

# Display status indicator with chart icon
ui_status() { _ui_render "$1" "📊 " "$ACCENT_PRIMARY" "${@:2}"; }

# Display action message with rocket icon
ui_action() { _ui_render "$1" "🚀 " "$ACCENT_PRIMARY" "${@:2}"; }

# Display completion message with party icon
ui_complete() { _ui_render "$1" "🎉 " "$ACCENT_SUCCESS" "${@:2}"; }

# Display plain text with secondary styling
ui_text() { _ui_render "$1" "" "$FG_SECONDARY" "${@:2}"; }

# =============================================================================
# HEADERS & LAYOUT FUNCTIONS  
# =============================================================================

# Display section title with double border
ui_title() {
    if _check_gum; then
        gum style --foreground "$ACCENT_PRIMARY" --bold --border double --padding "1 2" --margin "1 0" "$1"
    else
        echo
        echo "=== $1 ==="
        echo
    fi
}

# Display subtitle with single border
ui_subtitle() {
    local message="$1"
    shift
    
    # Parse universal parameters
    _parse_ui_params "$@"
    
    # Apply before spacing
    _apply_spacing "before"
    
    # Render subtitle
    _ui_render_subtitle "$message"
    
    # Apply after spacing
    _apply_spacing "after"
}

# Display content in a bordered box
ui_box() {
    local content="$1"
    shift
    local border_color="$FG_SECONDARY"
    
    # Parse border color parameter first
    if [[ $# -gt 0 && "$1" != --* ]]; then
        border_color="$1"
        shift
    fi
    
    # Parse universal parameters
    _parse_ui_params "$@"
    
    # Apply before spacing
    _apply_spacing "before"
    
    # Render box
    _ui_render_box "$content" "$border_color"
    
    # Apply after spacing
    _apply_spacing "after"
}

# Display visual separator
ui_separator() {
    if _check_gum; then
        gum style --foreground "$FG_MUTED" "────────────────────────────────────────────────────────"
    else
        echo "────────────────────────────────────────────────────────"
    fi
}

# Add consistent spacing with optional count
ui_spacer() {
    local count="${1:-1}"
    printf '\n%.0s' $(seq 1 "$count")
}

# Display raw data output with parameter support
ui_output() {
    local message="$1"
    shift
    
    # Parse universal parameters
    _parse_ui_params "$@"
    
    # Apply before spacing
    _apply_spacing "before"
    
    # Apply indentation and output message
    local prefix=""
    [ "$indent" -gt 0 ] && printf -v prefix "%*s" "$indent" ""
    echo "${prefix}${message}"
    
    # Apply after spacing
    _apply_spacing "after"
}

# =============================================================================
# INTERACTIVE FUNCTIONS
# =============================================================================

# Display confirmation prompt
ui_confirm() {
    local question="$1"
    local default="${2:-}"
    
    if _check_gum; then
        if [ -n "$default" ]; then
            gum confirm --default="$default" "$question"
        else
            gum confirm "$question"
        fi
    else
        printf "%s [y/N]: " "$question"
        read -r answer
        case "$answer" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Display selection menu
ui_choose() {
    local header="$1"
    shift
    
    if _check_gum; then
        if [ -n "$header" ]; then
            gum choose --header "$header" "$@"
        else
            gum choose "$@"
        fi
    else
        echo "$header"
        select choice in "$@"; do
            if [ -n "$choice" ]; then
                echo "$choice"
                break
            fi
        done
    fi
}

# Display multi-selection menu
ui_choose_multi() {
    local header="$1"
    local limit="${2:-0}"
    shift 2
    
    if _check_gum; then
        if [ "$limit" -gt 0 ]; then
            gum choose --header "$header" --limit "$limit" "$@"
        else
            gum choose --header "$header" --no-limit "$@"
        fi
    else
        echo "$header (enter numbers separated by spaces, e.g., '1 3 5'):"
        local i=1
        for option in "$@"; do
            echo "$i) $option"
            i=$((i + 1))
        done
        printf "Selection: "
        read -r selection
        # Simple fallback - would need more complex parsing for full functionality
        echo "$selection"
    fi
}

# Display text input prompt
ui_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    local default="${3:-}"
    
    if _check_gum; then
        local args=""
        [ -n "$placeholder" ] && args="$args --placeholder '$placeholder'"
        [ -n "$default" ] && args="$args --value '$default'"
        eval "gum input --prompt '$prompt: ' $args"
    else
        if [ -n "$default" ]; then
            printf "%s [%s]: " "$prompt" "$default"
        else
            printf "%s: " "$prompt"
        fi
        read -r input
        echo "${input:-$default}"
    fi
}

# Display password input prompt
ui_password() {
    local prompt="$1"
    
    if _check_gum; then
        gum input --password --prompt "$prompt: "
    else
        printf "%s: " "$prompt"
        stty -echo
        read -r password
        stty echo
        echo
        echo "$password"
    fi
}

# Display filter/search input
ui_filter() {
    local placeholder="${1:-Search...}"
    
    if _check_gum; then
        gum filter --placeholder "$placeholder"
    else
        echo "Filter functionality requires gum" >&2
        return 1
    fi
}

# =============================================================================
# PROGRESS & OPERATION FUNCTIONS
# =============================================================================

# Display spinner with command execution
ui_spin() {
    local title="$1"
    local command="$2"
    
    if _check_gum; then
        gum spin --spinner dot --title "$title" -- sh -c "$command"
    else
        echo "🔄 $title"
        eval "$command"
    fi
}

# Display operation start message
ui_progress_start() {
    local operation="$1"
    ui_action "Starting: $operation"
}

# Display operation completion message
ui_progress_complete() {
    local result="$1"
    ui_complete "$result"
}

# =============================================================================
# DATA DISPLAY FUNCTIONS
# =============================================================================

# Display formatted table
ui_table() {
    if _check_gum; then
        gum table
    else
        column -t -s $'\t'
    fi
}

# Display formatted list
ui_list() {
    local title="$1"
    shift
    
    if [ -n "$title" ]; then
        ui_subtitle "$title"
    fi
    
    for item in "$@"; do
        if _check_gum; then
            gum style --foreground "$FG_SECONDARY" "  • $item"
        else
            echo "  • $item"
        fi
    done
}

# Display key-value pairs
ui_key_value() {
    local key="$1"
    local value="$2"
    local separator="${3:-:}"
    
    if _check_gum; then
        local key_styled
        local value_styled
        key_styled=$(gum style --foreground "$ACCENT_PRIMARY" "$key$separator")
        value_styled=$(gum style --foreground "$FG_SECONDARY" "$value")
        echo "$key_styled $value_styled"
    else
        printf "%-20s %s %s\n" "$key$separator" "" "$value"
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Test all UI functions (for development/testing)
ui_test() {
    ui_title "Gum UI Library Test"
    
    ui_spacer
    ui_subtitle "Status Functions"
    ui_success "This is a success message"
    ui_error "This is an error message" 
    ui_warning "This is a warning message"
    ui_info "This is an info message"
    ui_step "This is a step message"
    ui_status "This is a status message"
    ui_action "This is an action message"
    ui_complete "This is a completion message"
    
    ui_spacer
    ui_subtitle "Layout Functions"
    ui_box "This content is in a bordered box"
    ui_separator
    
    ui_spacer
    ui_subtitle "Data Display"
    ui_list "Sample List" "First item" "Second item" "Third item"
    ui_key_value "Key" "Value"
    ui_key_value "Another Key" "Another Value" " =>"
    
    ui_spacer
    ui_complete "UI Library test completed!"
}

# Show library version and available functions
ui_help() {
    ui_title "Gum UI Library"
    ui_info "Standardized UI functions for consistent shell script formatting"
    ui_spacer
    
    ui_subtitle "Status Functions"
    ui_list "" \
        "ui_success 'message'" \
        "ui_error 'message'" \
        "ui_warning 'message'" \
        "ui_info 'message'" \
        "ui_step 'message'" \
        "ui_status 'message'" \
        "ui_action 'message'" \
        "ui_complete 'message'"
    
    ui_spacer
    ui_subtitle "Interactive Functions" 
    ui_list "" \
        "ui_confirm 'question' [default]" \
        "ui_choose 'header' opt1 opt2 opt3" \
        "ui_choose_multi 'header' [limit] opt1 opt2 opt3" \
        "ui_input 'prompt' [placeholder] [default]" \
        "ui_password 'prompt'" \
        "ui_filter [placeholder]"
    
    ui_spacer
    ui_subtitle "Progress Functions"
    ui_list "" \
        "ui_spin 'title' 'command'" \
        "ui_progress_start 'operation'" \
        "ui_progress_complete 'result'"
    
    ui_spacer
    ui_subtitle "Layout Functions"
    ui_list "" \
        "ui_title 'title'" \
        "ui_subtitle 'subtitle'" \
        "ui_box 'content' [border_color]" \
        "ui_separator" \
        "ui_spacer"
    
    ui_spacer
    ui_subtitle "Data Display Functions"
    ui_list "" \
        "ui_table < data.csv" \
        "ui_list 'title' item1 item2 item3" \
        "ui_key_value 'key' 'value' [separator]"
    
    ui_spacer
    ui_subtitle "Utility Functions"
    ui_list "" \
        "ui_test - Test all UI functions" \
        "ui_help - Show this help"
    
    ui_spacer
    ui_info "Colors are loaded from $SCRIPTS_DIR/core/colors.sh (oksolar theme)"
    ui_info "Gum is $(command -v gum >/dev/null 2>&1 && echo "available" || echo "not available - using fallbacks")"
}