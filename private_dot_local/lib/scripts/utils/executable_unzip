#!/usr/bin/env sh

# Script: unzip
# Purpose: Wrapper around unar to provide unzip-compatible interface
# Requirements: unar (installed via packages.yaml)

# Parse unzip arguments and translate to unar
QUIET=0
OUTPUT_DIR="."
OVERWRITE=""
ARCHIVE=""

while [ $# -gt 0 ]; do
    case "$1" in
        -q)
            QUIET=1
            shift
            ;;
        -d)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -o)
            OVERWRITE="-f"
            shift
            ;;
        -*)
            # Ignore other flags
            shift
            ;;
        *)
            # Archive file (last argument)
            ARCHIVE="$1"
            shift
            ;;
    esac
done

# Validate archive provided
if [ -z "$ARCHIVE" ]; then
    echo "Error: No archive specified" >&2
    exit 1
fi

# Run unar with translated arguments
if [ "$QUIET" -eq 1 ]; then
    unar -q -o "$OUTPUT_DIR" $OVERWRITE "$ARCHIVE" >/dev/null 2>&1
else
    unar -o "$OUTPUT_DIR" $OVERWRITE "$ARCHIVE"
fi
