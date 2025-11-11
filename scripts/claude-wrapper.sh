#!/bin/bash
# claude-wrapper.sh
# Wrapper script for Claude Code with AWS Bedrock integration
# Provides easy model switching and proper permission handling

SCRIPT_NAME="claude-wrapper.sh"
INSTALL_DIR="$HOME/bin"
WRAPPER_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SYMLINK_PATH="$INSTALL_DIR/claude"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to find the real claude binary (not in ~/bin)
find_claude_binary() {
  # Get all claude executables in PATH
  local claude_paths=$(which -a claude 2>/dev/null || true)

  if [[ -z "$claude_paths" ]]; then
    echo -e "${RED}✗ Claude Code not found in PATH${NC}" >&2
    echo "Please install Claude Code first:" >&2
    echo "  npm i -g @anthropic-ai/claude-code" >&2
    return 1
  fi

  # Find first claude that is NOT in ~/bin
  local home_bin_expanded="$HOME/bin"
  while IFS= read -r claude_path; do
    # Expand ~ in path for comparison
    local expanded_path="${claude_path/#\~/$HOME}"

    # Skip if it's in ~/bin (could be our symlink)
    if [[ "$expanded_path" != "$home_bin_expanded"* ]]; then
      echo "$expanded_path"
      return 0
    fi
  done <<< "$claude_paths"

  echo -e "${RED}✗ Could not find Claude Code binary outside of ~/bin${NC}" >&2
  return 1
}

# Function to install the wrapper
install_wrapper() {
  echo -e "${YELLOW}Installing Claude Code wrapper...${NC}"

  # Find the real claude binary
  local real_claude=$(find_claude_binary)
  if [[ $? -ne 0 ]]; then
    exit 1
  fi

  echo -e "${GREEN}✓${NC} Found Claude Code at: $real_claude"

  # Create ~/bin if it doesn't exist
  mkdir -p "$INSTALL_DIR"

  # Copy or download wrapper script to ~/bin
  if [[ ! -f "$WRAPPER_PATH" ]] || [[ "$(readlink -f "$0" 2>/dev/null || echo "")" != "$(readlink -f "$WRAPPER_PATH" 2>/dev/null)" ]]; then
    # When script is piped (curl | bash), $0 will be "bash"
    # Always download from GitHub in this case for reliability
    if [[ "$0" == "bash" ]] || [[ ! -f "$0" ]]; then
      echo -e "${YELLOW}Downloading wrapper script from GitHub...${NC}"
      if curl -f -s -o "$WRAPPER_PATH" https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh; then
        echo -e "${GREEN}✓${NC} Downloaded wrapper script"
      else
        echo -e "${RED}✗ Failed to download wrapper script${NC}" >&2
        exit 1
      fi
    else
      # Script is being run from a file, copy it
      echo -e "${YELLOW}Copying wrapper script...${NC}"
      if cp "$0" "$WRAPPER_PATH"; then
        echo -e "${GREEN}✓${NC} Copied wrapper script"
      else
        echo -e "${RED}✗ Failed to copy wrapper script${NC}" >&2
        exit 1
      fi
    fi
    chmod +x "$WRAPPER_PATH"
    echo -e "${GREEN}✓${NC} Installed wrapper to $WRAPPER_PATH"
  fi

  # Create symlink if it doesn't exist or points elsewhere
  if [[ -L "$SYMLINK_PATH" ]]; then
    local current_target=$(readlink "$SYMLINK_PATH")
    if [[ "$current_target" != "$SCRIPT_NAME" ]]; then
      rm "$SYMLINK_PATH"
      ln -s "$SCRIPT_NAME" "$SYMLINK_PATH"
      echo -e "${GREEN}✓${NC} Updated symlink $SYMLINK_PATH -> $SCRIPT_NAME"
    else
      echo -e "${GREEN}✓${NC} Symlink already correctly configured"
    fi
  elif [[ -e "$SYMLINK_PATH" ]]; then
    echo -e "${RED}✗ $SYMLINK_PATH exists but is not a symlink${NC}"
    echo "Please remove it manually and run this script again"
    exit 1
  else
    ln -s "$SCRIPT_NAME" "$SYMLINK_PATH"
    echo -e "${GREEN}✓${NC} Created symlink $SYMLINK_PATH -> $SCRIPT_NAME"
  fi

  echo ""
  echo -e "${GREEN}=== Installation Complete! ===${NC}"
  echo ""
  echo "Usage:"
  echo "  claude .              # Launch with Haiku (fast/default)"
  echo "  claude sonnet .       # Launch with Sonnet (balanced)"
  echo "  claude opus .         # Launch with Opus (most capable)"
  echo ""
  echo "The wrapper is now installed at: $SYMLINK_PATH"
  echo "Real Claude Code binary: $real_claude"
  echo ""

  exit 0
}

# Check if this is an installation run
if [[ "$1" == "--install" ]]; then
  install_wrapper
fi

# If script is not in ~/bin yet, auto-install or prompt
if [[ "$(readlink -f "$0")" != "$(readlink -f "$WRAPPER_PATH")" ]]; then
  echo -e "${YELLOW}Claude Code wrapper is not installed yet.${NC}"

  # Check if stdin is a terminal (interactive) or pipe (non-interactive)
  if [[ -t 0 ]]; then
    # Interactive mode - prompt user
    read -p "Install to $INSTALL_DIR/claude? (y/n): " install_confirm

    if [[ "$install_confirm" == "y" || "$install_confirm" == "Y" ]]; then
      install_wrapper
    else
      echo "Installation cancelled. Run with --install to install later."
      exit 1
    fi
  else
    # Non-interactive mode (piped) - auto-install
    echo -e "${YELLOW}Running in non-interactive mode. Auto-installing...${NC}"
    install_wrapper
  fi
fi

# ============================================================================
# WRAPPER FUNCTIONALITY
# ============================================================================

# AWS Bedrock Configuration
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-west-2
export AWS_PROFILE=bedrock

# Model Configuration
export ANTHROPIC_DEFAULT_HAIKU_MODEL="us.anthropic.claude-haiku-4-5-20251001-v1:0"
export ANTHROPIC_DEFAULT_SONNET_MODEL="us.anthropic.claude-sonnet-4-5-20250929-v1:0"
export ANTHROPIC_DEFAULT_OPUS_MODEL="us.anthropic.claude-opus-4-1-20250805-v1:0"
export ANTHROPIC_SMALL_FAST_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"

# Set default model to Haiku
mymodel="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"

# Check first argument for model selection
if [[ "$1" == "opus" ]]; then
  mymodel="opus"
  shift
elif [[ "$1" == "sonnet" ]]; then
  mymodel="sonnet[1m]"
  shift
elif [[ "$1" == "haiku" ]]; then
  mymodel="haiku"
  shift
fi

# Set the model environment variable
export ANTHROPIC_MODEL="us.anthropic.claude-${mymodel/-*/}-${mymodel/*-/}"

# Find the real claude binary
REAL_CLAUDE=$(find_claude_binary)
if [[ $? -ne 0 ]]; then
  exit 1
fi

# Execute the real Claude Code with model selection
# Note: Using --dangerously-skip-permissions for unrestricted access
# Remove this flag if you want to use permission restrictions
exec "$REAL_CLAUDE" --model "$mymodel" --dangerously-skip-permissions "$@"
