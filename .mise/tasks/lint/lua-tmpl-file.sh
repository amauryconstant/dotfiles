#!/usr/bin/env bash
#MISE description="Lint a single Lua template by rendering it, then stylua --check"
set -euo pipefail

# A *.lua.tmpl cannot be fed to stylua directly — Go template actions
# ({{ if ... }}) are not valid Lua. Render first, then check the result.
# Mirrors the documented shell pattern in .claude/rules/chezmoi-templates.md:
#   chezmoi execute-template < script.sh.tmpl | shellcheck -
#
# Two failure modes are caught: a Go-template error (execute-template exits
# non-zero) and badly formatted Lua inside the template (stylua --check).
#
# Limitation: only the branch that renders for THIS machine is checked. A
# {{ if ne .chassisType "laptop" }} block is invisible when run on the laptop.

file="${1:?usage: mise run lint:lua-tmpl-file -- <file.lua.tmpl>}"

# --stdin-filepath only names the input for diagnostics; strip .tmpl so stylua
# reports a .lua path and applies any .lua-scoped config.
# Assign first: under set -e a failed substitution here aborts, whereas inline
# it would silently render against the *global* chezmoi source dir.
worktree_root=$(git rev-parse --show-toplevel)
chezmoi execute-template --source "$worktree_root" <"$file" | stylua --check --stdin-filepath "${file%.tmpl}" -
