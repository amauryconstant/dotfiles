### BEGIN TWIGGIT WRAPPER
# Twiggit zsh wrapper - Generated on 2026-02-11 08:49:30
twiggit() {
    if [ "$1" = "cd" ]; then
        # Handle cd command with directory change
        target_dir=$(command twiggit "$@")
        if [ $? -eq 0 ] && [ -n "$target_dir" ]; then
            builtin cd "$target_dir"
        fi
    else
        # Pass through all other commands
        command twiggit "$@"
    fi
}
### END TWIGGIT WRAPPER
