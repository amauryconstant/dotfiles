#!/usr/bin/env bash
#MISE description="Lint a single YAML file with yamllint"
#MISE quiet=true
set -euo pipefail

file="${1:?usage: mise run lint:yaml-file -- <file>}"
yamllint -c .yamllint.yaml "$file"
