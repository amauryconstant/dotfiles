#!/usr/bin/env bash
#MISE description="Lint a single Lua file with stylua --check"
set -euo pipefail

file="${1:?usage: mise run lint:lua-file -- <file>}"
stylua --check "$file"
