#!/bin/bash
# dev-station-install.sh
# One-stop installer for development workstation setup
# Installs: shell-setup.sh, claude-wrapper.sh, nodejs, and AWS CLI

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub raw URL base
GITHUB_RAW="https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts"

# Detect OS and architecture
detect_platform() {
  local os=$(uname -s | tr '[:upper:]' '[:lower:]')
  local arch=$(uname -m)

  # Normalize architecture names
  case "$arch" in
    x86_64|amd64)
      arch="x86_64"
      ;;
    aarch64|arm64)
      arch="aarch64"
      ;;
    *)
      echo -e "${RED}✗ Unsupported architecture: $arch${NC}" >&2
      return 1
      ;;
  esac

  # Normalize OS names
  case "$os" in
    linux)
      os="linux"
      ;;
    darwin)
      os="macos"
      ;;
    *)
      echo -e "${RED}✗ Unsupported OS: $os${NC}" >&2
      return 1
      ;;
  esac

  echo "$os|$arch"
}

# Portable unzip function - uses unzip if available, falls back to Python
portable_unzip() {
  local zipfile="$1"
  local destdir="${2:-.}"

  if command -v unzip &> /dev/null; then
    unzip -q "$zipfile" -d "$destdir"
  elif command -v python3 &> /dev/null; then
    python3 -c "import zipfile; zipfile.ZipFile('$zipfile').extractall('$destdir')"
  elif command -v python &> /dev/null; then
    python -c "import zipfile; zipfile.ZipFile('$zipfile').extractall('$destdir')"
  else
    echo -e "${RED}✗ Cannot extract zip file: neither 'unzip' nor 'python' is available${NC}" >&2
    echo -e "${YELLOW}Please install unzip: sudo apt install unzip (or equivalent)${NC}" >&2
    return 1
  fi
}

# Show help
show_help() {
  cat << 'EOF'
dev-station-install.sh - Development workstation setup installer

USAGE:
  ./dev-station-install.sh [OPTIONS]

OPTIONS:
  (none)      Install all components (shell-setup in light mode, claude-wrapper,
              nodejs, and AWS CLI if not already installed)

  --full      Run shell-setup.sh in full interactive mode instead of light mode

  --help      Show this help message

WHAT IT INSTALLS:
  1. shell-setup.sh (--light mode by default)
     - PATH directories and convenience settings
     - Vim configuration with edr command
     - Git default branch set to 'main'

  2. claude-wrapper.sh
     - AWS Bedrock wrapper for Claude Code CLI
     - Model switching (opus/sonnet/haiku)

  3. Node.js (via nodejs-install-check.sh)
     - Required for Claude Code CLI

  4. AWS CLI v2 (if not already installed)
     - Installs to user directory (~/.local/aws-cli)
     - No sudo required

REQUIREMENTS:
  - curl (for downloading)
  - python3 or unzip (for extracting AWS CLI)

EXAMPLES:
  # Quick setup with defaults (light mode)
  ./dev-station-install.sh

  # Full interactive shell setup
  ./dev-station-install.sh --full

MORE INFORMATION:
  Repository: https://github.com/dirkpetersen/dok
  Documentation: https://dirkpetersen.github.io/dok

EOF
  exit 0
}

# Install shell-setup.sh
install_shell_setup() {
  local mode="$1"
  echo -e "\n${GREEN}=== Installing shell-setup.sh ===${NC}\n"

  mkdir -p ~/temp
  curl -fsSL -o ~/temp/shell-setup.sh "${GITHUB_RAW}/shell-setup.sh?`date +%s`"
  chmod +x ~/temp/shell-setup.sh

  if [[ "$mode" == "full" ]]; then
    echo -e "${YELLOW}Running shell-setup.sh in full interactive mode...${NC}\n"
    bash ~/temp/shell-setup.sh
  else
    echo -e "${YELLOW}Running shell-setup.sh in light mode...${NC}\n"
    bash ~/temp/shell-setup.sh --light
  fi
}

# Install claude-wrapper.sh
install_claude_wrapper() {
  echo -e "\n${GREEN}=== Installing claude-wrapper.sh ===${NC}\n"

  mkdir -p ~/temp
  curl -fsSL -o ~/temp/claude-wrapper.sh "${GITHUB_RAW}/claude-wrapper.sh?`date +%s`"
  chmod +x ~/temp/claude-wrapper.sh

  # Run installation
  bash ~/temp/claude-wrapper.sh --install
}

# Install Node.js
install_nodejs() {
  echo -e "\n${GREEN}=== Checking/Installing Node.js ===${NC}\n"

  mkdir -p ~/temp
  curl -fsSL -o ~/temp/nodejs-install-check.sh "${GITHUB_RAW}/nodejs-install-check.sh?`date +%s`"
  chmod +x ~/temp/nodejs-install-check.sh

  # Run installation check
  bash ~/temp/nodejs-install-check.sh
}

# Install AWS CLI v2
install_aws_cli() {
  echo -e "\n${GREEN}=== Installing AWS CLI v2 ===${NC}\n"

  # Check if already installed
  if command -v aws &> /dev/null; then
    local aws_version=$(aws --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} AWS CLI already installed: $aws_version"
    return 0
  fi

  # Detect platform
  local platform_info=$(detect_platform)
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}✗ Failed to detect platform${NC}"
    return 1
  fi

  local os=$(echo "$platform_info" | cut -d'|' -f1)
  local arch=$(echo "$platform_info" | cut -d'|' -f2)

  echo -e "${YELLOW}Detected platform: $os ($arch)${NC}"

  # Determine download URL based on platform
  local download_url=""
  case "$os" in
    linux)
      if [[ "$arch" == "x86_64" ]]; then
        download_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
      elif [[ "$arch" == "aarch64" ]]; then
        download_url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
      fi
      ;;
    macos)
      # macOS uses universal binary
      download_url="https://awscli.amazonaws.com/AWSCLIV2.pkg"
      ;;
  esac

  if [[ -z "$download_url" ]]; then
    echo -e "${RED}✗ No AWS CLI download available for $os ($arch)${NC}"
    return 1
  fi

  # Create temp directory for installation
  local temp_dir=$(mktemp -d)
  cd "$temp_dir"

  echo -e "${YELLOW}Downloading AWS CLI...${NC}"

  if [[ "$os" == "macos" ]]; then
    # macOS installation (pkg installer requires different approach for user install)
    # Fall back to zip method which supports user directory installation
    download_url="https://awscli.amazonaws.com/awscli-exe-macos.zip"
    curl -fsSL "$download_url" -o "awscliv2.zip"

    echo -e "${YELLOW}Extracting AWS CLI...${NC}"
    portable_unzip "awscliv2.zip"

    echo -e "${YELLOW}Installing AWS CLI to ~/.local/aws-cli...${NC}"
    mkdir -p ~/.local/bin ~/.local/aws-cli
    ./aws/install -i ~/.local/aws-cli -b ~/.local/bin --update

  else
    # Linux installation
    curl -fsSL "$download_url" -o "awscliv2.zip"

    echo -e "${YELLOW}Extracting AWS CLI...${NC}"
    portable_unzip "awscliv2.zip"

    echo -e "${YELLOW}Installing AWS CLI to ~/.local/aws-cli...${NC}"
    mkdir -p ~/.local/bin ~/.local/aws-cli
    ./aws/install -i ~/.local/aws-cli -b ~/.local/bin --update
  fi

  # Cleanup
  cd - > /dev/null
  rm -rf "$temp_dir"

  # Verify installation (need to use full path since PATH may not be updated yet)
  if [[ -x ~/.local/bin/aws ]]; then
    local aws_version=$(~/.local/bin/aws --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} AWS CLI installed successfully: $aws_version"
    echo -e "${YELLOW}Note: Make sure ~/.local/bin is in your PATH${NC}"
  else
    echo -e "${RED}✗ AWS CLI installation failed${NC}"
    return 1
  fi
}

# Main function
main() {
  local shell_setup_mode="light"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        show_help
        ;;
      --full)
        shell_setup_mode="full"
        shift
        ;;
      *)
        echo -e "${RED}✗ Unknown option: $1${NC}"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done

  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║      Development Workstation Installer                    ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

  # Detect and display platform
  local platform_info=$(detect_platform)
  if [[ $? -eq 0 ]]; then
    local os=$(echo "$platform_info" | cut -d'|' -f1)
    local arch=$(echo "$platform_info" | cut -d'|' -f2)
    echo -e "\n${YELLOW}Platform: $os ($arch)${NC}"
  fi

  # Check for required tools
  if ! command -v curl &> /dev/null; then
    echo -e "${RED}✗ curl is required but not installed${NC}"
    exit 1
  fi

  # Check for unzip or python (needed for AWS CLI)
  if ! command -v unzip &> /dev/null && ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${YELLOW}⚠ Neither 'unzip' nor 'python' found - AWS CLI installation may fail${NC}"
  fi

  # Run installations
  install_shell_setup "$shell_setup_mode"
  install_aws_cli
  install_nodejs
  install_claude_wrapper

  # Final summary
  echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║      Installation Complete!                               ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

  echo -e "\n${YELLOW}What was installed:${NC}"
  echo "  ✓ Shell setup (PATH, Vim, convenience settings)"
  echo "  ✓ AWS CLI v2 (to ~/.local/bin)"
  echo "  ✓ Node.js"
  echo "  ✓ Claude wrapper (to ~/bin/claude)"

  echo -e "\n${YELLOW}Next steps:${NC}"
  echo "1. Reload your shell configuration:"
  local current_shell="${SHELL##*/}"
  if [[ "$current_shell" == "zsh" ]]; then
    echo "   source ~/.zshrc"
  elif [[ "$current_shell" == "tcsh" || "$current_shell" == "csh" ]]; then
    echo "   source ~/.tcshrc"
  else
    echo "   source ~/.bashrc"
  fi

  echo ""
  echo "2. Configure AWS credentials (if not already done):"
  echo "   aws configure --profile bedrock"

  echo ""
  echo "3. Start using Claude Code:"
  echo "   claude"

  echo -e "\n${GREEN}Happy coding!${NC}"
}

# Run main function
main "$@"
