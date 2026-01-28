#!/bin/bash
# shell-setup.sh
# Comprehensive shell and SSH setup script for development environments
# Works on both Linux and macOS

# Check if running in bash, if not, automatically run with bash
if [ -z "$BASH_VERSION" ]; then
  if command -v bash >/dev/null 2>&1; then
    # When sourced in sh, $0 might be "-sh" or similar
    # We need to figure out the actual script path
    # This is tricky in POSIX sh, so we'll try a few approaches
    SCRIPT_PATH=""

    # Try to use the first argument if it looks like a path
    if [ -n "$1" ] && [ -f "$1" ]; then
      SCRIPT_PATH="$1"
    elif [ -f "$0" ]; then
      SCRIPT_PATH="$0"
    else
      # Last resort: search for the script in common locations
      for path in \
        "/home/dp/gh/docs/scripts/shell-setup.sh" \
        "$HOME/gh/docs/scripts/shell-setup.sh" \
        "$(pwd)/shell-setup.sh"
      do
        if [ -f "$path" ]; then
          SCRIPT_PATH="$path"
          break
        fi
      done
    fi

    if [ -n "$SCRIPT_PATH" ]; then
      echo "Switching to bash to run this script..."
      bash "$SCRIPT_PATH" "$@"
      return $? 2>/dev/null || exit $?
    else
      echo "Error: Cannot determine script path. Please run directly with bash:"
      echo "  bash /path/to/shell-setup.sh"
      return 1 2>/dev/null || exit 1
    fi
  else
    echo "Error: This script requires bash, but bash is not found in PATH"
    return 1 2>/dev/null || exit 1
  fi
fi

# Detect if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  SCRIPT_MODE="execute"
  # Note: Not using set -e as it causes premature exits with grep/sed/awk
  # Each function handles its own error checking
else
  SCRIPT_MODE="source"
fi

# Function to exit/return appropriately
script_exit() {
  local code="${1:-0}"
  if [[ "$SCRIPT_MODE" == "source" ]]; then
    return "$code"
  else
    exit "$code"
  fi
}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log file for tracking changes
LOG_FILE="$HOME/.local/state/shell-setup/shell-setup.log"
mkdir -p "$HOME/.local/state/shell-setup"

# Function to log changes
log_change() {
  local action="$1"
  local details="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $action: $details" >> "$LOG_FILE"
}

# Function to revert changes
revert_changes() {
  # Temporarily disable set -e for revert function
  # (arithmetic operations like ((skipped++)) can return 0 and exit with set -e)
  local old_opts=$-
  set +e

  if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}No log file found at $LOG_FILE${NC}"
    echo "Nothing to revert."
    [[ $old_opts == *e* ]] && set -e
    script_exit 1
  fi

  echo -e "${YELLOW}=== Reverting shell-setup.sh changes ===${NC}\n"
  echo -e "${RED}WARNING: This will attempt to undo all changes made by shell-setup.sh${NC}"
  echo -e "${YELLOW}Log file: $LOG_FILE${NC}"

  # Show summary of what's in the log
  local total_entries=$(grep -c "^\[" "$LOG_FILE" 2>/dev/null || echo 0)
  local bashrc_entries=$(grep -c ".bashrc" "$LOG_FILE" 2>/dev/null || echo 0)
  local profile_entries=$(grep -c ".profile\|.zprofile\|.bash_profile" "$LOG_FILE" 2>/dev/null || echo 0)

  echo "  Total logged changes: $total_entries"
  echo "  .bashrc changed lines: $bashrc_entries"
  echo "  Profile changed lines: $profile_entries"
  echo ""

  read -p "Are you sure you want to revert? (yes/N): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Revert cancelled."
    script_exit 0
  fi

  local reverted=0
  local failed=0
  local skipped=0

  # Arrays to track what was done
  declare -a reverted_items
  declare -a failed_items
  declare -a skipped_items

  # Process log file in reverse order
  while IFS= read -r line; do
    if [[ "$line" =~ \[.*\][[:space:]](.*):[[:space:]](.*) ]]; then
      local action="${BASH_REMATCH[1]}"
      local details="${BASH_REMATCH[2]}"

      case "$action" in
        "ADDED_TO_FILE")
          local file=$(echo "$details" | cut -d'|' -f1)
          local content=$(echo "$details" | cut -d'|' -f2-)

          if [[ -f "$file" ]]; then
            # Check if the content exists in the file
            if grep -Fq "$content" "$file"; then
              # Remove the added line
              if grep -Fv "$content" "$file" > "$file.tmp" && mv "$file.tmp" "$file"; then
                echo -e "${GREEN}✓${NC} Removed line from $file"
                reverted_items+=("$file")
                ((reverted++))
              else
                echo -e "${RED}✗${NC} Failed to remove line from $file"
                failed_items+=("$file")
                ((failed++))
              fi
            else
              # Debug: show what we're looking for if it's a .bashrc or profile file
              if [[ "$file" == *".bashrc"* ]] || [[ "$file" == *".profile"* ]] || [[ "$file" == *".zprofile"* ]]; then
                echo -e "${YELLOW}⊘${NC} Line not found in $file"
                echo -e "${YELLOW}   Looking for: ${content:0:70}${NC}"
                ((skipped++))
                skipped_items+=("$file (not found - check manually)")
              else
                echo -e "${YELLOW}⊘${NC} Line already removed from $file"
                skipped_items+=("$file (already removed)")
                ((skipped++))
              fi
            fi
          else
            echo -e "${YELLOW}⊘${NC} File $file not found"
            skipped_items+=("$file (not found)")
            ((skipped++))
          fi
          ;;
        "CREATED_FILE")
          local file="$details"
          if [[ -f "$file" ]]; then
            rm -f "$file"
            echo -e "${GREEN}✓${NC} Removed file $file"
            reverted_items+=("Removed file $file")
            ((reverted++))
          else
            echo -e "${YELLOW}⊘${NC} File $file not found"
            skipped_items+=("File $file not found")
            ((skipped++))
          fi
          ;;
        "CREATED_DIR")
          # Skip directory removal - directories created should not be deleted
          # as they may contain user files or be in use
          local dir="$details"
          echo -e "${YELLOW}⊘${NC} Skipped directory removal: $dir (may contain user files)"
          skipped_items+=("Skipped directory $dir")
          ((skipped++))
          ;;
        "GIT_CONFIG")
          # Check if Git is installed before attempting to revert Git config
          if ! command -v git &> /dev/null; then
            echo -e "${YELLOW}⊘${NC} Git not installed, skipping Git config revert"
            skipped_items+=("Git config (Git not installed)")
            ((skipped++))
            continue
          fi

          local config=$(echo "$details" | cut -d'=' -f1)
          local old_value=$(echo "$details" | cut -d'=' -f2-)
          if [[ "$old_value" == "UNSET" ]]; then
            if git config --global --unset "$config" 2>/dev/null; then
              echo -e "${GREEN}✓${NC} Unset git config $config"
              reverted_items+=("Unset git config $config")
              ((reverted++))
            else
              echo -e "${YELLOW}⊘${NC} Config $config already unset"
              skipped_items+=("Config $config already unset")
              ((skipped++))
            fi
          else
            if git config --global "$config" "$old_value"; then
              echo -e "${GREEN}✓${NC} Restored git config $config"
              reverted_items+=("Restored git config $config=$old_value")
              ((reverted++))
            else
              echo -e "${RED}✗${NC} Failed to restore git config $config"
              failed_items+=("Failed to restore git config $config")
              ((failed++))
            fi
          fi
          ;;
        "SSH_KEY_CREATED")
          local key_file="$details"
          if [[ -f "$key_file" ]]; then
            echo -e "${YELLOW}Found SSH key: $key_file${NC}"
            read -p "Delete this SSH key? (yes/N): " delete_key
            if [[ "$delete_key" == "yes" ]]; then
              rm -f "$key_file" "${key_file}.pub"
              echo -e "${GREEN}✓${NC} Removed SSH key"
              reverted_items+=("Removed SSH key $key_file")
              ((reverted++))
            else
              echo -e "${YELLOW}⊘${NC} Skipped SSH key removal (user choice)"
              skipped_items+=("Skipped SSH key $key_file (user choice)")
              ((skipped++))
            fi
          else
            echo -e "${YELLOW}⊘${NC} SSH key $key_file not found"
            skipped_items+=("SSH key $key_file not found")
            ((skipped++))
          fi
          ;;
        "GPG_KEY_CREATED")
          local key_id="$details"
          echo -e "${YELLOW}Found GPG key: $key_id${NC}"
          read -p "Delete this GPG key? (yes/N): " delete_gpg
          if [[ "$delete_gpg" == "yes" ]]; then
            if gpg --batch --yes --delete-secret-keys "$key_id" 2>/dev/null && \
               gpg --batch --yes --delete-keys "$key_id" 2>/dev/null; then
              echo -e "${GREEN}✓${NC} Removed GPG key"
              reverted_items+=("Removed GPG key $key_id")
              ((reverted++))
            else
              echo -e "${RED}✗${NC} Failed to remove GPG key"
              failed_items+=("Failed to remove GPG key $key_id")
              ((failed++))
            fi
          else
            echo -e "${YELLOW}⊘${NC} Skipped GPG key removal (user choice)"
            skipped_items+=("Skipped GPG key $key_id (user choice)")
            ((skipped++))
          fi
          ;;
      esac
    fi
  done < <(tac "$LOG_FILE")

  echo ""
  echo -e "${GREEN}=== Revert Summary ===${NC}\n"

  # Show detailed summary
  echo -e "${GREEN}Successfully Reverted ($reverted):${NC}"
  if [[ ${#reverted_items[@]} -gt 0 ]]; then
    for item in "${reverted_items[@]}"; do
      echo -e "  ${GREEN}✓${NC} $item"
    done
  else
    echo "  (none)"
  fi
  echo ""

  if [[ $skipped -gt 0 ]]; then
    echo -e "${YELLOW}Skipped ($skipped):${NC}"
    for item in "${skipped_items[@]}"; do
      echo -e "  ${YELLOW}⊘${NC} $item"
    done
    echo ""
  fi

  if [[ $failed -gt 0 ]]; then
    echo -e "${RED}Failed ($failed):${NC}"
    for item in "${failed_items[@]}"; do
      echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
  fi

  # Archive the log file
  local archive_name="$LOG_FILE.$(date +%Y%m%d_%H%M%S).reverted"
  mv "$LOG_FILE" "$archive_name"
  echo -e "Log file archived to: ${YELLOW}$archive_name${NC}"

  # Restore set -e if it was enabled
  [[ $old_opts == *e* ]] && set -e

  script_exit 0
}

# Function to show help
show_help() {
  cat << 'EOF'
shell-setup.sh - Comprehensive shell and SSH setup script

USAGE:
  ./shell-setup.sh [OPTIONS]

OPTIONS:
  (none)      Interactive setup mode (default)
              - Prompts before overwriting existing configurations
              - Skips steps that are already configured
              - Safe for repeated runs (idempotent)

  --light     Light mode - minimal automated setup
              - Sets up PATH directories and convenience settings
              - Configures Vim with desert theme and edr command
              - Only sets Git default branch to 'main' if not set
              - Skips SSH key, GPG key, Git user config, and SSH config setup
              - No prompts, fully automated
              - Use for: minimal shell configuration without credentials

  --force     Force mode - overwrites all settings
              - Backs up existing SSH keys to ~/.ssh/backup-TIMESTAMP/
              - Backs up existing GPG keys to ~/.gnupg/backup-TIMESTAMP/
              - Removes and recreates all configurations
              - No prompts, fully automated
              - Use for: fresh setups, fixing corrupted configs

  --revert    Revert all changes made by this script
              - Removes lines added to .bashrc and .profile
              - Restores previous Git configurations
              - Optionally removes SSH/GPG keys (with confirmation)
              - Skips directory removal (may contain user files)
              - Archives log file after reverting

  --help      Show this help message

WHAT IT SETS UP:
  1. PATH directories (~/.local/bin and ~/bin)
     - Ensures ~/bin comes BEFORE ~/.local/bin in PATH
     - Removes PATH blocks from .profile (belong in .bashrc for batch mode support)
     - Adds correct PATH configuration to .bashrc
  2. XDG_RUNTIME_DIR for container support (Linux only)
  3. Convenience settings (LS_COLORS cyan directories, history size)
  4. SSH key (ed25519 with mandatory passphrase)
  5. GPG key for Git commit signing (no passphrase)
  6. Keychain for SSH key management
  7. SSH config (optional, for jump hosts)
  8. Vim configuration (desert color scheme)
  9. Git global configuration
  10. Git commit signing with GPG

LOG FILE:
  All changes are logged to: ~/.local/state/shell-setup/shell-setup.log
  Use --revert to undo changes based on this log.

EXAMPLES:
  # First time setup (interactive)
  ./shell-setup.sh

  # Minimal setup without credentials (fully automated)
  ./shell-setup.sh --light

  # Force reconfiguration with backups
  ./shell-setup.sh --force

  # Undo all changes
  ./shell-setup.sh --revert

MORE INFORMATION:
  Repository: https://github.com/dirkpetersen/dok
  Documentation: https://dirkpetersen.github.io/dok

EOF
  script_exit 0
}

# Check for flags
FORCE_MODE=false
LIGHT_MODE=false
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  show_help
elif [[ "$1" == "--revert" ]]; then
  revert_changes
elif [[ "$1" == "--light" ]]; then
  LIGHT_MODE=true
  echo -e "${YELLOW}=== Light Mode Enabled ===${NC}"
  echo -e "${YELLOW}Minimal automated setup - no credential configuration${NC}\n"
elif [[ "$1" == "--force" ]]; then
  FORCE_MODE=true
  echo -e "${YELLOW}=== Force Mode Enabled ===${NC}"
  echo -e "${YELLOW}This will overwrite existing configurations${NC}"
  echo -e "${YELLOW}Existing SSH/GPG keys will be backed up${NC}\n"
fi

echo -e "${GREEN}=== Development Environment Setup ===${NC}\n"
echo -e "${YELLOW}Changes will be logged to: $LOG_FILE${NC}\n"

# Function to detect user's login shell
get_login_shell_rc() {
  local login_shell="${SHELL##*/}"
  case "$login_shell" in
    zsh)
      echo "$HOME/.zshrc"
      ;;
    bash)
      echo "$HOME/.bashrc"
      ;;
    *)
      echo "$HOME/.bashrc"
      ;;
  esac
}

# Function to detect login shell profile for keychain
get_login_profile() {
  local login_shell="${SHELL##*/}"
  case "$login_shell" in
    zsh)
      echo "$HOME/.zprofile"
      ;;
    bash)
      if [[ -f "$HOME/.bash_profile" ]]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.profile"
      fi
      ;;
    *)
      echo "$HOME/.profile"
      ;;
  esac
}

# Function to check PATH ordering
check_path_order() {
  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  local bin_home="$HOME/bin"
  local bin_local="$HOME/.local/bin"

  # Get position of each directory in current PATH
  local bin_home_pos=-1
  local bin_local_pos=-1
  local pos=0

  IFS=':' read -ra PATH_ARRAY <<< "$PATH"
  for dir in "${PATH_ARRAY[@]}"; do
    # Normalize path (resolve ~ and remove trailing slashes)
    local normalized_dir="${dir/#\~/$HOME}"
    normalized_dir="${normalized_dir%/}"

    if [[ "$normalized_dir" == "$bin_home" ]]; then
      bin_home_pos=$pos
    elif [[ "$normalized_dir" == "$bin_local" ]]; then
      bin_local_pos=$pos
    fi
    pos=$((pos + 1))
  done

  local result=2  # Default: one or both not in PATH

  # Check if both exist in PATH
  if [[ $bin_home_pos -ne -1 ]] && [[ $bin_local_pos -ne -1 ]]; then
    # Check if bin_home comes before bin_local
    if [[ $bin_home_pos -lt $bin_local_pos ]]; then
      result=0  # Correct order
    else
      result=1  # Wrong order
    fi
  fi

  # Restore set -e if it was enabled
  [[ $old_opts == *e* ]] && set -e
  return $result
}

# Function to remove RHEL9 default PATH block from .bashrc
remove_rhel_path_from_bashrc() {
  local old_opts=$-
  set +e

  local bashrc_file="$1"

  # Check if file has the RHEL9 default PATH block
  if grep -q 'if ! \[\[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" \]\]' "$bashrc_file" 2>/dev/null; then

    echo -e "${YELLOW}Found RHEL9 default PATH configuration in $bashrc_file - removing${NC}"

    # Create backup
    cp "$bashrc_file" "${bashrc_file}.bak.$(date +%Y%m%d_%H%M%S)"

    # Remove the RHEL9 PATH block using awk
    local temp_file="${bashrc_file}.tmp"

    awk '
      /^# User specific environment/ { skip=1; next }
      /^if ! \[\[ "\$PATH" =~ "\$HOME\/\.local\/bin:\$HOME\/bin:" \]\]/ { skip=1; next }
      skip && /^then$/ { next }
      skip && /^[[:space:]]*PATH=/ { next }
      skip && /^fi$/ { skip=0; next }
      skip && /^export PATH$/ { skip=0; next }
      /^export PATH$/ && !skip { next }
      !skip { print }
    ' "$bashrc_file" > "$temp_file"

    # Clean up multiple consecutive blank lines
    cat -s "$temp_file" > "${temp_file}.clean"
    mv "${temp_file}.clean" "$bashrc_file"
    rm -f "$temp_file"

    # Note: Not logging this removal as it can't be easily reverted

    echo -e "${GREEN}✓${NC} Removed RHEL9 PATH block from $bashrc_file"
  fi

  [[ $old_opts == *e* ]] && set -e
  return 0
}

# Function to remove PATH blocks from .profile (they belong in .bashrc)
remove_path_from_profile() {
  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  local profile_file="$1"

  # Check if file has the Ubuntu default PATH blocks (use -F for fixed string matching)
  if grep -Fq 'if [ -d "$HOME/bin" ]' "$profile_file" 2>/dev/null || \
     grep -Fq 'if [ -d "$HOME/.local/bin" ]' "$profile_file" 2>/dev/null; then

    echo -e "${YELLOW}Found PATH configuration in $profile_file - moving to .bashrc${NC}"

    # Create backup
    cp "$profile_file" "${profile_file}.bak.$(date +%Y%m%d_%H%M%S)"

    # Remove the PATH blocks using awk for multi-line pattern removal
    local temp_file="${profile_file}.tmp"

    awk '
      /^# set PATH so it includes user.*private bin/ { skip=1; next }
      /^if \[ -d "\$HOME\/bin" \]/ { skip=1; next }
      /^if \[ -d "\$HOME\/\.local\/bin" \]/ { skip=1; next }
      skip && /^[[:space:]]*PATH=/ { next }
      skip && /^[[:space:]]*fi$/ { skip=0; next }
      !skip { print }
    ' "$profile_file" > "$temp_file"

    # Clean up multiple consecutive blank lines
    cat -s "$temp_file" > "${temp_file}.clean"
    mv "${temp_file}.clean" "$profile_file"
    rm -f "$temp_file"

    # Note: Not logging this removal as it can't be easily reverted
    echo -e "${GREEN}✓${NC} Removed PATH blocks from $profile_file"
  fi

  # Restore set -e if it was enabled
  [[ $old_opts == *e* ]] && set -e
  return 0
}

# Function to ensure login profile sources .bashrc
# Interactive login shells read .profile/.bash_profile but not .bashrc by default
ensure_profile_sources_bashrc() {
  local old_opts=$-
  set +e

  local profile_file="$1"
  local shell_rc="$2"

  # Skip if not bash or if profile doesn't exist
  if [[ ! -f "$profile_file" ]]; then
    [[ $old_opts == *e* ]] && set -e
    return 0
  fi

  # Check if .bashrc is already being sourced (various patterns)
  # Patterns: . ~/.bashrc, source ~/.bashrc, . "$HOME/.bashrc", source "$HOME/.bashrc"
  # Also with single quotes or no quotes
  if grep -Eq '(\.|source)[[:space:]]+(~|"\$HOME"|'"'"'\$HOME'"'"'|\$HOME)/\.bashrc' "$profile_file" 2>/dev/null || \
     grep -Eq '(\.|source)[[:space:]]+"?~/\.bashrc"?' "$profile_file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Login profile already sources .bashrc"
    [[ $old_opts == *e* ]] && set -e
    return 0
  fi

  # Also check for the common Ubuntu pattern: if [ -f "$HOME/.bashrc" ]; then . "$HOME/.bashrc"
  if grep -q 'if.*-f.*\.bashrc' "$profile_file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Login profile already sources .bashrc"
    [[ $old_opts == *e* ]] && set -e
    return 0
  fi

  # .bashrc is not being sourced, add it
  echo -e "${YELLOW}Adding .bashrc sourcing to $profile_file${NC}"

  # Create backup
  cp "$profile_file" "${profile_file}.bak.$(date +%Y%m%d_%H%M%S)"

  # Extract first line (usually a comment like #!/bin/bash or # ~/.profile)
  local first_line=$(head -1 "$profile_file")
  local rest_of_file=$(tail -n +2 "$profile_file")

  # Create temp file with: first line + blank line + sourcing line + rest of file
  {
    echo "$first_line"
    echo ""
    echo "# Source .bashrc for interactive login shells (shell-setup.sh)"
    echo '[ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
    echo ""
    echo "$rest_of_file"
  } > "${profile_file}.tmp"

  mv "${profile_file}.tmp" "$profile_file"

  log_change "ADDED_TO_FILE" "$profile_file|# Source .bashrc for interactive login shells (shell-setup.sh)"
  log_change "ADDED_TO_FILE" "$profile_file|[ -n \"\$BASH_VERSION\" ] && [ -f \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\""
  echo -e "${GREEN}✓${NC} Added .bashrc sourcing to $profile_file"

  [[ $old_opts == *e* ]] && set -e
  return 0
}

# Function to add directories to beginning of PATH
add_to_begin_of_path() {
  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  local shell_rc=$(get_login_shell_rc)
  local profile=$(get_login_profile)
  local bin_home="$HOME/bin"
  local bin_local="$HOME/.local/bin"
  local created_any=false

  # Create directories if they don't exist
  if [[ ! -d "$bin_home" ]]; then
    mkdir -p "$bin_home"
    log_change "CREATED_DIR" "$bin_home"
    created_any=true
  fi

  if [[ ! -d "$bin_local" ]]; then
    mkdir -p "$bin_local"
    log_change "CREATED_DIR" "$bin_local"
    created_any=true
  fi

  if [[ "$created_any" == true ]]; then
    echo -e "${GREEN}✓${NC} Created directories: $bin_home and $bin_local"
  else
    echo -e "${GREEN}✓${NC} Directories already exist: $bin_home and $bin_local"
  fi

  # Check PATH ordering
  local order_status
  check_path_order
  order_status=$?

  if [[ $order_status -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} PATH order is correct: \$HOME/bin comes before \$HOME/.local/bin"
  elif [[ $order_status -eq 1 ]]; then
    echo -e "${YELLOW}⚠${NC}  PATH order issue: \$HOME/.local/bin comes before \$HOME/bin"
    echo -e "${YELLOW}   This will be fixed by the PATH configuration in .bashrc${NC}"
  else
    echo -e "${YELLOW}⚠${NC}  One or both directories not in PATH yet"
  fi

  # Remove PATH blocks from .profile if present (they belong in .bashrc)
  for pfile in "$profile" "$HOME/.profile"; do
    if [[ -f "$pfile" ]]; then
      remove_path_from_profile "$pfile"
    fi
  done

  # Remove RHEL9 default PATH block from .bashrc if present
  if [[ -f "$shell_rc" ]]; then
    remove_rhel_path_from_bashrc "$shell_rc"
  fi

  # Check if PATH entries already exist in RC file using unique marker
  local marker="# Add local bin directories to PATH (shell-setup.sh)"
  if grep -Fq "$marker" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} PATH directories already configured in $shell_rc"
      # Still verify login profile sources .bashrc
      ensure_profile_sources_bashrc "$profile" "$shell_rc"
      [[ $old_opts == *e* ]] && set -e
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing PATH configuration${NC}"
      grep -Fv "$marker" "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
      grep -Fv 'export PATH=$HOME/bin:$HOME/.local/bin:$PATH' "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
    fi
  fi

  # Add to beginning of PATH (in correct order)
  echo "" >> "$shell_rc"
  echo "$marker" >> "$shell_rc"
  echo 'export PATH=$HOME/bin:$HOME/.local/bin:$PATH' >> "$shell_rc"
  log_change "ADDED_TO_FILE" "$shell_rc|$marker"
  log_change "ADDED_TO_FILE" "$shell_rc"'|export PATH=$HOME/bin:$HOME/.local/bin:$PATH'
  echo -e "${GREEN}✓${NC} Added PATH configuration to $shell_rc"

  # Ensure login profile sources .bashrc (for interactive login shells)
  ensure_profile_sources_bashrc "$profile" "$shell_rc"

  # Restore set -e if it was enabled
  [[ $old_opts == *e* ]] && set -e
}

# Function to setup XDG_RUNTIME_DIR for container support (Linux only)
setup_xdg_runtime_dir() {
  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  # Only run on Linux, skip on macOS
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${GREEN}✓${NC} Skipping XDG_RUNTIME_DIR (not Linux)"
    [[ $old_opts == *e* ]] && set -e
    return 0
  fi

  local shell_rc=$(get_login_shell_rc)
  local marker="# Container support (shell-setup.sh)"
  local xdg_line='export XDG_RUNTIME_DIR="/run/user/$(id -u)"'

  # Check for our marker to ensure idempotency
  if grep -Fq "$marker" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} XDG_RUNTIME_DIR already configured in $shell_rc"
      [[ $old_opts == *e* ]] && set -e
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing XDG_RUNTIME_DIR configuration${NC}"
      # Remove our block (marker + xdg line)
      grep -Fv "$marker" "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
      grep -Fv 'XDG_RUNTIME_DIR=' "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
    fi
  fi

  # Add XDG_RUNTIME_DIR configuration
  echo "" >> "$shell_rc"
  echo "$marker" >> "$shell_rc"
  echo "$xdg_line" >> "$shell_rc"
  log_change "ADDED_TO_FILE" "$shell_rc|$marker"
  log_change "ADDED_TO_FILE" "$shell_rc"'|export XDG_RUNTIME_DIR="/run/user/$(id -u)"'
  echo -e "${GREEN}✓${NC} Added XDG_RUNTIME_DIR configuration to $shell_rc"

  [[ $old_opts == *e* ]] && set -e
}

# Function to setup convenience environment settings (LS_COLORS and history)
setup_convenience_settings() {
  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  local shell_rc=$(get_login_shell_rc)
  local marker="# Convenience environment settings (shell-setup.sh)"
  local needs_update=false

  # Check if our convenience settings marker exists
  if grep -Fq "$marker" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} Convenience settings already configured in $shell_rc"
      [[ $old_opts == *e* ]] && set -e
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing convenience settings${NC}"
      # Remove old convenience settings block
      sed -i.bak "/$marker/,/^$/d" "$shell_rc"
      needs_update=true
    fi
  else
    needs_update=true
  fi

  if [[ "$needs_update" != true ]]; then
    [[ $old_opts == *e* ]] && set -e
    return 0
  fi

  # Get current LS_COLORS if it exists, otherwise use default
  local current_ls_colors=""
  if grep -q "^export LS_COLORS=" "$shell_rc" 2>/dev/null; then
    current_ls_colors=$(grep "^export LS_COLORS=" "$shell_rc" | head -1 | sed 's/^export LS_COLORS="//' | sed 's/"$//')
  else
    # Use system default or a basic one
    current_ls_colors="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32"
  fi

  # Replace di=01;34 with di=01;36 (change directory color from blue to cyan)
  local new_ls_colors="${current_ls_colors//di=01;34/di=01;36}"
  # Also handle di=34 without the bold
  new_ls_colors="${new_ls_colors//di=34/di=01;36}"

  # Check if HISTCONTROL is already set in the file
  local add_histcontrol=false
  if ! grep -q "^export HISTCONTROL=" "$shell_rc" 2>/dev/null && \
     ! grep -q "^HISTCONTROL=" "$shell_rc" 2>/dev/null; then
    add_histcontrol=true
  fi

  # Check if HISTSIZE/HISTFILESIZE are already set - if so, edit in place
  local add_histsize=true
  local add_histfilesize=true

  if grep -q "^HISTSIZE=" "$shell_rc" 2>/dev/null || grep -q "^export HISTSIZE=" "$shell_rc" 2>/dev/null; then
    # Edit existing HISTSIZE in place
    sed -i.bak 's/^HISTSIZE=.*/HISTSIZE=10000/' "$shell_rc"
    sed -i.bak 's/^export HISTSIZE=.*/export HISTSIZE=10000/' "$shell_rc"
    add_histsize=false
    echo -e "${GREEN}✓${NC} Updated existing HISTSIZE to 10000"
  fi

  if grep -q "^HISTFILESIZE=" "$shell_rc" 2>/dev/null || grep -q "^export HISTFILESIZE=" "$shell_rc" 2>/dev/null; then
    # Edit existing HISTFILESIZE in place
    sed -i.bak 's/^HISTFILESIZE=.*/HISTFILESIZE=20000/' "$shell_rc"
    sed -i.bak 's/^export HISTFILESIZE=.*/export HISTFILESIZE=20000/' "$shell_rc"
    add_histfilesize=false
    echo -e "${GREEN}✓${NC} Updated existing HISTFILESIZE to 20000"
  fi

  # Add convenience settings block
  echo "" >> "$shell_rc"
  echo "$marker" >> "$shell_rc"
  echo "" >> "$shell_rc"
  echo "# Change directory color from dark blue to cyan for better visibility" >> "$shell_rc"
  echo "export LS_COLORS=\"${new_ls_colors}\"" >> "$shell_rc"

  # Only add history settings if they weren't edited in place
  if [[ "$add_histsize" == true ]] || [[ "$add_histfilesize" == true ]]; then
    echo "" >> "$shell_rc"
    echo "# Increase history size" >> "$shell_rc"
    if [[ "$add_histsize" == true ]]; then
      echo "export HISTSIZE=10000" >> "$shell_rc"
    fi
    if [[ "$add_histfilesize" == true ]]; then
      echo "export HISTFILESIZE=20000" >> "$shell_rc"
    fi
  fi

  # Only add HISTCONTROL if it wasn't already set
  if [[ "$add_histcontrol" == true ]]; then
    echo "export HISTCONTROL=ignoreboth" >> "$shell_rc"
  fi

  # Log changes
  log_change "ADDED_TO_FILE" "$shell_rc|$marker"
  log_change "ADDED_TO_FILE" "$shell_rc|# Change directory color from dark blue to cyan for better visibility"
  log_change "ADDED_TO_FILE" "$shell_rc|export LS_COLORS=\"${new_ls_colors}\""

  if [[ "$add_histsize" == true ]]; then
    log_change "ADDED_TO_FILE" "$shell_rc|export HISTSIZE=10000"
  fi
  if [[ "$add_histfilesize" == true ]]; then
    log_change "ADDED_TO_FILE" "$shell_rc|export HISTFILESIZE=20000"
  fi
  if [[ "$add_histcontrol" == true ]]; then
    log_change "ADDED_TO_FILE" "$shell_rc|export HISTCONTROL=ignoreboth"
  fi

  echo -e "${GREEN}✓${NC} Added convenience settings to $shell_rc"

  [[ $old_opts == *e* ]] && set -e
}

# Function to check if SSH key has a password
ssh_key_has_password() {
  local key_file="$1"
  # Check for encryption markers in OpenSSH format keys
  # Encrypted keys contain "aes" or "ENCRYPTED" markers
  if [[ ! -f "$key_file" ]]; then
    return 1  # File doesn't exist
  fi

  # Check in the base64-decoded content (OpenSSH format stores cipher info base64-encoded)
  # Extract the second line (first base64 line) and decode it
  local key_header=$(head -2 "$key_file" | tail -1)
  if echo "$key_header" | base64 -d 2>/dev/null | grep -q "aes"; then
    return 0  # Has password (encrypted)
  fi

  # Also check for legacy PEM format with ENCRYPTED marker
  if grep -q "ENCRYPTED" "$key_file" 2>/dev/null; then
    return 0  # Has password (encrypted)
  fi

  return 1  # No password
}

# Function to setup SSH key
setup_ssh_key() {
  local email="$1"
  local ssh_dir="$HOME/.ssh"
  local key_file="$ssh_dir/id_ed25519"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ -f "$key_file" ]]; then
    echo -e "${YELLOW}SSH key already exists at $key_file${NC}"

    if [[ "$FORCE_MODE" == true ]]; then
      # Backup existing key
      local backup_dir="$ssh_dir/backup-$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$backup_dir"
      cp "$key_file" "$backup_dir/"
      [[ -f "${key_file}.pub" ]] && cp "${key_file}.pub" "$backup_dir/"
      echo -e "${GREEN}✓${NC} Backed up existing SSH key to $backup_dir"
      # Remove existing keys so ssh-keygen doesn't prompt
      rm -f "$key_file" "${key_file}.pub"
      # Continue to generate new key
    elif ssh_key_has_password "$key_file"; then
      echo -e "${GREEN}✓${NC} SSH key has a password (encrypted)"
      return 0
    else
      echo -e "${RED}✗ SSH key exists but has NO password!${NC}"
      echo -e "${YELLOW}Please:${NC}"
      echo "  1. Backup existing key: mv $key_file ${key_file}.bak"
      echo "  2. Add a password to your existing key: ssh-keygen -p -f $key_file"
      echo "  3. Run this script again, or use --force to backup and replace"
      return 1
    fi
  fi

  if [[ ! -f "$key_file" ]] || [[ "$FORCE_MODE" == true ]]; then
    echo -e "${YELLOW}Generating new SSH key with passphrase...${NC}"
    echo -e "${YELLOW}You will be prompted to enter a passphrase (REQUIRED for security):${NC}"

    # Use read to get passphrase from user
    local passphrase=""
    local passphrase_confirm=""

    while true; do
      read -sp "Enter passphrase: " passphrase
      echo

      # Check for empty passphrase
      if [[ -z "$passphrase" ]]; then
        echo -e "${RED}✗ Passphrase cannot be empty for security reasons. Please try again.${NC}"
        echo
        continue
      fi

      echo
      read -sp "Enter passphrase again: " passphrase_confirm
      echo

      if [[ "$passphrase" == "$passphrase_confirm" ]]; then
        break
      else
        echo -e "${RED}✗ Passphrases do not match. Try again.${NC}"
        echo
      fi
    done

    # Generate key with the passphrase using -N flag
    ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N "$passphrase" -q
    log_change "SSH_KEY_CREATED" "$key_file"

    # Check if key file was actually created
    if [[ ! -f "$key_file" ]]; then
      echo -e "${RED}✗ Failed to create SSH key file!${NC}"
      return 1
    fi

    # Verify key was created with password
    if ssh_key_has_password "$key_file"; then
      echo -e "${GREEN}✓${NC} SSH key generated successfully with passphrase"
      return 0
    else
      echo -e "${RED}✗ SSH key was generated without a passphrase!${NC}"
      echo -e "${YELLOW}Removing insecure key. Please run this script again and set a passphrase.${NC}"
      rm -f "$key_file" "${key_file}.pub"
      return 1
    fi
  fi
}

# Function to install keychain
install_keychain() {
  if command -v keychain &> /dev/null; then
    echo -e "${GREEN}✓${NC} Keychain is already installed"
    return 0
  fi

  echo -e "${YELLOW}Installing keychain...${NC}"
  mkdir -p "$HOME/bin"
  curl -fsSL https://raw.githubusercontent.com/danielrobbins/keychain/refs/heads/master/keychain.sh -o "$HOME/bin/keychain"
  chmod +x "$HOME/bin/keychain"
  echo -e "${GREEN}✓${NC} Keychain installed to $HOME/bin/keychain"
}

# Function to setup GPG key
setup_gpg_key() {
  local name="$1"
  local email="$2"

  # Check if GPG is installed
  if ! command -v gpg &> /dev/null; then
    echo -e "${YELLOW}GPG not installed. Install it with: sudo apt install gnupg (or brew install gnupg on macOS)${NC}"
    return 1
  fi

  # Check if user already has a GPG key
  if gpg --list-secret-keys --keyid-format=long "$email" &>/dev/null; then
    local key_id=$(gpg --list-secret-keys --keyid-format=long "$email" | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)

    if [[ "$FORCE_MODE" == true ]]; then
      # Export existing key as backup
      local backup_dir="$HOME/.gnupg/backup-$(date +%Y%m%d_%H%M%S)"
      mkdir -p "$backup_dir"
      gpg --export-secret-keys --armor "$email" > "$backup_dir/private-key-$key_id.asc" 2>/dev/null
      gpg --export --armor "$email" > "$backup_dir/public-key-$key_id.asc" 2>/dev/null
      echo -e "${GREEN}✓${NC} Backed up existing GPG key to $backup_dir" >&2
      # Continue to generate new key (old key will remain in keyring)
    else
      echo -e "${GREEN}✓${NC} GPG key already exists for $email" >&2
      echo "$key_id"
      return 0
    fi
  fi

  echo -e "${YELLOW}Generating GPG key for Git commit signing (no passphrase required)...${NC}" >&2

  # Configure GPG directory
  mkdir -p "$HOME/.gnupg"
  chmod 700 "$HOME/.gnupg"

  # Create GPG key generation configuration without passphrase
  # No passphrase is fine for commit signing keys since they only sign, not encrypt
  cat > /tmp/gpg-gen-key.conf << EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $name
Name-Email: $email
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF

  # Generate the key
  gpg --batch --generate-key /tmp/gpg-gen-key.conf 2>/dev/null
  rm -f /tmp/gpg-gen-key.conf

  # Get the key ID
  local key_id=$(gpg --list-secret-keys --keyid-format=long "$email" | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)

  if [[ -n "$key_id" ]]; then
    log_change "GPG_KEY_CREATED" "$key_id"
    echo -e "${GREEN}✓${NC} GPG key generated successfully" >&2
    echo -e "${GREEN}   Key ID: $key_id${NC}" >&2
    echo "$key_id"
    return 0
  else
    echo -e "${RED}✗ Failed to generate GPG key${NC}" >&2
    return 1
  fi
}

# Function to setup keychain in login profile
setup_keychain_profile() {
  local profile=$(get_login_profile)

  # Build keychain command for SSH key management
  # Use --nogui to avoid pinentry requirement (uses console prompts instead)
  local keychain_line='[ -z $SLURM_PTY_PORT ] && eval $(keychain --nogui --quiet --eval ~/.ssh/id_ed25519)'

  if grep -q "keychain" "$profile" 2>/dev/null; then
    # Check if the desired SSH configuration already exists
    if grep -q "keychain.*--nogui.*--quiet.*--eval.*id_ed25519" "$profile" 2>/dev/null; then
      echo -e "${GREEN}✓${NC} Keychain already configured in $profile"
      return 0
    fi

    # Configuration exists but doesn't match what we want
    if [[ "$FORCE_MODE" == true ]]; then
      echo -e "${YELLOW}Force mode: Removing existing keychain configuration${NC}"
      sed -i.bak '/keychain/d' "$profile"
      sed -i.bak '/SSH Keychain/d' "$profile"
      sed -i.bak '/Only run on interactive/d' "$profile"
    else
      echo -e "${YELLOW}Keychain already configured in $profile${NC}"
      read -p "Update keychain configuration? (y/N): " update_keychain
      if [[ "$update_keychain" == "y" || "$update_keychain" == "Y" ]]; then
        # Remove old keychain lines
        sed -i.bak '/keychain/d' "$profile"
        sed -i.bak '/SSH Keychain/d' "$profile"
        sed -i.bak '/Only run on interactive/d' "$profile"
      else
        echo -e "${GREEN}✓${NC} Keeping existing keychain configuration"
        return 0
      fi
    fi
  fi

  echo "" >> "$profile"
  echo "# SSH Keychain - loads SSH key passphrase into memory" >> "$profile"
  echo "# Only run on interactive login shells (not in Slurm jobs)" >> "$profile"
  echo "$keychain_line" >> "$profile"
  log_change "ADDED_TO_FILE" "$profile|# SSH Keychain - loads SSH key passphrase into memory"
  log_change "ADDED_TO_FILE" "$profile|# Only run on interactive login shells (not in Slurm jobs)"
  log_change "ADDED_TO_FILE" "$profile|$keychain_line"
  echo -e "${GREEN}✓${NC} Added keychain configuration to $profile"
}

# Function to setup SSH config
setup_ssh_config() {
  local ssh_config="$HOME/.ssh/config"

  if [[ -f "$ssh_config" ]]; then
    echo -e "${GREEN}✓${NC} SSH config already exists at $ssh_config"
    return 0
  fi

  echo -e "${YELLOW}Setting up SSH configuration...${NC}"
  read -p "Do you connect through a ssh jump/bastion host (for HPC/AI)? [y/N]: " has_remote

  # If user doesn't have remote hosts to configure, skip SSH config creation
  if [[ "$has_remote" != "y" && "$has_remote" != "Y" ]]; then
    echo -e "${GREEN}✓${NC} Skipping SSH config setup (no remote hosts to configure)"
    return 0
  fi

  local username=""
  local jumphost=""
  local jumphost_user=""
  local hpc_host=""
  local hpc_username=""

  # Ask for username once (used for both jump host and HPC/AI login node)
  read -p "Your username: " username

  # User said yes to jump/bastion host, so ask for details
  read -p "Jump/bastion host hostname (e.g., jump.example.edu): " jumphost
  jumphost_user="$username"

  # Now ask for HPC/AI login node details
  read -p "HPC/AI login node hostname (e.g., login.hpc.university.edu): " hpc_host
  hpc_username="$username"

  # Create SSH config
  mkdir -p "$HOME/.ssh/controlmasters"
  chmod 700 "$HOME/.ssh"

  cat > "$ssh_config" << 'EOF'
# SSH Connection Multiplexing and Global Defaults
Host *
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
    ServerAliveInterval 10
    ServerAliveCountMax 3

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
EOF

  # Add jump host if provided
  if [[ -n "$jumphost" && -n "$jumphost_user" ]]; then
    cat >> "$ssh_config" << EOF

# Jump Host
Host jumphost
    HostName $jumphost
    User $jumphost_user
    ControlMaster auto
    DynamicForward 1080
EOF
  fi

  # Add HPC config if provided
  if [[ -n "$hpc_host" && -n "$hpc_username" ]]; then
    cat >> "$ssh_config" << EOF

# HPC Login Node
Host hpc
    HostName $hpc_host
    User $hpc_username
EOF

    # Add ProxyJump if jumphost exists
    if [[ -n "$jumphost" ]]; then
      echo "    ProxyJump jumphost" >> "$ssh_config"
    fi
  fi

  chmod 600 "$ssh_config"
  chmod 700 "$HOME/.ssh/controlmasters"
  echo -e "${GREEN}✓${NC} SSH config created at $ssh_config"
}

# Function to setup Vim configuration
setup_vim_config() {
  local vimrc="$HOME/.vimrc"
  local vim_wrapper="$HOME/.local/bin/vim-wrapper"
  local edr_symlink="$HOME/bin/edr"

  # Check if vim is installed
  if ! command -v vim &> /dev/null; then
    echo -e "${YELLOW}Vim not installed. Skipping Vim configuration.${NC}"
    return 0
  fi

  # Check if .vimrc already has our configuration
  local has_syntax=false
  local has_colorscheme=false

  if [[ -f "$vimrc" ]]; then
    grep -q "^syntax on" "$vimrc" 2>/dev/null && has_syntax=true
    grep -q "^colorscheme desert" "$vimrc" 2>/dev/null && has_colorscheme=true

    if [[ "$has_syntax" == true && "$has_colorscheme" == true ]]; then
      if [[ "$FORCE_MODE" != true ]]; then
        echo -e "${GREEN}✓${NC} Vim already configured with desert color scheme"
      else
        echo -e "${YELLOW}Force mode: Reconfiguring Vim${NC}"
        # Backup existing .vimrc
        local backup_file="$vimrc.backup-$(date +%Y%m%d_%H%M%S)"
        cp "$vimrc" "$backup_file"
        echo -e "${GREEN}✓${NC} Backed up existing .vimrc to $backup_file"
      fi
    fi
  fi

  # Create or append to .vimrc if needed
  if [[ ! -f "$vimrc" ]]; then
    # Create new .vimrc
    cat > "$vimrc" << 'EOF'
" Enable syntax highlighting
syntax on

" Use desert color scheme
colorscheme desert
EOF
    log_change "CREATED_FILE" "$vimrc"
    echo -e "${GREEN}✓${NC} Created ~/.vimrc with desert color scheme"
  elif [[ "$has_syntax" != true ]] || [[ "$has_colorscheme" != true ]]; then
    # Append to existing .vimrc
    echo "" >> "$vimrc"
    echo "\" Enable syntax highlighting" >> "$vimrc"
    echo "syntax on" >> "$vimrc"
    echo "" >> "$vimrc"
    echo "\" Use desert color scheme" >> "$vimrc"
    echo "colorscheme desert" >> "$vimrc"
    log_change "ADDED_TO_FILE" "$vimrc|\" Enable syntax highlighting"
    log_change "ADDED_TO_FILE" "$vimrc|syntax on"
    log_change "ADDED_TO_FILE" "$vimrc|\" Use desert color scheme"
    log_change "ADDED_TO_FILE" "$vimrc|colorscheme desert"
    echo -e "${GREEN}✓${NC} Added desert color scheme to ~/.vimrc"
  fi

  # Always install/update vim wrapper script
  mkdir -p "$HOME/.local/bin"

  # Download vim-wrapper.sh from GitHub
  if curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/vim-wrapper.sh" -o "$vim_wrapper" 2>/dev/null; then
    chmod +x "$vim_wrapper"
    log_change "CREATED_FILE" "$vim_wrapper"
    echo -e "${GREEN}✓${NC} Installed vim wrapper to ~/.local/bin/vim-wrapper"
  else
    echo -e "${RED}✗${NC} Could not download vim-wrapper.sh from GitHub"
  fi

  # Always create/update edr symlink in ~/bin pointing to ~/.local/bin/vim-wrapper
  mkdir -p "$HOME/bin"
  ln -sf "$vim_wrapper" "$edr_symlink"
  log_change "CREATED_FILE" "$edr_symlink"
  echo -e "${GREEN}✓${NC} Created symlink ~/bin/edr -> ~/.local/bin/vim-wrapper"
}

# Function to fetch GitHub user info from API
get_github_user_info() {
  local github_username="$1"

  # Temporarily disable set -e for this function
  local old_opts=$-
  set +e

  # Query GitHub API with timeout
  local github_response=$(curl -s -m 5 "https://api.github.com/users/$github_username" 2>/dev/null)

  # Check if response is valid (contains "login" field and not an error)
  if ! echo "$github_response" | grep -q '"login"'; then
    [[ $old_opts == *e* ]] && set -e
    return 1  # User not found or API error
  fi

  # Extract name from response using jq if available, otherwise use grep
  local name=""
  if command -v jq &> /dev/null; then
    name=$(echo "$github_response" | jq -r '.name // empty' 2>/dev/null)
  else
    # Fallback to grep - extract name field, handle both quoted and null values
    name=$(echo "$github_response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    # Also check for null value: "name": null
    if echo "$github_response" | grep -q '"name": *null'; then
      name=""
    fi
  fi

  # Use username as fallback if name is empty
  if [[ -z "$name" ]]; then
    name="$github_username"
  fi

  # Extract email from response
  local email=""
  if command -v jq &> /dev/null; then
    email=$(echo "$github_response" | jq -r '.email // empty' 2>/dev/null)
  else
    # Fallback to grep - extract email field if it's not null
    if ! echo "$github_response" | grep -q '"email": *null'; then
      email=$(echo "$github_response" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
    fi
  fi

  # Use noreply GitHub email as fallback if email is empty
  if [[ -z "$email" ]]; then
    email="${github_username}@users.noreply.github.com"
  fi

  # Restore set -e if it was enabled
  [[ $old_opts == *e* ]] && set -e

  echo "$name|$email"
  return 0
}

# Function to setup git configuration
setup_git_config() {
  local git_name="$1"
  local git_email="$2"

  # Check if Git is installed
  if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not installed. Skipping Git configuration.${NC}"
    echo -e "${YELLOW}To install: sudo apt install git (or brew install git on macOS)${NC}"
    return 0
  fi

  # Check if git is already configured
  local current_name=$(git config --global user.name 2>/dev/null)
  local current_email=$(git config --global user.email 2>/dev/null)
  local current_branch=$(git config --global init.defaultBranch 2>/dev/null)

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    echo -e "${GREEN}✓${NC} Git already configured:"
    echo "   Name: $current_name"
    echo "   Email: $current_email"

    if [[ "$current_name" == "$git_name" && "$current_email" == "$git_email" ]]; then
      if [[ "$FORCE_MODE" != true ]]; then
        echo -e "${GREEN}✓${NC} Configuration matches input (no changes needed)"

        # Still set default branch if not set
        if [[ "$current_branch" != "main" ]]; then
          git config --global init.defaultBranch main
          echo -e "${GREEN}✓${NC} Set default branch to 'main'"
        fi
        return 0
      else
        echo -e "${YELLOW}Force mode: Reconfiguring Git${NC}"
      fi
    else
      if [[ "$FORCE_MODE" == true ]]; then
        echo -e "${YELLOW}Force mode: Updating Git configuration${NC}"
      else
        read -p "Update git config with new values? (y/N): " update_git
        if [[ "$update_git" != "y" && "$update_git" != "Y" ]]; then
          echo -e "${YELLOW}Keeping existing git configuration${NC}"
          return 0
        fi
      fi
    fi
  fi

  # Apply configuration
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  git config --global init.defaultBranch main
  echo -e "${GREEN}✓${NC} Git configuration complete"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Step 1: Get user information (skip in light mode)
if [[ "$LIGHT_MODE" != true ]]; then
  echo -e "${YELLOW}Step 1: User Information${NC}"

  # Try to get existing git config (if git is installed)
  existing_name=""
  existing_email=""
  if command -v git &> /dev/null; then
    existing_name=$(git config --global user.name 2>/dev/null || true)
    existing_email=$(git config --global user.email 2>/dev/null || true)
  fi

  if [[ -n "$existing_name" && -n "$existing_email" ]]; then
    echo -e "${GREEN}Found existing git configuration:${NC}"
    echo "   Name: $existing_name"
    echo "   Email: $existing_email"
    read -p "Use this configuration? (Y/n): " use_existing

    if [[ "$use_existing" == "y" || "$use_existing" == "Y" || -z "$use_existing" ]]; then
      user_name="$existing_name"
      user_email="$existing_email"
      echo -e "${GREEN}✓${NC} Using existing configuration"
    else
      # Prompt for GitHub username and fetch info
      while true; do
        read -p "Your GitHub username: " github_username

        if [[ -z "$github_username" ]]; then
          echo -e "${RED}✗ GitHub username cannot be empty${NC}"
          continue
        fi

        echo -e "${YELLOW}Fetching GitHub profile information...${NC}"
        user_info=$(get_github_user_info "$github_username")

        if [[ $? -eq 0 ]]; then
          user_name=$(echo "$user_info" | cut -d'|' -f1)
          user_email=$(echo "$user_info" | cut -d'|' -f2)
          echo -e "${GREEN}✓${NC} GitHub profile found"
          echo "   Name: $user_name"
          echo "   Email: $user_email"
          break
        else
          echo -e "${RED}✗ GitHub user '$github_username' not found${NC}"
        fi
      done
    fi
  else
    # Prompt for GitHub username and fetch info
    while true; do
      read -p "Your GitHub username: " github_username

      if [[ -z "$github_username" ]]; then
        echo -e "${RED}✗ GitHub username cannot be empty${NC}"
        continue
      fi

      echo -e "${YELLOW}Fetching GitHub profile information...${NC}"
      user_info=$(get_github_user_info "$github_username")

      if [[ $? -eq 0 ]]; then
        user_name=$(echo "$user_info" | cut -d'|' -f1)
        user_email=$(echo "$user_info" | cut -d'|' -f2)
        echo -e "${GREEN}✓${NC} GitHub profile found"
        echo "   Name: $user_name"
        echo "   Email: $user_email"
        break
      else
        echo -e "${RED}✗ GitHub user '$github_username' not found${NC}"
      fi
    done
  fi

  if [[ -z "$user_name" || -z "$user_email" ]]; then
    echo -e "${RED}✗ Name and email are required${NC}"
    script_exit 1
  fi
fi

# Step 2: Setup PATH directories
echo -e "\n${YELLOW}Step 2: Setting up PATH directories${NC}"
add_to_begin_of_path

# Step 2b: Setup XDG_RUNTIME_DIR for container support (Linux only)
echo -e "\n${YELLOW}Step 2b: Setting up container support${NC}"
setup_xdg_runtime_dir

# Step 2c: Setup convenience environment settings
echo -e "\n${YELLOW}Step 2c: Setting up convenience environment settings${NC}"
setup_convenience_settings

# In light mode, setup Vim and Git default branch, skip credential setup
if [[ "$LIGHT_MODE" == true ]]; then
  # Step 3: Setup Vim
  echo -e "\n${YELLOW}Step 3: Configuring Vim${NC}"
  setup_vim_config

  # Step 4: Set Git default branch
  echo -e "\n${YELLOW}Step 4: Setting Git default branch${NC}"
  if command -v git &> /dev/null; then
    current_branch=$(git config --global init.defaultBranch 2>/dev/null)
    if [[ "$current_branch" != "main" ]]; then
      log_change "GIT_CONFIG" "init.defaultBranch=${current_branch:-UNSET}"
      git config --global init.defaultBranch main
      echo -e "${GREEN}✓${NC} Set default branch to 'main'"
    else
      echo -e "${GREEN}✓${NC} Default branch already set to 'main'"
    fi
  else
    echo -e "${YELLOW}Git not installed. Skipping Git configuration.${NC}"
  fi
else
  # Full setup mode - run all configuration steps

  # Step 3: Setup SSH key
  echo -e "\n${YELLOW}Step 3: Setting up SSH key${NC}"
  if ! setup_ssh_key "$user_email"; then
    echo -e "${RED}✗ SSH key setup failed. Please resolve the issue and run this script again.${NC}"
    script_exit 1
  fi

  # Step 4: Setup GPG key for Git commit signing
  echo -e "\n${YELLOW}Step 4: Setting up GPG key for Git commit signing${NC}"
  gpg_key_id=""

  # Check if GPG is installed
  if ! command -v gpg &> /dev/null; then
    echo -e "${YELLOW}GPG not installed. Skipping GPG key setup.${NC}"
    echo -e "${YELLOW}To install: sudo apt install gnupg (or brew install gnupg on macOS)${NC}"
  else
    # Check if user already has a GPG key for this email
    if gpg --list-secret-keys --keyid-format=long "$user_email" &>/dev/null; then
      echo -e "${GREEN}✓${NC} GPG key already exists for $user_email"
      gpg_key_id=$(gpg --list-secret-keys --keyid-format=long "$user_email" | grep sec | awk '{print $2}' | cut -d'/' -f2 | head -1)
      echo -e "${GREEN}   Key ID: $gpg_key_id${NC}"
    else
      # Generate GPG key without passphrase (only used for commit signing)
      gpg_key_id=$(setup_gpg_key "$user_name" "$user_email")
      if [[ $? -eq 0 && -n "$gpg_key_id" ]]; then
        echo -e "${GREEN}✓${NC} GPG key setup complete"
      else
        echo -e "${YELLOW}Skipping GPG key setup${NC}"
        gpg_key_id=""
      fi
    fi
  fi

  # Step 5: Install keychain
  echo -e "\n${YELLOW}Step 5: Installing keychain${NC}"
  install_keychain

  # Step 6: Setup keychain in login profile
  echo -e "\n${YELLOW}Step 6: Configuring keychain in login profile${NC}"
  setup_keychain_profile

  # Step 7: Setup Vim
  echo -e "\n${YELLOW}Step 7: Configuring Vim${NC}"
  setup_vim_config

  # Step 8: Setup Git
  echo -e "\n${YELLOW}Step 8: Configuring Git${NC}"
  setup_git_config "$user_name" "$user_email"

  # Configure GPG signing if we have a GPG key
  previous_signing_key=""
  if [[ -n "$gpg_key_id" ]] && command -v git &> /dev/null; then
    # Check if Git signing is already configured with a different key
    current_signing_key=$(git config --global user.signingkey 2>/dev/null || echo "")
    current_gpgsign=$(git config --global commit.gpgsign 2>/dev/null || echo "false")

    if [[ "$current_signing_key" != "$gpg_key_id" ]] || [[ "$current_gpgsign" != "true" ]]; then
      # Save the previous key if it was different
      if [[ -n "$current_signing_key" ]] && [[ "$current_signing_key" != "$gpg_key_id" ]]; then
        previous_signing_key="$current_signing_key"
      fi

      log_change "GIT_CONFIG" "user.signingkey=${current_signing_key:-UNSET}"
      log_change "GIT_CONFIG" "commit.gpgsign=${current_gpgsign}"
      git config --global user.signingkey "$gpg_key_id"
      git config --global commit.gpgsign true
      echo -e "${GREEN}✓${NC} Configured Git to sign commits with GPG key $gpg_key_id"
    else
      echo -e "${GREEN}✓${NC} Git commit signing already configured with key $gpg_key_id"
    fi
  fi

  # Step 9: Setup SSH config
  echo -e "\n${YELLOW}Step 9: Setting up SSH configuration${NC}"
  setup_ssh_config
fi

# Inform user about revert option
echo ""
echo -e "${YELLOW}Note:${NC} All changes have been logged to: ${YELLOW}~/.local/state/shell-setup/shell-setup.log${NC}"
echo -e "To revert these changes later, run: ${YELLOW}bash ~/temp/shell-setup.sh --revert${NC}"
echo ""

# Display completion summary
echo -e "${GREEN}=== Setup Complete! ===${NC}\n"

if [[ "$LIGHT_MODE" == true ]]; then
  echo -e "${YELLOW}Light mode setup completed:${NC}\n"
  echo "✓ PATH directories configured"
  echo "✓ XDG_RUNTIME_DIR configured (Linux only)"
  echo "✓ Convenience settings applied"
  echo "✓ Vim configured with desert theme and edr command"
  echo "✓ Git default branch set to 'main' (if Git is installed)"
  echo ""
  echo -e "${YELLOW}Next steps:${NC}\n"
  echo "1. Reload your shell configuration:"
  CURRENT_SHELL="${SHELL##*/}"
  if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    echo "   . ~/.zshrc"
  else
    echo "   . ~/.bashrc"
  fi
  echo ""
  echo "2. For full setup with SSH, GPG, and Git config:"
  echo "   ./shell-setup.sh"
  echo ""
else
  echo -e "${YELLOW}Next steps:${NC}\n"

  echo "1. Reload your shell configuration:"
  CURRENT_SHELL="${SHELL##*/}"
  if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    echo "   . ~/.zprofile"
  else
    if [[ -f "$HOME/.bash_profile" ]]; then
      echo "   . ~/.bash_profile"
    else
      echo "   . ~/.profile"
    fi
  fi
  echo ""

  echo "2. Add your SSH public key to GitHub:"
  echo "   cat ~/.ssh/id_ed25519.pub"
  echo "   Visit: https://github.com/settings/ssh/new"
  echo ""

  echo "3. Test your SSH connection:"
  echo "   ssh -T git@github.com"
  echo ""

  if [[ -n "$gpg_key_id" ]]; then
    step=4

    # Only show note if there was a different signing key
    if [[ -n "$previous_signing_key" ]]; then
      echo "4. Note: You had a different GPG signing key ($previous_signing_key)"
      echo "   Git is now configured to use: $gpg_key_id"
      echo "   To revert to the old key, run:"
      echo "   git config --global user.signingkey $previous_signing_key"
      echo ""
      step=5
    fi

    echo "$step. Export your GPG public key to add to GitHub:"
    echo "   gpg --armor --export $gpg_key_id"
    echo "   Visit: https://github.com/settings/gpg/new"
    echo ""

    step=$((step + 1))
    echo "$step. Your SSH key passphrase will be loaded on next login via keychain"
    echo "   (GPG key has no passphrase - only used for commit signing)"

    # Check if HPC was configured in SSH config
    if grep -q "^Host hpc" "$HOME/.ssh/config" 2>/dev/null; then
      step=$((step + 1))
      echo ""
      echo "$step. Connect to your HPC system:"
      echo "   ssh hpc"
      echo "   (This uses the jump host configuration you set up)"
    fi
  else
    echo "4. Your SSH key passphrase will be loaded on next login via keychain"
    echo "   (no need to run keychain manually)"

    # Check if HPC was configured in SSH config
    if grep -q "^Host hpc" "$HOME/.ssh/config" 2>/dev/null; then
      echo ""
      echo "5. Connect to your HPC system:"
      echo "   ssh hpc"
      echo "   (This uses the jump host configuration you set up)"
    fi
  fi
fi
echo ""

echo -e "${GREEN}Happy coding!${NC}"
