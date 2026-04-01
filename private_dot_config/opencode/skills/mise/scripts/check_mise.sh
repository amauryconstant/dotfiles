#!/usr/bin/env sh

# Script: check_mise.sh

# Purpose: Verify mise installation and shell integration setup

# Usage: ./check_mise.sh

set -u

# Color codes for output (safe to use in most shells)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Checking mise installation..."
echo ""

# Check if mise is installed

if ! command -v mise >/dev/null 2>&1; then
    printf "${RED}✗ mise not found in PATH${NC}\n"
    echo ""
    echo "Installation options:"
    echo ""
    echo "1. Homebrew (macOS/Linux):"
    echo "   brew install mise"
    echo ""
    echo "2. Apt (Debian/Ubuntu):"
    echo "   curl <https://mise.jdx.dev/install.sh> | sh"
    echo ""
    echo "3. Pacman (Arch Linux):"
    echo "   pacman -S mise"
    echo ""
    echo "4. Cargo (Rust):"
    echo "   cargo install mise"
    echo ""
    echo "5. Official installer:"
    echo "   curl <https://mise.jdx.dev/install.sh> | sh"
    echo ""
    echo "See <https://mise.jdx.dev/installing-mise.html> for more options."
    exit 1
fi

# Get mise version

MISE_VERSION=$(mise --version 2>/dev/null || echo "unknown")
printf "${GREEN}✓ mise is installed: ${MISE_VERSION}${NC}\n"
echo ""

# Check if mise is activated in current shell

if [ -z "${MISE_SHELL_INIT:-}" ]; then
    printf "${YELLOW}⚠ mise activation not detected in current shell${NC}\n"
    echo ""
    echo "Add one of these to your shell rc file (~/.zshrc, ~/.bashrc, etc):"
    echo ""
    echo "For interactive shells (zsh, bash, fish, etc):"
    echo '  eval "$(mise activate zsh)"  # or bash, fish, ksh, nu, xonsh, elvish'
    echo ""
    echo "For non-interactive environments (CI, GUI apps):"
    echo '  eval "$(mise activate bash --shims)"'
    echo ""
else
    printf "${GREEN}✓ mise is activated in current shell${NC}\n"
fi

echo ""
echo "To verify setup, run:"
echo "  mise doctor"
