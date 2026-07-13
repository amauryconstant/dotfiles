#!/usr/bin/env bash
# dcli installation script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/usr/share/zsh/site-functions"
SCRIPT_NAME="dcli"
COMPLETION_NAME="_dcli"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_package() {
	local package="$1"

	case "$package" in
		go-yq)
			command -v yq &> /dev/null
			;;
		*)
			command -v "$package" &> /dev/null
			;;
	esac
}

get_aur_helper() {
	if check_package "paru"; then
		echo "paru" "https://github.com/morganamilo/paru"
	elif check_package "yay"; then
		echo "yay" "https://aur.archlinux.org/yay.git"
	else
		echo "paru" "https://github.com/morganamilo/paru"
	fi
}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  dcli Installation Script             ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Error: Do not run this script as root${NC}" >&2
  echo "Run as a regular user. The script will use sudo when needed." >&2
  exit 1
fi

# Check if dcli binary exists (Rust version)
if [ ! -f "$SCRIPT_DIR/target/release/$SCRIPT_NAME" ]; then
  echo -e "${YELLOW}Rust binary not found. Building from source...${NC}"
  echo ""

  # Check if cargo is installed
  if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo (Rust toolchain) not found${NC}" >&2
    echo ""
    echo "dcli requires Rust to build. You have two options:" >&2
    echo ""
    echo "Option 1 - Install Rust with rustup (recommended):" >&2
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" >&2
    echo "  source \$HOME/.cargo/env" >&2
    echo "  ./install.sh" >&2
    echo ""
    echo "Option 2 - Install Rust from Arch repos (may be older):" >&2
    echo "  sudo pacman -S rust" >&2
    echo "  ./install.sh" >&2
    echo ""
    read -p "Would you like to install Rust now with rustup? [Y/n] " -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      echo -e "${BLUE}Installing Rust...${NC}"
      if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo ""
        echo -e "${GREEN}✓${NC} Rust installed successfully"
        echo -e "${BLUE}Loading Rust environment...${NC}"
        if [ -f "$HOME/.cargo/env" ]; then
            source "$HOME/.cargo/env"
          else
            source "$HOME/.local/share/cargo/env"
        fi
        # Verify cargo is now available
        if ! command -v cargo &> /dev/null; then
          echo -e "${RED}Error: cargo still not found after installation${NC}" >&2
          echo "Please restart your terminal and run ./install.sh again" >&2
          exit 1
        fi
        echo -e "${GREEN}✓${NC} Rust is ready"
        echo ""
      else
        echo -e "${RED}Error: Failed to install Rust${NC}" >&2
        echo "Please install manually and try again" >&2
        exit 1
      fi
    else
      echo -e "${YELLOW}Installation cancelled${NC}"
      echo "Install Rust and run ./install.sh again"
      exit 1
    fi
  fi

  # Check if Cargo.toml exists
  if [ ! -f "$SCRIPT_DIR/Cargo.toml" ]; then
    echo -e "${RED}Error: Not a Rust project (Cargo.toml not found)${NC}" >&2
    exit 1
  fi

  echo -e "${BLUE}Building dcli with cargo (all features, locked deps)...${NC}"
  if ! cargo build --release --locked --all-features --manifest-path="$SCRIPT_DIR/Cargo.toml"; then
    echo -e "${RED}Error: Failed to build dcli${NC}" >&2
    exit 1
  fi
  echo -e "${GREEN}✓${NC} Build completed"
  echo ""
fi

# Verify the binary exists now
if [ ! -f "$SCRIPT_DIR/target/release/$SCRIPT_NAME" ]; then
  echo -e "${RED}Error: dcli binary not found after build${NC}" >&2
  exit 1
fi

# Check if dcli is already installed
if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
  echo -e "${YELLOW}Warning: dcli is already installed at $INSTALL_DIR/$SCRIPT_NAME${NC}"

  # Check if it's the old bash version (will be a text file with shebang)
  if head -n 1 "$INSTALL_DIR/$SCRIPT_NAME" 2>/dev/null | grep -q "^#!/"; then
    echo -e "${YELLOW}⚠ Detected old bash-based version of dcli${NC}"
    echo -e "${BLUE}This will be replaced with the new Rust-based version${NC}"
  fi

  read -p "Do you want to reinstall? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
  fi
fi

# Install dcli
echo -e "${BLUE}Installing dcli to $INSTALL_DIR...${NC}"
if sudo cp "$SCRIPT_DIR/target/release/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"; then
  echo -e "${GREEN}✓${NC} Copied dcli binary to $INSTALL_DIR"
else
  echo -e "${RED}Error: Failed to copy dcli${NC}" >&2
  exit 1
fi

# Make executable
if sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"; then
  echo -e "${GREEN}✓${NC} Set executable permissions"
else
  echo -e "${RED}Error: Failed to set permissions${NC}" >&2
  exit 1
fi

# Verify installation
if command -v dcli &> /dev/null; then
  echo -e "${GREEN}✓${NC} dcli is now available in PATH"
else
  echo -e "${RED}Error: dcli not found in PATH after installation${NC}" >&2
  echo "You may need to restart your terminal or run: hash -r" >&2
  exit 1
fi

# Install zsh completion
if [ -f "$SCRIPT_DIR/$COMPLETION_NAME" ]; then
  echo ""
  echo -e "${BLUE}Installing zsh completion...${NC}"
  if sudo mkdir -p "$COMPLETION_DIR" && sudo cp "$SCRIPT_DIR/$COMPLETION_NAME" "$COMPLETION_DIR/$COMPLETION_NAME"; then
    echo -e "${GREEN}✓${NC} Zsh completion installed to $COMPLETION_DIR"
    echo -e "${YELLOW}→${NC} You may need to restart your terminal or run: exec zsh"
  else
    echo -e "${YELLOW}⚠${NC} Failed to install zsh completion (non-critical)"
  fi
else
  echo -e "${YELLOW}⚠${NC} Zsh completion script not found (skipping)"
fi

# Check for dependencies
echo ""
echo -e "${BLUE}Checking dependencies...${NC}"

read aur_helper aur_helper_url <<< "$(get_aur_helper)"

dependencies=("$aur_helper" "fzf")
missing_deps=()
installable_deps=()

for dep in "${dependencies[@]}"; do
  if check_package "$dep"; then
    echo -e "${GREEN}✓${NC} $dep installed"
  else
    echo -e "${YELLOW}⚠${NC} $dep not installed"
    missing_deps+=("$dep")

    # Track which dependencies can be auto-installed
    case $dep in
      fzf)
        installable_deps+=("$dep")
        ;;
    esac
  fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}Missing dependencies:${NC}"
  for dep in "${missing_deps[@]}"; do
    case $dep in
      "$aur_helper")
        echo "  • ${aur_helper} - AUR helper (optional, but recommended)"
        echo "    Install from: ${aur_helper_url}"
        ;;
      fzf)
        echo "  • fzf - Fuzzy finder (required for search, module, and backup TUI features)"
        ;;
    esac
  done

  # Offer to install missing dependencies
  if [ ${#installable_deps[@]} -gt 0 ]; then
    echo ""
    read -p "Would you like to install missing dependencies now? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      echo ""
      echo -e "${BLUE}Installing dependencies...${NC}"

      # Install each missing dependency
      for dep in "${installable_deps[@]}"; do
        echo -e "${BLUE}→${NC} Installing $dep..."
        if sudo pacman -S --noconfirm "$dep"; then
          echo -e "${GREEN}✓${NC} $dep installed successfully"
          # Remove from missing_deps array
          missing_deps=("${missing_deps[@]/$dep}")
        else
          echo -e "${RED}✗${NC} Failed to install $dep"
        fi
      done

      # Clean up empty elements from array
      missing_deps=("${missing_deps[@]}")
    fi
  fi

fi

# Check for snapshot/backup tools (snapper or timeshift)
echo ""
echo -e "${BLUE}Checking for snapshot tools...${NC}"
has_snapper=false
has_timeshift=false

if check_package "snapper"; then
  echo -e "${GREEN}✓${NC} snapper installed"
  has_snapper=true
elif check_package "timeshift"; then
  echo -e "${GREEN}✓${NC} timeshift installed"
  has_timeshift=true
fi

# If neither is installed, offer a choice
if ! $has_snapper && ! $has_timeshift; then
  echo -e "${YELLOW}⚠${NC} No snapshot tool installed"
  echo ""
  echo "Which snapshot tool would you like to install?"
  echo "  1) timeshift (recommended for beginners)"
  echo "  2) snapper (more advanced, btrfs-focused)"
  echo "  3) Skip (install manually later)"
  echo ""
  read -p "Enter your choice [1-3]: " -n 1 -r snapshot_choice
  echo ""

  case $snapshot_choice in
    1)
      echo ""
      echo -e "${BLUE}→${NC} Installing timeshift..."
      if sudo pacman -S --noconfirm timeshift; then
        echo -e "${GREEN}✓${NC} timeshift installed successfully"
      else
        echo -e "${RED}✗${NC} Failed to install timeshift"
      fi
      ;;
    2)
      echo ""
      echo -e "${BLUE}→${NC} Installing snapper..."
      if sudo pacman -S --noconfirm snapper; then
        echo -e "${GREEN}✓${NC} snapper installed successfully"
      else
        echo -e "${RED}✗${NC} Failed to install snapper"
      fi
      ;;
    3)
      echo ""
      echo "Skipping snapshot tool installation"
      ;;
    *)
      echo ""
      echo "Invalid choice. Skipping snapshot tool installation"
      ;;
  esac
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation Complete!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  First computer?"
echo "    1. Run: dcli init"
echo "    2. Run: dcli repo init (to set up git)"
echo ""
echo "  Additional computer?"
echo "    • Run: dcli repo clone"
echo ""
echo "Run 'dcli help' to see all available commands"
