#!/usr/bin/env bash
# dcli migration script - Bash to Rust version

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  dcli Bash → Rust Migration            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Error: Do not run this script as root${NC}" >&2
  echo "Run as a regular user. The script will use sudo when needed." >&2
  exit 1
fi

# Check if dcli is currently installed
if ! command -v dcli &> /dev/null; then
  echo -e "${RED}Error: dcli is not currently installed${NC}" >&2
  echo "This script is for upgrading from bash to Rust version." >&2
  echo "For fresh installation, run: ./install.sh" >&2
  exit 1
fi

echo -e "${BLUE}Current dcli installation:${NC}"
dcli --version 2>/dev/null || echo "  Bash version (no version flag)"
which dcli
echo ""

# Backup current dcli
echo -e "${BLUE}Backing up current dcli installation...${NC}"
if sudo cp /usr/local/bin/dcli /usr/local/bin/dcli.bash.backup 2>/dev/null; then
  echo -e "${GREEN}✓${NC} Backed up to: /usr/local/bin/dcli.bash.backup"
else
  echo -e "${YELLOW}⚠${NC} Could not backup (maybe already Rust version?)"
fi
echo ""

# Check for Rust toolchain
echo -e "${BLUE}Checking for Rust toolchain...${NC}"
if ! command -v cargo &> /dev/null; then
  echo -e "${YELLOW}Rust not found. Installing rustup...${NC}"
  echo ""

  # Install rustup
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

  # Source cargo env
  source "$HOME/.cargo/env"

  echo ""
  echo -e "${GREEN}✓${NC} Rust toolchain installed"
else
  echo -e "${GREEN}✓${NC} Rust toolchain found"
  cargo --version
fi
echo ""

# Check if we need to source cargo
if ! command -v cargo &> /dev/null; then
  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  fi
fi

# Verify cargo is available
if ! command -v cargo &> /dev/null; then
  echo -e "${RED}Error: cargo still not available after installation${NC}" >&2
  echo "Please run: source \$HOME/.cargo/env" >&2
  echo "Then try this script again." >&2
  exit 1
fi

# Build Rust binary
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Building Rust binary...${NC}"
echo -e "${YELLOW}This may take a few minutes on first build...${NC}"
echo ""

if ! cargo build --release --manifest-path="$SCRIPT_DIR/Cargo.toml"; then
  echo -e "${RED}Error: Failed to build dcli${NC}" >&2
  exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Build completed successfully"
echo ""

# Verify binary exists
if [ ! -f "$SCRIPT_DIR/target/release/dcli" ]; then
  echo -e "${RED}Error: Binary not found after build${NC}" >&2
  exit 1
fi

# Install new binary
echo -e "${BLUE}Installing Rust binary to /usr/local/bin...${NC}"
if sudo cp "$SCRIPT_DIR/target/release/dcli" /usr/local/bin/dcli; then
  echo -e "${GREEN}✓${NC} Installed Rust binary"
else
  echo -e "${RED}Error: Failed to install binary${NC}" >&2
  exit 1
fi

# Set executable permissions
if sudo chmod +x /usr/local/bin/dcli; then
  echo -e "${GREEN}✓${NC} Set executable permissions"
else
  echo -e "${RED}Error: Failed to set permissions${NC}" >&2
  exit 1
fi
echo ""

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"
if command -v dcli &> /dev/null; then
  echo -e "${GREEN}✓${NC} dcli is available in PATH"
  NEW_VERSION=$(dcli --version 2>/dev/null || echo "unknown")
  echo -e "${GREEN}✓${NC} New version: ${NEW_VERSION}"
else
  echo -e "${RED}Error: dcli not found after installation${NC}" >&2
  exit 1
fi
echo ""

# Check arch-config
if [ -d "$HOME/.config/arch-config" ]; then
  echo -e "${BLUE}Checking your arch-config...${NC}"
  if dcli status &> /dev/null; then
    echo -e "${GREEN}✓${NC} Your configuration is compatible"
  else
    echo -e "${YELLOW}⚠${NC} Configuration check had warnings (this may be normal)"
  fi
  echo ""
fi

# Optional: Check for go-yq
if command -v yq &> /dev/null; then
  echo -e "${YELLOW}Note: go-yq is still installed but no longer needed${NC}"
  echo "You can remove it with: ${BLUE}sudo pacman -Rs go-yq${NC}"
  echo ""
fi

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Migration Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Your dcli has been upgraded to the Rust version!"
echo ""
echo "What's new:"
echo "  • Zero runtime dependencies (no more go-yq needed)"
echo "  • Significantly faster performance"
echo "  • Better error handling"
echo "  • All your configs and modules work exactly the same!"
echo ""
echo "Next steps:"
echo "  • Test: ${BLUE}dcli status${NC}"
echo "  • Run: ${BLUE}dcli sync${NC}"
echo ""
echo "If you need to rollback:"
echo "  ${BLUE}sudo cp /usr/local/bin/dcli.bash.backup /usr/local/bin/dcli${NC}"
echo ""
