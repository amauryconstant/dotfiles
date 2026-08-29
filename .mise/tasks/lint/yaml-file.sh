#!/usr/bin/env bash
#MISE description="Lint a single YAML file with yamllint"
set -euo pipefail

file="${1:?usage: mise run lint:yaml-file -- <file>}"
yamllint -c .yamllint.yaml "$file"
