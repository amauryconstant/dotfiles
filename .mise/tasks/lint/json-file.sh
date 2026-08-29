#!/usr/bin/env bash
#MISE description="Validate a single JSON/JSONC file with jq empty"
set -euo pipefail

file="${1:?usage: mise run lint:json-file -- <file>}"
jq empty "$file"
