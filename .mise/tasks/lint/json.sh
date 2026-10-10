#!/usr/bin/env bash
#MISE description="Validate tracked JSON/JSONC files with jq empty"
#MISE quiet=true
set -euo pipefail
# modify_* are Go-template generators (jq chokes on {{ }}); same exclusion as
# json-staged.sh. xargs exits 123 if any jq invocation fails.
git ls-files -z -- '*.json' '*.jsonc' |
	grep -zv -e '/modify_' -e '^_ai/' |
	xargs -0 -r jq empty
