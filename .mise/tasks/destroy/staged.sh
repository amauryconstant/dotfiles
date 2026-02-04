#!/usr/bin/env bash
set -euo pipefail

deleted_files=$(git diff --cached --name-status | awk '$1 == "D" {print $2}')

if [ -n "$deleted_files" ]; then
  for file in $deleted_files; do
    echo "Running chezmoi destroy for deleted file: $file"
    chezmoi destroy "$file" || true  # Don't block on chezmoi errors
  done
fi
