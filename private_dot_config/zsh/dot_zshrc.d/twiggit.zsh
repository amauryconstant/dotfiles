### BEGIN TWIGGIT WRAPPER
# Twiggit zsh wrapper - Generated on 2026-02-23 08:49:16
twiggit() {
case "$1" in
    cd)
        # Handle cd command with directory change
        target_dir=$(command twiggit "$@")
        if [ $? -eq 0 ] && [ -n "$target_dir" ]; then
            builtin cd "$target_dir"
        fi
        ;;
    create)
        # Handle create command with -C flag
	if [[ " "$@" " == *" -C "* ]] || [[ " "$@" " == *" --cd "* ]]; then
			target_dir=$(command twiggit "$@")
			if [ $? -eq 0 ] && [ -n "$target_dir" ]; then
				builtin cd "$target_dir"
			fi
		else
			command twiggit "$@"
		fi
		;;
	delete)
		# Handle delete command with -C flag
		if [[ " "$@" " == *" -C "* ]] || [[ " "$@" " == *" --cd "* ]]; then
            target_dir=$(command twiggit "$@")
            if [ $? -eq 0 ] && [ -n "$target_dir" ]; then
                builtin cd "$target_dir"
            fi
        else
            command twiggit "$@"
        fi
        ;;
    *)
        # Pass through all other commands
        command twiggit "$@"
        ;;
esac
}
### END TWIGGIT WRAPPER
