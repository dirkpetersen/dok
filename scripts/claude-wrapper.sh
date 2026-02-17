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

# Function to verify PATH configuration
verify_path_configuration() {
  local home_bin="$HOME/bin"
  local home_local_bin="$HOME/.local/bin"
  local current_shell="${SHELL##*/}"
  local rc_file=""
  local path_cmd=""
  local source_cmd=""

  # Determine which rc file and syntax to use based on shell
  if [[ "$current_shell" == "zsh" ]]; then
    rc_file="~/.zshrc"
    path_cmd="export PATH=\$HOME/bin:\$HOME/.local/bin:\$PATH"
    source_cmd=". $rc_file"
  elif [[ "$current_shell" == "tcsh" || "$current_shell" == "csh" ]]; then
    rc_file="~/.tcshrc"
    path_cmd="setenv PATH \$HOME/bin:\$HOME/.local/bin:\$PATH"
    source_cmd="source $rc_file"
  else
    rc_file="~/.bashrc"
    path_cmd="export PATH=\$HOME/bin:\$HOME/.local/bin:\$PATH"
    source_cmd=". $rc_file"
  fi

  # Check if ~/bin is in PATH
  if [[ ":$PATH:" != *":$home_bin:"* ]]; then
    echo -e "${RED}✗ Error: $home_bin is not in PATH${NC}" >&2
    echo "" >&2
    echo "To fix this, add the following to $rc_file:" >&2
    echo "" >&2
    echo "  $path_cmd" >&2
    echo "" >&2
    echo "Then reload your shell:" >&2
    echo "  $source_cmd" >&2
    echo "" >&2
    return 1
  fi

  # Check if ~/.local/bin is in PATH
  if [[ ":$PATH:" != *":$home_local_bin:"* ]]; then
    echo -e "${RED}✗ Error: $home_local_bin is not in PATH${NC}" >&2
    echo "" >&2
    echo "To fix this, add the following to $rc_file:" >&2
    echo "" >&2
    echo "  $path_cmd" >&2
    echo "" >&2
    echo "Then reload your shell:" >&2
    echo "  $source_cmd" >&2
    echo "" >&2
    return 1
  fi

  # Check if ~/bin comes before ~/.local/bin
  # Add colons to beginning and end for easier matching
  local normalized_path=":$PATH:"

  # Find the position of first occurrence of each directory
  local bin_pos="${normalized_path%%:$home_bin:*}"
  local local_bin_pos="${normalized_path%%:$home_local_bin:*}"

  # If local_bin appears before bin, the prefix will be shorter
  if [[ ${#local_bin_pos} -lt ${#bin_pos} ]]; then
    echo -e "${RED}✗ Error: $home_bin must come before $home_local_bin in PATH${NC}" >&2
    echo "" >&2
    echo "Current PATH order:" >&2
    echo "  $home_local_bin comes first" >&2
    echo "  $home_bin comes second" >&2
    echo "" >&2
    echo "To fix this, ensure $rc_file has:" >&2
    echo "" >&2
    echo "  $path_cmd" >&2
    echo "" >&2
    echo "Then reload your shell:" >&2
    echo "  $source_cmd" >&2
    echo "" >&2
    return 1
  fi

  return 0
}

# Function to find the real claude binary (not in ~/bin)
find_claude_binary() {
  # Get all claude executables in PATH
  local claude_paths=$(which -a claude 2>/dev/null || true)

  # Find first claude that is NOT in ~/bin
  local home_bin_expanded="$HOME/bin"
  local real_claude=""

  while IFS= read -r claude_path; do
    # Expand ~ in path for comparison
    local expanded_path="${claude_path/#\~/$HOME}"

    # Skip if it's in ~/bin (could be our symlink)
    if [[ "$expanded_path" != "$home_bin_expanded"* ]]; then
      real_claude="$expanded_path"
      break
    fi
  done <<< "$claude_paths"

  # If we found a real claude binary, return it
  if [[ -n "$real_claude" ]]; then
    echo "$real_claude"
    return 0
  fi

  # No Claude Code found outside ~/bin, try to install it
  echo -e "${YELLOW}Claude Code not found in PATH${NC}" >&2
  echo "" >&2
  echo "Installing Claude Code..." >&2
  echo "Running: curl -fsSL https://claude.ai/install.sh | bash -s latest" >&2
  echo "" >&2
  if curl -fsSL https://claude.ai/install.sh | bash -s latest; then
    echo -e "${GREEN}✓${NC} Claude Code installed successfully" >&2
    echo "" >&2
    # Re-check PATH after installation
    claude_paths=$(which -a claude 2>/dev/null || true)

    # Try to find it again
    while IFS= read -r claude_path; do
      local expanded_path="${claude_path/#\~/$HOME}"
      if [[ "$expanded_path" != "$home_bin_expanded"* ]]; then
        echo "$expanded_path"
        return 0
      fi
    done <<< "$claude_paths"

    # Still not found after install
    echo -e "${RED}✗ Claude Code still not found in PATH after installation${NC}" >&2
    echo "Please reload your shell and try again:" >&2
    local current_shell="${SHELL##*/}"
    if [[ "$current_shell" == "zsh" ]]; then
      echo "  . ~/.zshrc" >&2
    elif [[ "$current_shell" == "tcsh" || "$current_shell" == "csh" ]]; then
      echo "  source ~/.tcshrc" >&2
    else
      echo "  . ~/.bashrc" >&2
    fi
    return 1
  else
    echo -e "${RED}✗ Failed to install Claude Code${NC}" >&2
    return 1
  fi
}

# Function to install the wrapper
install_wrapper() {
  echo -e "${YELLOW}Installing Claude Code wrapper...${NC}"

  # Find the real claude binary (this will auto-install if not found)
  local real_claude=$(find_claude_binary)
  local find_result=$?

  if [[ $find_result -ne 0 ]] || [[ -z "$real_claude" ]]; then
    # Claude Code installation failed or not found
    echo -e "${RED}✗ Cannot install wrapper without Claude Code binary${NC}" >&2
    echo "" >&2
    echo "Please ensure Claude Code is installed and in your PATH." >&2
    echo "You may need to reload your shell:" >&2
    local current_shell="${SHELL##*/}"
    if [[ "$current_shell" == "zsh" ]]; then
      echo "  . ~/.zshrc" >&2
    elif [[ "$current_shell" == "tcsh" || "$current_shell" == "csh" ]]; then
      echo "  source ~/.tcshrc" >&2
    else
      echo "  . ~/.bashrc" >&2
    fi
    exit 1
  fi

  # Create ~/bin if it doesn't exist
  mkdir -p "$INSTALL_DIR"

  # Force remove old wrapper and symlink
  rm -f "$WRAPPER_PATH" "$SYMLINK_PATH"

  # Copy or download wrapper script to ~/bin
  # When script is piped (curl | bash), $0 will be "bash"
  # Always download from GitHub in this case to ensure latest version
  if [[ "$0" == "bash" ]] || [[ ! -f "$0" ]]; then
    echo -e "${YELLOW}Downloading wrapper script from GitHub...${NC}"
    if curl -fsSL -o "$WRAPPER_PATH" "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh?`date +%s`"; then
      echo -e "${GREEN}✓${NC} Downloaded wrapper script"
    else
      echo -e "${RED}✗ Failed to download wrapper script${NC}" >&2
      exit 1
    fi
    chmod +x "$WRAPPER_PATH"
    echo -e "${GREEN}✓${NC} Installed wrapper to ~/bin/$SCRIPT_NAME"
  else
    # Script is being run from a file, copy it
    echo -e "${YELLOW}Copying wrapper script...${NC}"
    if cp "$0" "$WRAPPER_PATH"; then
      echo -e "${GREEN}✓${NC} Copied wrapper script"
    else
      echo -e "${RED}✗ Failed to copy wrapper script${NC}" >&2
      exit 1
    fi
    chmod +x "$WRAPPER_PATH"
    echo -e "${GREEN}✓${NC} Installed wrapper to ~/bin/$SCRIPT_NAME"
  fi

  # Create fresh symlink
  ln -s "$SCRIPT_NAME" "$SYMLINK_PATH"
  echo -e "${GREEN}✓${NC} Created symlink ~/bin/claude"

  echo ""
  echo -e "${GREEN}=== Installation Complete! ===${NC}"
  echo ""
  echo "You can now run the claude wrapper from anywhere:"
  echo ""
  echo "  claude                # Launch with Haiku (fast/default)"
  echo "  claude sonnet         # Launch with Sonnet (balanced)"
  echo "  claude opus           # Launch with Opus (most capable)"
  echo "  claude opus-1m        # Launch with Opus in fast mode"
  echo "  claude sonnet-1m      # Launch with Sonnet in fast mode"
  echo "  claude -c opus        # Model name works anywhere in args"
  echo "  claude --local        # Use local LLM (requires LOCAL_ANTHROPIC_BASE_URL)"
  echo ""

  exit 0
}

# Create default .claude.json if it doesn't exist (must happen before any claude execution)
if [[ ! -f "$HOME/.claude.json" ]]; then
  cat > "$HOME/.claude.json" <<'EOF'
{
  "numStartups": 1,
  "customApiKeyResponses": {
    "approved": [
      "sk-ant-dummy"
    ],
    "rejected": []
  }
}
EOF
fi

# Verify PATH configuration first, before doing anything
verify_path_configuration
if [[ $? -ne 0 ]]; then
  exit 1
fi

# Check if this is an installation run
if [[ "$1" == "--install" ]]; then
  install_wrapper
fi

# Check if wrapper is already installed
# If we're being run from the installed location, skip installation checks
CURRENT_SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || echo "")"
INSTALLED_WRAPPER_PATH="$(readlink -f "$WRAPPER_PATH" 2>/dev/null || echo "")"

if [[ -n "$CURRENT_SCRIPT_PATH" && "$CURRENT_SCRIPT_PATH" == "$INSTALLED_WRAPPER_PATH" ]]; then
  # We're running from the installed location - proceed to wrapper functionality
  :
elif [[ -L "$SYMLINK_PATH" && -f "$WRAPPER_PATH" ]]; then
  # Wrapper is installed but we're running from a different location (e.g., git repo)
  echo -e "${GREEN}✓${NC} Wrapper already installed. Reinstalling to ensure latest version..."
  install_wrapper
  exit 0
else
  # Script is not installed yet, auto-install or prompt
  echo -e "${YELLOW}Claude Code wrapper is not installed yet.${NC}"

  # Check if stdin is a terminal (interactive) or pipe (non-interactive)
  if [[ -t 0 ]]; then
    # Interactive mode - prompt user
    read -p "Install to ~/bin/claude? (y/n): " install_confirm

    if [[ "$install_confirm" == "y" || "$install_confirm" == "Y" ]]; then
      install_wrapper
      # install_wrapper exits, so we won't reach here
    else
      echo "Installation cancelled. Run with --install to install later."
      exit 1
    fi
  else
    # Non-interactive mode (piped) - auto-install
    echo -e "${YELLOW}Running in non-interactive mode. Auto-installing...${NC}"
    install_wrapper
    # install_wrapper exits, so we won't reach here
  fi
fi

# ============================================================================
# WRAPPER FUNCTIONALITY
# ============================================================================

# Find the real claude binary once
REAL_CLAUDE=$(find_claude_binary)
if [[ $? -ne 0 ]]; then
  exit 1
fi

# Check if --local flag is used
if [[ "$1" == "--local" ]]; then
  shift  # Remove --local from arguments

  # Check if LOCAL_ANTHROPIC_BASE_URL is set
  if [[ -z "$LOCAL_ANTHROPIC_BASE_URL" ]]; then
    echo -e "${RED}✗ Error: --local flag used but LOCAL_ANTHROPIC_BASE_URL is not set${NC}" >&2
    echo "" >&2
    echo "To use --local, set the LOCAL_ANTHROPIC_BASE_URL environment variable:" >&2
    echo "  export LOCAL_ANTHROPIC_BASE_URL=\"http://llm.run.university.edu/cc/v1\"" >&2
    echo "" >&2
    echo "Optionally, also set local model names:" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL=\"hc/glm-4.7\"" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL=\"hc/glm-4.7\"" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL=\"hc/glm-4.7\"" >&2
    exit 1
  fi

  # Set ANTHROPIC_BASE_URL from LOCAL_ANTHROPIC_BASE_URL
  export ANTHROPIC_BASE_URL="$LOCAL_ANTHROPIC_BASE_URL"
  export ANTHROPIC_API_KEY="sk-ant-dummy"

  # Set model configurations if LOCAL_* variants exist
  [[ -n "$LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL" ]] && export ANTHROPIC_DEFAULT_HAIKU_MODEL="$LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL"
  [[ -n "$LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL" ]] && export ANTHROPIC_DEFAULT_SONNET_MODEL="$LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL"
  [[ -n "$LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL" ]] && export ANTHROPIC_DEFAULT_OPUS_MODEL="$LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL"

# Check if ANTHROPIC_BASE_URL is already set (for local LLM usage without --local flag)
elif [[ -n "$ANTHROPIC_BASE_URL" ]]; then
  # Set ANTHROPIC_API_KEY to dummy value if not set or invalid
  if [[ -z "$ANTHROPIC_API_KEY" ]] || [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
    export ANTHROPIC_API_KEY="sk-ant-dummy"
  fi

# Default: AWS Bedrock Configuration - only enable if bedrock is configured
elif grep -q "bedrock" "$HOME/.aws/config" 2>/dev/null; then
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_DEFAULT_REGION=us-west-2
  export AWS_PROFILE=bedrock

# No valid configuration found
else
  echo -e "${RED}✗ Error: No valid configuration found${NC}" >&2
  echo "" >&2
  echo "Options to fix this:" >&2
  echo "" >&2
  echo "1. Configure AWS Bedrock by getting AWS creds and then executing:" >&2
  echo "   aws configure --profile bedrock" >&2
  echo "" >&2
  echo "2. Use --local flag with a local LLM endpoint:" >&2
  echo "   claude --local" >&2
  echo "" >&2
  echo "3. Bypass this wrapper and run Claude Code directly:" >&2
  echo "   ~/.local/bin/claude" >&2
  exit 1
fi

# Model Configuration (Bedrock model IDs, overridden by LOCAL_* variants if set above)
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-us.anthropic.claude-haiku-4-5-20251001-v1:0}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-global.anthropic.claude-sonnet-4-6}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-global.anthropic.claude-opus-4-6-v1}"
export ANTHROPIC_SMALL_FAST_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"

# Default model is Haiku
mymodel="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"
model_name="haiku"

# Scan all arguments for model selection (allows e.g. "claude -c opus")
new_args=()
for arg in "$@"; do
  case "$arg" in
    opus-1m)
      mymodel="${ANTHROPIC_DEFAULT_OPUS_MODEL}[1m]"
      model_name="opus-1m"
      ;;
    opus)
      mymodel="${ANTHROPIC_DEFAULT_OPUS_MODEL}"
      model_name="opus"
      ;;
    sonnet-1m)
      mymodel="${ANTHROPIC_DEFAULT_SONNET_MODEL}[1m]"
      model_name="sonnet-1m"
      ;;
    sonnet)
      mymodel="${ANTHROPIC_DEFAULT_SONNET_MODEL}"
      model_name="sonnet"
      ;;
    haiku)
      mymodel="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"
      model_name="haiku"
      ;;
    *)
      new_args+=("$arg")
      ;;
  esac
done
set -- "${new_args[@]}"

export ANTHROPIC_MODEL="$mymodel"

# Show status message for local/custom base URL
if [[ -n "$ANTHROPIC_BASE_URL" ]]; then
  echo -e "${GREEN}Using local $model_name model: $mymodel${NC}" >&2
  echo -e "${GREEN}  Base URL: $ANTHROPIC_BASE_URL${NC}" >&2
fi

# Execute Claude Code
exec "$REAL_CLAUDE" --model "$mymodel" --dangerously-skip-permissions "$@"
