#!/usr/bin/env bash
set -euo pipefail

# Exclude _ai/ — vendored subtree updates stage deletions that are not
# chezmoi-managed targets; running `chezmoi destroy` on them is noise.
deleted_files=$(git diff --cached --name-status | awk '$1 == "D" {print $2}' | grep -v '^_ai/' || true)

if [ -n "$deleted_files" ]; then
	for file in $deleted_files; do
		echo "Running chezmoi destroy for deleted file: $file"
		chezmoi destroy "$file" || true # Don't block on chezmoi errors
	done
fi
