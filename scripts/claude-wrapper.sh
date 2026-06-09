#!/bin/bash
# claude-wrapper.sh
# Wrapper script for Claude Code with AWS Bedrock integration
# Provides easy model switching and proper permission handling

SCRIPT_NAME="claude-wrapper.sh"
WRAPPER_VERSION="1.22"
INSTALL_DIR="$HOME/bin"
WRAPPER_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SYMLINK_PATH="$INSTALL_DIR/claude"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ENV_FILE="$HOME/.claude/claude-wrapper.env"

# Portable file checksum: md5sum on Linux, md5 on macOS/BSD. Prints the hash
# only, or nothing if neither tool is available (callers treat empty as "unknown").
_file_md5() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" 2>/dev/null | cut -d' ' -f1
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  fi
}

# Write or update a single KEY="value" line in claude-wrapper.env.
# Values are double-quoted so the file can be safely `source`d even when a
# value contains spaces; any embedded double quotes are escaped.
_set_wrapper_env() {
  local key="$1" value="$2"
  mkdir -p "$HOME/.claude"
  [[ -f "$ENV_FILE" ]] || printf "# Claude wrapper settings\n" > "$ENV_FILE"
  local tmpf
  tmpf=$(mktemp)
  grep -v "^${key}=" "$ENV_FILE" > "$tmpf" 2>/dev/null || true
  printf '%s="%s"\n' "$key" "${value//\"/\\\"}" >> "$tmpf"
  mv "$tmpf" "$ENV_FILE"
}

# Migrate legacy files into claude-wrapper.env, then delete them (idempotent)
_migrate_to_wrapper_env() {
  # claudelocalrc → LOCAL_* vars
  if [[ -f "$HOME/.claude/claudelocalrc" ]]; then
    while IFS= read -r _mline; do
      _mline="${_mline#export }"
      [[ "$_mline" =~ ^LOCAL_[A-Z_]+=.* ]] || continue
      local _mkey="${_mline%%=*}"
      local _mval="${_mline#*=}"
      _mval="${_mval#\"}" ; _mval="${_mval%\"}"
      grep -q "^${_mkey}=" "$ENV_FILE" 2>/dev/null || _set_wrapper_env "$_mkey" "$_mval"
    done < "$HOME/.claude/claudelocalrc"
    rm -f "$HOME/.claude/claudelocalrc"
  fi
  # wrapper-last-update → WRAPPER_LAST_UPDATE
  if [[ -f "$HOME/.claude/wrapper-last-update" ]]; then
    local _mts
    _mts=$(cat "$HOME/.claude/wrapper-last-update" 2>/dev/null || echo 0)
    grep -q "^WRAPPER_LAST_UPDATE=" "$ENV_FILE" 2>/dev/null || _set_wrapper_env "WRAPPER_LAST_UPDATE" "$_mts"
    rm -f "$HOME/.claude/wrapper-last-update"
  fi
  # yolo-mode flag file → WRAPPER_YOLO
  if [[ -f "$HOME/.claude/yolo-mode" ]]; then
    grep -q "^WRAPPER_YOLO=" "$ENV_FILE" 2>/dev/null || _set_wrapper_env "WRAPPER_YOLO" "1"
    rm -f "$HOME/.claude/yolo-mode"
  fi
}

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
  local claude_paths
  claude_paths=$(which -a claude 2>/dev/null || true)

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
  echo "Running: curl -fsSL https://claude.ai/install.sh | bash" >&2
  echo "" >&2
  local _install_sh
  _install_sh=$(mktemp)
  if ! curl -fsSL -o "$_install_sh" https://claude.ai/install.sh; then
    echo -e "${RED}✗ Failed to download Claude Code installer (HTTP error)${NC}" >&2
    rm -f "$_install_sh"
    return 1
  fi
  if bash "$_install_sh" latest; then
    rm -f "$_install_sh"
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
    rm -f "$_install_sh"
    echo -e "${RED}✗ Failed to install Claude Code${NC}" >&2
    return 1
  fi
}

# Function to install the wrapper
install_wrapper() {
  echo -e "${YELLOW}Installing Claude Code wrapper...${NC}"

  # Find the real claude binary (this will auto-install if not found)
  # Declare first, then assign separately — combining `local x=$(...)` would
  # capture local's exit status (always 0) instead of find_claude_binary's.
  local real_claude
  real_claude=$(find_claude_binary)
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
  echo "  claude                # Launch with default model (haiku unless changed)"
  echo "  claude sonnet         # Launch with Sonnet (balanced)"
  echo "  claude opus           # Launch with Opus (most capable)"
  echo "  claude opus-1m        # Launch with Opus (1M token context window)"
  echo "  claude fable          # Launch with Fable 5 (1M context window by default)"
  echo "  claude fable-1m       # Alias for fable (1M is already the default)"
  echo "  claude sonnet-1m      # Launch with Sonnet (1M token context window)"
  echo "  claude -c opus        # Model name works anywhere in args"
  echo "  claude default opus   # Set persistent default model (haiku/sonnet/opus/fable/sonnet-1m/opus-1m/fable-1m)"
  echo "  claude default yolo   # Skip all permission prompts (sets WRAPPER_YOLO=1)"
  echo "  claude default noyolo # Re-enable permission prompts (sets WRAPPER_YOLO=0)"
  echo "  claude --models       # Show default Anthropic models"
  echo "  claude update         # Update wrapper and Claude Code"
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

# Source ~/.azure/clauderc if it exists (loads Foundry and other Azure settings)
CLAUDERC_LOADED=0
if [[ -f "$HOME/.azure/clauderc" ]]; then
  CLAUDERC_LOADED=1
  # shellcheck source=/dev/null
  source "$HOME/.azure/clauderc"
fi

# Migrate any legacy files into claude-wrapper.env (deletes them on success)
_migrate_to_wrapper_env

# Load claude-wrapper.env — single source of truth for wrapper settings
ENV_FILE_LOADED=0
if [[ -f "$ENV_FILE" ]]; then
  ENV_FILE_LOADED=1
  # shellcheck source=/dev/null
  set -a; source "$ENV_FILE"; set +a
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

# Check if --models flag is used
if [[ "$1" == "--models" ]]; then
  echo ""
  echo "Default Anthropic Models:"
  echo ""
  echo "  Haiku:  ${ANTHROPIC_DEFAULT_HAIKU_MODEL:-us.anthropic.claude-haiku-4-5-20251001-v1:0}"
  echo "  Sonnet: ${ANTHROPIC_DEFAULT_SONNET_MODEL:-global.anthropic.claude-sonnet-4-6}"
  echo "  Opus:   ${ANTHROPIC_DEFAULT_OPUS_MODEL:-global.anthropic.claude-opus-4-8}"
  echo "  Fable:  ${ANTHROPIC_DEFAULT_FABLE_MODEL:-anthropic.claude-fable-5}"
  echo ""
  echo "Fast mode models (append [1m] to base model):"
  echo "  Sonnet: ${ANTHROPIC_DEFAULT_SONNET_MODEL:-global.anthropic.claude-sonnet-4-6}[1m]"
  echo "  Opus:   ${ANTHROPIC_DEFAULT_OPUS_MODEL:-global.anthropic.claude-opus-4-8}[1m]"
  echo "  Fable:  ${ANTHROPIC_DEFAULT_FABLE_MODEL:-anthropic.claude-fable-5}  (1M context by default, no [1m] suffix needed)"
  echo ""
  echo "Persistent default (set with 'claude default <model>'):"
  echo "  ${WRAPPER_DEFAULT_MODEL:-haiku}"
  echo ""

  # Show Foundry configuration section
  if [[ "${CLAUDE_CODE_USE_FOUNDRY:-0}" == "1" && -n "$ANTHROPIC_FOUNDRY_BASE_URL" && -n "$ANTHROPIC_FOUNDRY_API_KEY" ]]; then
    echo "Foundry Configuration (active via CLAUDE_CODE_USE_FOUNDRY=1):"
    echo ""
    echo "  Base URL: $ANTHROPIC_FOUNDRY_BASE_URL"
    echo "  Haiku:    ${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku-4-5}"
    echo "  Sonnet:   ${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet-4-6}"
    echo "  Opus:     ${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-4-8}"
    echo "  Fable:    ${ANTHROPIC_DEFAULT_FABLE_MODEL:-claude-fable-5}"
    echo ""
  elif [[ "${CLAUDE_CODE_USE_FOUNDRY:-0}" == "1" ]]; then
    echo "Foundry Configuration (CLAUDE_CODE_USE_FOUNDRY=1 set but incomplete):"
    echo ""
    [[ -z "$ANTHROPIC_FOUNDRY_BASE_URL" ]] && echo "  Missing: ANTHROPIC_FOUNDRY_BASE_URL"
    [[ -z "$ANTHROPIC_FOUNDRY_API_KEY" ]]  && echo "  Missing: ANTHROPIC_FOUNDRY_API_KEY"
    echo ""
  fi

  # Always show local LLM configuration section
  if [[ -n "$LOCAL_ANTHROPIC_BASE_URL" ]]; then
    echo "Local LLM Configuration (use 'claude --local'):"
    echo ""
    echo "  Base URL: $LOCAL_ANTHROPIC_BASE_URL"
    echo "  Haiku:    ${LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-flash}"
    echo "  Sonnet:   ${LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL:-deepseek-flash}"
    echo "  Opus:     ${LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL:-deepseek-flash}"
    echo "  Fable:    ${LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL:-deepseek-flash}"
    echo ""
  else
    echo "Local LLM Configuration (not configured):"
    echo ""
    echo "  Set LOCAL_ANTHROPIC_BASE_URL to activate local models"
    echo "  Example: export LOCAL_ANTHROPIC_BASE_URL=\"http://llm.example.com/v1\""
    echo ""
    echo "  Default models (deepseek-flash) can be overridden with:"
    echo "    LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL"
    echo "    LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL"
    echo "    LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL"
    echo "    LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL"
    echo ""
  fi

  exit 0
fi

# Set persistent defaults (model, yolo)
if [[ "$1" == "default" ]]; then
  _valid_models="haiku sonnet opus fable sonnet-1m opus-1m fable-1m"
  _chosen="${2:-}"
  if [[ -z "$_chosen" ]]; then
    echo -e "${YELLOW}Current default model: ${WRAPPER_DEFAULT_MODEL:-haiku}${NC}" >&2
    echo -e "${YELLOW}Yolo mode (skip permissions): ${WRAPPER_YOLO:-0}${NC}" >&2
    echo "" >&2
    echo "Usage: claude default <model|yolo|noyolo>" >&2
    echo "Valid models: $_valid_models" >&2
    exit 0
  fi
  case "$_chosen" in
    haiku|sonnet|opus|fable|sonnet-1m|opus-1m|fable-1m)
      _set_wrapper_env WRAPPER_DEFAULT_MODEL "$_chosen"
      echo -e "${GREEN}✓${NC} Default model set to '$_chosen' in ~/.claude/claude-wrapper.env" >&2
      exit 0
      ;;
    yolo)
      _set_wrapper_env WRAPPER_YOLO "1"
      echo -e "${GREEN}✓${NC} Yolo mode enabled (WRAPPER_YOLO=1) in ~/.claude/claude-wrapper.env" >&2
      exit 0
      ;;
    noyolo)
      _set_wrapper_env WRAPPER_YOLO "0"
      echo -e "${GREEN}✓${NC} Yolo mode disabled (WRAPPER_YOLO=0) in ~/.claude/claude-wrapper.env" >&2
      exit 0
      ;;
    *)
      echo -e "${RED}✗ Unknown option '$_chosen'${NC}" >&2
      echo "Valid models: $_valid_models" >&2
      echo "Other options: yolo, noyolo" >&2
      exit 1
      ;;
  esac
fi

# Check if update/upgrade is requested
if [[ "$1" == "update" || "$1" == "upgrade" ]]; then
  echo -e "${YELLOW}Updating claude-wrapper...${NC}" >&2

  # Checksum before download
  MD5_BEFORE=$(_file_md5 "$WRAPPER_PATH")

  # Download new wrapper to temp file
  TEMP_WRAPPER=$(mktemp)
  if curl -fsSL -o "$TEMP_WRAPPER" "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh?`date +%s`"; then
    MD5_AFTER=$(_file_md5 "$TEMP_WRAPPER")
    # Replace the installed wrapper
    _new_ver=$(grep '^WRAPPER_VERSION=' "$TEMP_WRAPPER" 2>/dev/null | head -1 | cut -d'"' -f2)
    if mv "$TEMP_WRAPPER" "$WRAPPER_PATH" && chmod +x "$WRAPPER_PATH"; then
      if [[ "$MD5_BEFORE" != "$MD5_AFTER" ]]; then
        echo -e "${GREEN}✓${NC} Wrapper updated successfully (now v${_new_ver:-unknown})" >&2
      else
        echo -e "${GREEN}✓${NC} Wrapper already up to date (v${_new_ver:-$WRAPPER_VERSION})" >&2
      fi
      echo "" >&2
    else
      echo -e "${RED}✗ Failed to replace wrapper${NC}" >&2
      rm -f "$TEMP_WRAPPER"
    fi
  else
    echo -e "${RED}✗ Failed to download wrapper${NC}" >&2
    rm -f "$TEMP_WRAPPER"
  fi

  # Now update Claude Code itself
  echo -e "${YELLOW}Updating Claude Code...${NC}" >&2
  _set_wrapper_env WRAPPER_LAST_UPDATE "$(date +%s)"
  exec "$REAL_CLAUDE" update
fi

# Auto-update if it has been more than 7 days since last update
_now=$(date +%s)
_last="${WRAPPER_LAST_UPDATE:-0}"
if (( _now - _last > 604800 )); then
  echo -e "${YELLOW}Auto-updating claude-wrapper (last update was >7 days ago)...${NC}" >&2
  TEMP_WRAPPER=$(mktemp)
  MD5_BEFORE=$(_file_md5 "$WRAPPER_PATH")
  if curl -fsSL -o "$TEMP_WRAPPER" "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh?`date +%s`"; then
    MD5_AFTER=$(_file_md5 "$TEMP_WRAPPER")
    _new_ver=$(grep '^WRAPPER_VERSION=' "$TEMP_WRAPPER" 2>/dev/null | head -1 | cut -d'"' -f2)
    if mv "$TEMP_WRAPPER" "$WRAPPER_PATH" && chmod +x "$WRAPPER_PATH"; then
      if [[ "$MD5_BEFORE" != "$MD5_AFTER" ]]; then
        echo -e "${GREEN}✓${NC} Wrapper updated (now v${_new_ver:-unknown})" >&2
      else
        echo -e "${GREEN}✓${NC} Wrapper already up to date (v${_new_ver:-$WRAPPER_VERSION})" >&2
      fi
    else
      echo -e "${RED}✗ Failed to replace wrapper${NC}" >&2
      rm -f "$TEMP_WRAPPER"
    fi
  else
    echo -e "${YELLOW}⚠ Auto-update skipped (no network?)${NC}" >&2
    rm -f "$TEMP_WRAPPER"
  fi
  _set_wrapper_env WRAPPER_LAST_UPDATE "$(date +%s)"
fi

# Check if --local flag is used
if [[ "$1" == "--local" ]]; then
  shift  # Remove --local from arguments

  # Check if LOCAL_ANTHROPIC_BASE_URL is set
  if [[ -z "$LOCAL_ANTHROPIC_BASE_URL" ]]; then
    echo -e "${RED}✗ Error: --local flag used but LOCAL_ANTHROPIC_BASE_URL is not set${NC}" >&2
    echo "" >&2
    echo "To use --local, set the LOCAL_ANTHROPIC_BASE_URL environment variable:" >&2
    echo "  export LOCAL_ANTHROPIC_BASE_URL=\"http://llm.dev-ai.university.edu/cc/v1\"" >&2
    echo "" >&2
    echo "Optionally, also set local model names:" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL=\"deepseek-flash\"" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL=\"deepseek-flash\"" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL=\"deepseek-flash\"" >&2
    echo "  export LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL=\"deepseek-flash\"" >&2
    exit 1
  fi

  # Set ANTHROPIC_BASE_URL from LOCAL_ANTHROPIC_BASE_URL
  export ANTHROPIC_BASE_URL="$LOCAL_ANTHROPIC_BASE_URL"
  export ANTHROPIC_API_KEY="sk-ant-dummy"

  # Apply local model names, defaulting to deepseek-flash so the runtime models
  # match what 'claude --models' advertises (otherwise the later Model
  # Configuration block would fill in Bedrock-prefixed IDs for a local endpoint).
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL:-deepseek-flash}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL:-deepseek-flash}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL:-deepseek-flash}"
  export ANTHROPIC_DEFAULT_FABLE_MODEL="${LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL:-deepseek-flash}"
  USING_LOCAL=1
  # Local LLM endpoint — make sure neither cloud backend is active.
  export CLAUDE_CODE_USE_BEDROCK=0
  export CLAUDE_CODE_USE_FOUNDRY=0

  # Offer to persist settings to claude-wrapper.env
  if { [[ ! -f "$ENV_FILE" ]] || ! grep -q "^LOCAL_ANTHROPIC_BASE_URL=" "$ENV_FILE" 2>/dev/null; } && [[ -t 0 ]]; then
    echo "" >&2
    echo -e "${YELLOW}Local LLM vars are set but not yet saved to ~/.claude/claude-wrapper.env.${NC}" >&2
    read -p "Save these settings for future sessions? (Y/n): " _save_local
    if [[ -z "$_save_local" || "$_save_local" == "y" || "$_save_local" == "Y" ]]; then
      mkdir -p "$HOME/.claude"
      # Write to claude-wrapper.env (primary)
      _set_wrapper_env LOCAL_ANTHROPIC_BASE_URL "$LOCAL_ANTHROPIC_BASE_URL"
      [[ -n "$LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL" ]]  && _set_wrapper_env LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL  "$LOCAL_ANTHROPIC_DEFAULT_HAIKU_MODEL"
      [[ -n "$LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL" ]] && _set_wrapper_env LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL "$LOCAL_ANTHROPIC_DEFAULT_SONNET_MODEL"
      [[ -n "$LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL" ]]   && _set_wrapper_env LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL   "$LOCAL_ANTHROPIC_DEFAULT_OPUS_MODEL"
      [[ -n "$LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL" ]]  && _set_wrapper_env LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL  "$LOCAL_ANTHROPIC_DEFAULT_FABLE_MODEL"
      echo -e "${GREEN}✓${NC} Saved to ~/.claude/claude-wrapper.env" >&2
    fi
    echo "" >&2
  fi

# Check if ANTHROPIC_BASE_URL is already set (for local LLM usage without --local flag)
elif [[ -n "$ANTHROPIC_BASE_URL" ]]; then
  # Custom endpoint — neither cloud backend should be active.
  export CLAUDE_CODE_USE_BEDROCK=0
  export CLAUDE_CODE_USE_FOUNDRY=0
  # Set ANTHROPIC_API_KEY to dummy value if not set or invalid
  if [[ -z "$ANTHROPIC_API_KEY" ]] || [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
    export ANTHROPIC_API_KEY="sk-ant-dummy"
  fi

# Foundry Configuration - use Azure AI Foundry if CLAUDE_CODE_USE_FOUNDRY=1
elif [[ "${CLAUDE_CODE_USE_FOUNDRY:-0}" == "1" ]]; then
  if [[ -z "$ANTHROPIC_FOUNDRY_BASE_URL" || -z "$ANTHROPIC_FOUNDRY_API_KEY" ]]; then
    echo -e "${RED}✗ Error: CLAUDE_CODE_USE_FOUNDRY=1 but required variables are not set${NC}" >&2
    echo "" >&2
    echo "Both of these must be set in your ~/.profile (or ~/.bashrc / ~/.zshrc):" >&2
    echo "" >&2
    echo "  export ANTHROPIC_FOUNDRY_BASE_URL=\"https://<your-endpoint>.openai.azure.com/...\"" >&2
    echo "  export ANTHROPIC_FOUNDRY_API_KEY=\"<your-foundry-api-key>\"" >&2
    echo "" >&2
    [[ -z "$ANTHROPIC_FOUNDRY_BASE_URL" ]] && echo "  Missing: ANTHROPIC_FOUNDRY_BASE_URL" >&2
    [[ -z "$ANTHROPIC_FOUNDRY_API_KEY" ]]  && echo "  Missing: ANTHROPIC_FOUNDRY_API_KEY" >&2
    echo "" >&2
    exit 1
  fi
  export ANTHROPIC_BASE_URL="$ANTHROPIC_FOUNDRY_BASE_URL"
  export ANTHROPIC_API_KEY="sk-ant-dummy"
  # Foundry endpoint — Bedrock must not be active.
  export CLAUDE_CODE_USE_BEDROCK=0
  USING_FOUNDRY=1

  # Offer to persist settings to ~/.azure/clauderc if it doesn't exist yet
  if [[ ! -f "$HOME/.azure/clauderc" ]] && [[ -t 0 ]]; then
    echo "" >&2
    echo -e "${YELLOW}Azure Foundry vars are set but ~/.azure/clauderc does not exist.${NC}" >&2
    read -p "Save these settings to ~/.azure/clauderc for future sessions? (Y/n): " _save_confirm
    if [[ -z "$_save_confirm" || "$_save_confirm" == "y" || "$_save_confirm" == "Y" ]]; then
      mkdir -p "$HOME/.azure"
      cat > "$HOME/.azure/clauderc" <<EOF
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_BASE_URL="$ANTHROPIC_FOUNDRY_BASE_URL"
export ANTHROPIC_FOUNDRY_API_KEY="$ANTHROPIC_FOUNDRY_API_KEY"
EOF
      echo -e "${GREEN}✓${NC} Saved to ~/.azure/clauderc" >&2
    fi
    echo "" >&2
  fi

# Default: AWS Bedrock Configuration - only enable if a 'bedrock' profile exists.
# Match the section header precisely ([profile bedrock] or [bedrock]) rather than
# a bare substring, so unrelated text (comments, regions, other profiles) does not
# accidentally trigger Bedrock mode.
elif grep -Eq '^\[(profile[[:space:]]+)?bedrock\]' "$HOME/.aws/config" 2>/dev/null; then
  export CLAUDE_CODE_USE_BEDROCK=1
  export CLAUDE_CODE_USE_FOUNDRY=0
  export AWS_DEFAULT_REGION=us-west-2
  export AWS_PROFILE=bedrock

# No valid configuration found
else
  echo -e "${RED}✗ Error: No valid configuration found${NC}" >&2
  echo "" >&2
  echo "Options to fix this:" >&2
  echo "" >&2
  echo "1. Use Azure AI Foundry — paste these exports into your shell (or add to ~/.bashrc):" >&2
  echo "   export CLAUDE_CODE_USE_FOUNDRY=1" >&2
  echo "   export ANTHROPIC_FOUNDRY_BASE_URL=https://xxxxxxxxxxxxx.azure-api.net/anthropic" >&2
  echo "   export ANTHROPIC_FOUNDRY_API_KEY=xxxxxxxxxxxxxxxxxx" >&2
  echo "" >&2
  echo "2. Configure AWS Bedrock — get AWS creds and run:" >&2
  echo "   aws configure --profile bedrock" >&2
  echo "" >&2
  echo "3. Use --local flag with a local LLM endpoint:" >&2
  echo "   claude --local" >&2
  echo "" >&2
  echo "4. Bypass this wrapper and run Claude Code directly:" >&2
  echo "   ~/.local/bin/claude" >&2
  exit 1
fi

# Model Configuration — Foundry uses plain model names; Bedrock uses prefixed IDs
if [[ "${USING_FOUNDRY:-0}" == "1" ]]; then
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-claude-sonnet-4-6}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-claude-haiku-4-5}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-claude-opus-4-8}"
  export ANTHROPIC_DEFAULT_FABLE_MODEL="${ANTHROPIC_DEFAULT_FABLE_MODEL:-claude-fable-5}"
else
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL:-us.anthropic.claude-haiku-4-5-20251001-v1:0}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${ANTHROPIC_DEFAULT_SONNET_MODEL:-global.anthropic.claude-sonnet-4-6}"
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${ANTHROPIC_DEFAULT_OPUS_MODEL:-global.anthropic.claude-opus-4-8}"
  export ANTHROPIC_DEFAULT_FABLE_MODEL="${ANTHROPIC_DEFAULT_FABLE_MODEL:-anthropic.claude-fable-5}"
fi
export ANTHROPIC_SMALL_FAST_MODEL="${ANTHROPIC_DEFAULT_HAIKU_MODEL}"

# Default model — haiku unless overridden by 'claude default <model>'
model_name="${WRAPPER_DEFAULT_MODEL:-haiku}"
case "$model_name" in
  fable-1m)  mymodel="${ANTHROPIC_DEFAULT_FABLE_MODEL}" ;;
  fable)     mymodel="${ANTHROPIC_DEFAULT_FABLE_MODEL}" ;;
  opus-1m)   mymodel="${ANTHROPIC_DEFAULT_OPUS_MODEL}[1m]" ;;
  opus)      mymodel="${ANTHROPIC_DEFAULT_OPUS_MODEL}" ;;
  sonnet-1m) mymodel="${ANTHROPIC_DEFAULT_SONNET_MODEL}[1m]" ;;
  sonnet)    mymodel="${ANTHROPIC_DEFAULT_SONNET_MODEL}" ;;
  *)         mymodel="${ANTHROPIC_DEFAULT_HAIKU_MODEL}" ; model_name="haiku" ;;
esac

# Scan all arguments for model selection (allows e.g. "claude -c opus").
# Trade-off: a bare arg equal to a model keyword (opus/sonnet/haiku/-1m) is
# consumed as a model selector and not forwarded to Claude Code. This is
# intentional so the keyword works anywhere in the arg list.
wdebug=0
new_args=()
for arg in "$@"; do
  case "$arg" in
    fable-1m)
      mymodel="${ANTHROPIC_DEFAULT_FABLE_MODEL}"
      model_name="fable-1m"
      ;;
    fable)
      mymodel="${ANTHROPIC_DEFAULT_FABLE_MODEL}"
      model_name="fable"
      ;;
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
    --wdebug)
      wdebug=1
      ;;
    *)
      new_args+=("$arg")
      ;;
  esac
done
set -- "${new_args[@]}"

export ANTHROPIC_MODEL="$mymodel"

# Show status message for Foundry / local / custom base URL
if [[ "${USING_FOUNDRY:-0}" == "1" ]]; then
  _msg="Foundry Model: $mymodel, URL: $ANTHROPIC_BASE_URL"
  [[ "$CLAUDERC_LOADED" == "1" ]] && _msg="Reading ~/.azure/clauderc, $_msg"
  echo -e "${GREEN}${_msg}${NC}" >&2
elif [[ "${USING_LOCAL:-0}" == "1" ]]; then
  _msg="Local Model: $mymodel, URL: $ANTHROPIC_BASE_URL"
  [[ "$ENV_FILE_LOADED" == "1" ]] && _msg="Reading ~/.claude/claude-wrapper.env, $_msg"
  echo -e "${GREEN}${_msg}${NC}" >&2
elif [[ -n "$ANTHROPIC_BASE_URL" ]]; then
  echo -e "${GREEN}Local Model: $mymodel, URL: $ANTHROPIC_BASE_URL${NC}" >&2
fi

# Show debug info if --wdebug was requested
if [[ "$wdebug" -eq 1 ]]; then
  echo -e "${YELLOW}=== claude-wrapper debug ===${NC}" >&2
  echo "" >&2
  echo "Environment variables set by wrapper:" >&2
  for var in ANTHROPIC_MODEL ANTHROPIC_BASE_URL ANTHROPIC_API_KEY \
             ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
             ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_FABLE_MODEL \
             ANTHROPIC_SMALL_FAST_MODEL \
             CLAUDE_CODE_USE_FOUNDRY ANTHROPIC_FOUNDRY_BASE_URL \
             CLAUDE_CODE_USE_BEDROCK AWS_DEFAULT_REGION AWS_PROFILE; do
    if [[ -n "${!var+x}" ]]; then
      echo "  $var=${!var}" >&2
    fi
  done
  echo "" >&2
  if [[ "${WRAPPER_YOLO:-0}" == "1" ]]; then
    echo "Command: $REAL_CLAUDE --model $mymodel --dangerously-skip-permissions $*" >&2
  else
    echo "Command: $REAL_CLAUDE --model $mymodel --allowedTools <list> --disallowedTools <list> $*" >&2
  fi
  echo "" >&2
fi

# Block running Claude Code directly in the home directory
if [[ "$PWD" == "$HOME" ]]; then
  echo -e "${RED}✗ Error: Do not run Claude Code directly in your home directory${NC}" >&2
  echo "" >&2
  echo "Please create a project folder first, for example:" >&2
  echo "" >&2
  echo "  mkdir ~/myproject && cd ~/myproject && git init" >&2
  echo "" >&2
  exit 1
fi

# Check if current directory is inside a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${YELLOW}⚠ Recommendation: Running Claude Code inside a git repository is highly recommended.${NC}" >&2
  echo "" >&2
  echo "To set one up, run one of these before starting Claude:" >&2
  echo "" >&2
  echo "  1. Clone an existing repository from GitHub:" >&2
  echo "     git clone https://github.com/username/repo-name && cd repo-name" >&2
  echo "" >&2
  echo "  2. Initialize a new local git repository:" >&2
  echo "     git init" >&2
  echo "" >&2
fi

# Allowed/disallowed tools for non-yolo mode
ALLOWED_TOOLS=(
  "Read" "Edit" "WebFetch" "Agent"
  "Bash(ls *)" "Bash(cat *)" "Bash(head *)" "Bash(tail *)" "Bash(less *)"
  "Bash(find *)" "Bash(tree *)" "Bash(file *)" "Bash(stat *)" "Bash(wc *)"
  "Bash(du *)" "Bash(df *)" "Bash(grep *)" "Bash(awk *)" "Bash(sed *)"
  "Bash(sort *)" "Bash(uniq *)" "Bash(cut *)" "Bash(tr *)" "Bash(diff *)"
  "Bash(jq *)" "Bash(yq *)" "Bash(xargs *)" "Bash(tee *)"
  "Bash(cp *)" "Bash(mv *)" "Bash(mkdir *)" "Bash(touch *)" "Bash(chmod *)"
  "Bash(chown *)" "Bash(ln *)" "Bash(tar *)" "Bash(zip *)" "Bash(unzip *)"
  "Bash(gzip *)" "Bash(gunzip *)"
  "Bash(curl *)" "Bash(wget *)" "Bash(ping *)" "Bash(dig *)"
  "Bash(nslookup *)" "Bash(host *)" "Bash(ss *)" "Bash(netstat *)"
  "Bash(ip *)" "Bash(ifconfig *)" "Bash(traceroute *)" "Bash(nmap *)"
  "Bash(ssh *)" "Bash(scp *)" "Bash(rsync *)"
  "Bash(ps *)" "Bash(top *)" "Bash(htop *)" "Bash(kill *)" "Bash(killall *)"
  "Bash(uptime *)" "Bash(free *)" "Bash(uname *)" "Bash(hostname *)"
  "Bash(whoami *)" "Bash(id *)" "Bash(w *)" "Bash(who *)" "Bash(lsof *)"
  "Bash(strace *)" "Bash(systemctl *)" "Bash(journalctl *)" "Bash(service *)"
  "Bash(apt *)" "Bash(apt-get *)" "Bash(yum *)" "Bash(dnf *)" "Bash(brew *)"
  "Bash(snap *)" "Bash(pip *)" "Bash(pip3 *)" "Bash(npm *)" "Bash(npx *)"
  "Bash(docker *)" "Bash(docker-compose *)" "Bash(kubectl *)" "Bash(helm *)"
  "Bash(terraform *)" "Bash(ansible *)"
  "Bash(aws *)" "Bash(az *)" "Bash(gcloud *)" "Bash(git *)" "Bash(gh *)"
  "Bash(appmo *)"
  "Bash(python *)" "Bash(python3 *)" "Bash(node *)"
  "Bash(bash *)" "Bash(sh *)" "Bash(env *)" "Bash(export *)"
  "Bash(echo *)" "Bash(printf *)" "Bash(date *)"
  "Bash(cron *)" "Bash(crontab *)"
  "Bash(mount *)" "Bash(umount *)" "Bash(fdisk *)" "Bash(lsblk *)" "Bash(blkid *)"
  "Bash(openssl *)" "Bash(ssh-keygen *)" "Bash(iptables *)" "Bash(ufw *)"
  "Bash(sudo *)"
  "Bash(* --version)" "Bash(* --help)" "Bash(* --help *)"
  "Bash(which *)" "Bash(type *)" "Bash(man *)"
)
DISALLOWED_TOOLS=(
  "Bash(rm -rf /)"
  "Bash(rm -rf /*)"
  "Bash(mkfs *)"
  "Bash(dd *)"
  "Bash(:(){ :|:& };:)"
)

# Execute Claude Code (skip permissions if WRAPPER_YOLO=1)
if [[ "${WRAPPER_YOLO:-0}" == "1" ]]; then
  exec "$REAL_CLAUDE" --model "$mymodel" --dangerously-skip-permissions "$@"
else
  exec "$REAL_CLAUDE" --model "$mymodel" \
    --allowedTools "${ALLOWED_TOOLS[@]}" \
    --disallowedTools "${DISALLOWED_TOOLS[@]}" \
    "$@"
fi
