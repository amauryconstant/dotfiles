#!/usr/bin/env bash
#MISE description="Lint shell scripts"
#MISE quiet=true
# Silent on success; on failure shellcheck prints only warnings and errors.
set -euo pipefail
# xargs exits 123 if any shellcheck invocation fails.
find . \( -name "*.sh" -o -name "*.bash" \) -not -path './.git/*' -not -path './_ai/*' -print0 |
	xargs -0 -r shellcheck --severity=warning
