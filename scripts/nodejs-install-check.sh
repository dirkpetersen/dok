#!/bin/bash
# nodejs-install-check.sh
# Script to check and install Node.js/npm with proper configuration
# Works on both standard Linux/macOS and HPC systems with Lmod

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to detect user's login shell and add nvm initialization to PATH
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
      echo -e "${YELLOW}Warning: Detected shell '$login_shell'. Please manually add NVM initialization to your shell RC file.${NC}"
      return 1
      ;;
  esac

  # Check if NVM initialization already exists
  if grep -q 'NVM_DIR.*nvm.sh' "$shell_rc" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} NVM already configured in $shell_name configuration"
    return 0
  fi

  # Add NVM initialization to shell RC file
  echo "" >> "$shell_rc"
  echo "# NVM (Node Version Manager) initialization" >> "$shell_rc"
  echo "export NVM_DIR=\"\$HOME/.nvm\"" >> "$shell_rc"
  echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"  # This loads nvm" >> "$shell_rc"
  echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion" >> "$shell_rc"

  echo -e "${GREEN}✓${NC} Added NVM initialization to $shell_name configuration ($shell_rc)"
  return 0
}

# Check if npm is installed
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
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

if [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
  echo -e "${RED}✗ Failed to install NVM${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} NVM installed successfully"

# Load nvm in current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js (version 24, latest LTS)
echo -e "${YELLOW}Installing Node.js v24...${NC}"
nvm install 24

if ! command -v npm &> /dev/null; then
  echo -e "${RED}✗ Failed to install Node.js${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Node.js installed successfully"

# Configure npm to install global packages in home directory
echo -e "${YELLOW}Configuring npm...${NC}"
npm_prefix=$(npm config get prefix 2>/dev/null || echo "")

if [[ "$npm_prefix" != "$HOME/.nvm"* ]]; then
  echo -e "${YELLOW}Setting npm prefix to NVM directory...${NC}"
  npm config set prefix "$HOME/.nvm/versions/node/$(node --version | cut -d'v' -f2)"
fi

# Add NVM initialization to shell configuration
echo -e "${YELLOW}Configuring shell...${NC}"
add_nvm_to_shell

# Final instructions
echo ""
echo "========================================"
echo "Node.js/npm installation complete!"
echo "========================================"
echo ""
echo "To apply the PATH changes, reload your shell configuration:"
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
echo "Then verify the installation:"
echo "  npm --version"
echo ""
