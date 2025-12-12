#!/bin/bash
# nodejs-install-check.sh
# Script to check and install Node.js/npm with proper configuration
# Works on both standard Linux/macOS and HPC systems with Lmod

# Note: NOT using set -e because we want to handle errors gracefully

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to detect user's login shell and add nvm initialization to shell rc
add_nvm_to_shell() {
  local shell_rc=""
  local shell_name=""
  local login_shell=""

  # Get the user's login shell from the SHELL environment variable
  login_shell="${SHELL##*/}"  # Extract shell name from path (e.g., /bin/zsh -> zsh)

  case "$login_shell" in
    zsh)
      shell_rc="$HOME/.zshrc"
      shell_name="Zsh"
      ;;
    bash)
      shell_rc="$HOME/.bashrc"
      shell_name="Bash"
      ;;
    *)
      echo -e "${YELLOW}Warning: Detected shell '$login_shell'. Please manually add NVM initialization.${NC}"
      return 1
      ;;
  esac

  # Create shell rc file if it doesn't exist
  if [[ ! -f "$shell_rc" ]]; then
    touch "$shell_rc"
    echo -e "${YELLOW}Created new $shell_name configuration file: $shell_rc${NC}"
  fi

  # Check if NVM initialization already exists (uncommented)
  if grep -q '^[^#]*NVM_DIR.*nvm.sh' "$shell_rc" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} NVM already configured in $shell_name configuration"
    return 0
  fi

  # Remove commented-out NVM lines if they exist
  if grep -q '#.*NVM_DIR.*nvm.sh' "$shell_rc" 2>/dev/null; then
    echo -e "${YELLOW}Removing commented NVM configuration...${NC}"
    sed -i.bak '/^#.*NVM_DIR/d; /^#.*nvm.sh/d; /^#.*bash_completion/d' "$shell_rc"
    rm -f "${shell_rc}.bak"
  fi

  # Add NVM initialization to shell RC file
  # Use a separator comment to mark our additions
  echo "" >> "$shell_rc"
  echo "# ========== NVM (Node Version Manager) initialization ==========" >> "$shell_rc"
  echo "export NVM_DIR=\"\$HOME/.nvm\"" >> "$shell_rc"
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> "$shell_rc"
  echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> "$shell_rc"
  echo "# ================================================================" >> "$shell_rc"

  echo -e "${GREEN}✓${NC} Added NVM initialization to $shell_name configuration"
  return 0
}

# Check if npm is already installed
if command -v npm &> /dev/null; then
  echo -e "${GREEN}✓${NC} npm is already installed"
  npm --version
  exit 0
fi

echo -e "${YELLOW}npm not found. Installing Node.js via NVM...${NC}"
echo ""

# Try loading nodejs module first (for HPC systems that have it)
if command -v module &> /dev/null; then
  echo -e "${YELLOW}Attempting to load nodejs module...${NC}"
  if module load nodejs 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Successfully loaded nodejs module"
    if command -v npm &> /dev/null; then
      echo -e "${GREEN}✓${NC} npm is now available"
      npm --version
      exit 0
    fi
  else
    echo -e "${YELLOW}⊘${NC} nodejs module not found or failed to load. Proceeding with NVM installation..."
  fi
fi

# Install NVM (Node Version Manager)
echo -e "${YELLOW}Installing NVM (Node Version Manager)...${NC}"

# Check if NVM already installed
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

  if [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
    echo -e "${RED}✗ Failed to install NVM${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓${NC} NVM installed successfully"
else
  echo -e "${GREEN}✓${NC} NVM already exists at $HOME/.nvm"
fi

# Add NVM initialization to shell configuration
echo -e "${YELLOW}Configuring shell...${NC}"
add_nvm_to_shell
if [[ $? -ne 0 ]]; then
  echo -e "${RED}✗ Failed to configure shell${NC}"
  exit 1
fi

# Load nvm in current shell session
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  echo -e "${RED}✗ NVM script not found at $NVM_DIR/nvm.sh${NC}"
  exit 1
fi

# Source NVM in current shell
. "$NVM_DIR/nvm.sh" 2>/dev/null || true

# Verify NVM is loaded
if ! command -v nvm &> /dev/null; then
  echo -e "${RED}✗ Failed to load NVM in current shell${NC}"
  echo -e "${YELLOW}Try reloading your shell: source ~/.bashrc${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} NVM loaded in current shell"

# Install Node.js (version 24, latest LTS)
echo -e "${YELLOW}Installing Node.js v24...${NC}"
nvm install 24

if ! command -v npm &> /dev/null; then
  echo -e "${RED}✗ Failed to install Node.js${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Node.js installed successfully"

# Verify versions
echo ""
echo -e "${GREEN}Installation Summary:${NC}"
node --version
npm --version

# Final instructions
echo ""
echo "========================================"
echo "Node.js/npm installation complete!"
echo "========================================"
echo ""
echo "To apply the NVM configuration in new shell sessions:"
echo ""
if [[ -n "$ZSH_VERSION" ]]; then
  echo "  source ~/.zshrc"
elif [[ -n "$BASH_VERSION" ]]; then
  echo "  source ~/.bashrc"
else
  case "$SHELL" in
    */zsh)
      echo "  source ~/.zshrc"
      ;;
    */bash)
      echo "  source ~/.bashrc"
      ;;
  esac
fi
echo ""
echo "Then install Claude Code:"
echo "  npm install -g @anthropic-ai/claude-code"
echo ""
