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
  set -e
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
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  show_help
elif [[ "$1" == "--revert" ]]; then
  revert_changes
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

# Function to add directories to beginning of PATH
add_to_begin_of_path() {
  local shell_rc=$(get_login_shell_rc)
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

  # Check if PATH entries already exist in RC file
  # Look for the exact PATH export line we add
  if grep -Fq "export PATH=\$HOME/bin:\$HOME/.local/bin:\$PATH" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} PATH directories already configured in $shell_rc"
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing PATH configuration${NC}"
      grep -Fv "export PATH=\$HOME/bin:\$HOME/.local/bin:\$PATH" "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
      grep -Fv "# Add local bin directories to PATH (front)" "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
    fi
  fi

  # Add to beginning of PATH (in correct order)
  echo "" >> "$shell_rc"
  echo "# Add local bin directories to PATH (front)" >> "$shell_rc"
  echo "export PATH=\$HOME/bin:\$HOME/.local/bin:\$PATH" >> "$shell_rc"
  log_change "ADDED_TO_FILE" "$shell_rc|# Add local bin directories to PATH (front)"
  log_change "ADDED_TO_FILE" "$shell_rc"'|export PATH=$HOME/bin:$HOME/.local/bin:$PATH'
  echo -e "${GREEN}✓${NC} Added PATH configuration to $shell_rc"
}

# Function to setup XDG_RUNTIME_DIR for container support (Linux only)
setup_xdg_runtime_dir() {
  # Only run on Linux, skip on macOS
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${GREEN}✓${NC} Skipping XDG_RUNTIME_DIR (not Linux)"
    return 0
  fi

  local shell_rc=$(get_login_shell_rc)
  local xdg_line='export XDG_RUNTIME_DIR="/run/user/$(id -u)"'

  # Check if XDG_RUNTIME_DIR is already set in shell rc
  if grep -q "export XDG_RUNTIME_DIR=" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} XDG_RUNTIME_DIR already configured in $shell_rc"
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing XDG_RUNTIME_DIR configuration${NC}"
      grep -Fv 'export XDG_RUNTIME_DIR=' "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
      grep -Fv "# Container support" "$shell_rc" > "$shell_rc.tmp" && mv "$shell_rc.tmp" "$shell_rc"
    fi
  fi

  # Add XDG_RUNTIME_DIR configuration
  echo "" >> "$shell_rc"
  echo "# Container support" >> "$shell_rc"
  echo "$xdg_line" >> "$shell_rc"
  log_change "ADDED_TO_FILE" "$shell_rc|# Container support"
  log_change "ADDED_TO_FILE" "$shell_rc"'|export XDG_RUNTIME_DIR="/run/user/$(id -u)"'
  echo -e "${GREEN}✓${NC} Added XDG_RUNTIME_DIR configuration to $shell_rc"
}

# Function to setup convenience environment settings (LS_COLORS and history)
setup_convenience_settings() {
  local shell_rc=$(get_login_shell_rc)
  local needs_update=false

  # Check if our convenience settings marker exists
  if grep -q "# Convenience environment settings" "$shell_rc" 2>/dev/null; then
    if [[ "$FORCE_MODE" != true ]]; then
      echo -e "${GREEN}✓${NC} Convenience settings already configured in $shell_rc"
      return 0
    else
      echo -e "${YELLOW}Force mode: Removing existing convenience settings${NC}"
      # Remove old convenience settings block
      sed -i.bak '/# Convenience environment settings/,/^$/d' "$shell_rc"
      needs_update=true
    fi
  else
    needs_update=true
  fi

  if [[ "$needs_update" != true ]]; then
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
  local histcontrol_line=""
  if ! grep -q "^export HISTCONTROL=" "$shell_rc" 2>/dev/null && \
     ! grep -q "^HISTCONTROL=" "$shell_rc" 2>/dev/null; then
    # HISTCONTROL not set, add it with ignoreboth
    histcontrol_line="export HISTCONTROL=ignoreboth"
  fi

  # Add convenience settings block
  echo "" >> "$shell_rc"
  echo "# Convenience environment settings" >> "$shell_rc"
  echo "" >> "$shell_rc"
  echo "# Change directory color from dark blue to cyan for better visibility" >> "$shell_rc"
  echo "export LS_COLORS=\"${new_ls_colors}\"" >> "$shell_rc"
  echo "" >> "$shell_rc"
  echo "# Increase history size" >> "$shell_rc"
  echo "export HISTSIZE=10000" >> "$shell_rc"
  echo "export HISTFILESIZE=20000" >> "$shell_rc"

  # Only add HISTCONTROL if it wasn't already set
  if [[ -n "$histcontrol_line" ]]; then
    echo "export HISTCONTROL=ignoreboth" >> "$shell_rc"
  fi

  # Log changes
  log_change "ADDED_TO_FILE" "$shell_rc|# Convenience environment settings"
  log_change "ADDED_TO_FILE" "$shell_rc|# Change directory color from dark blue to cyan for better visibility"
  log_change "ADDED_TO_FILE" "$shell_rc|export LS_COLORS=\"${new_ls_colors}\""
  log_change "ADDED_TO_FILE" "$shell_rc|# Increase history size"
  log_change "ADDED_TO_FILE" "$shell_rc|export HISTSIZE=10000"
  log_change "ADDED_TO_FILE" "$shell_rc|export HISTFILESIZE=20000"

  # Only log HISTCONTROL if we added it
  if [[ -n "$histcontrol_line" ]]; then
    log_change "ADDED_TO_FILE" "$shell_rc|export HISTCONTROL=ignoreboth"
  fi

  echo -e "${GREEN}✓${NC} Added convenience settings to $shell_rc"
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
  curl -s https://raw.githubusercontent.com/danielrobbins/keychain/refs/heads/master/keychain.sh -o "$HOME/bin/keychain"
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
  local vim_wrapper="$HOME/bin/vim-wrapper"
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

  # Install vim wrapper script
  if [[ ! -f "$vim_wrapper" ]] || [[ "$FORCE_MODE" == true ]]; then
    mkdir -p "$HOME/bin"

    # Download or copy vim-wrapper.sh
    if curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/vim-wrapper.sh" -o "$vim_wrapper" 2>/dev/null; then
      chmod +x "$vim_wrapper"
      log_change "CREATED_FILE" "$vim_wrapper"
      echo -e "${GREEN}✓${NC} Installed vim wrapper to ~/bin/vim-wrapper"
    else
      echo -e "${YELLOW}Could not download vim-wrapper.sh from GitHub${NC}"
      echo -e "${YELLOW}Creating vim wrapper locally...${NC}"
      cat > "$vim_wrapper" << 'EOF'
#!/bin/bash
# vim-wrapper.sh - Simple vim wrapper for easy editing
# Starts in insert mode and uses double-escape to save/quit

vim -c "startinsert" \
    -c "let g:esc_pressed = 0" \
    -c "function! SaveAndQuit()
        if &modified
            let choice = confirm('Save changes?', \"&Yes\n&No\n&Cancel\", 1)
            if choice == 1
                wq
            elseif choice == 2
                q!
            endif
        else
            q
        endif
    endfunction" \
    -c "function! HandleEscape()
        if g:esc_pressed
            let g:esc_pressed = 0
            call SaveAndQuit()
        else
            let g:esc_pressed = 1
            call timer_start(500, {-> execute('let g:esc_pressed = 0')})
            return \"\\<Esc>\"
        endif
        return ''
    endfunction" \
    -c "inoremap <expr> <Esc> HandleEscape()" \
    -c "nnoremap <Esc><Esc> :call SaveAndQuit()<CR>" \
    "$@"
EOF
      chmod +x "$vim_wrapper"
      log_change "CREATED_FILE" "$vim_wrapper"
      echo -e "${GREEN}✓${NC} Created vim wrapper at ~/bin/vim-wrapper"
    fi
  else
    echo -e "${GREEN}✓${NC} Vim wrapper already installed"
  fi

  # Create edr symlink
  if [[ ! -L "$edr_symlink" ]] || [[ "$FORCE_MODE" == true ]]; then
    ln -sf "vim-wrapper" "$edr_symlink"
    log_change "CREATED_FILE" "$edr_symlink"
    echo -e "${GREEN}✓${NC} Created symlink ~/bin/edr -> vim-wrapper"
  else
    echo -e "${GREEN}✓${NC} Symlink ~/bin/edr already exists"
  fi
}

# Function to setup git configuration
setup_git_config() {
  local git_name="$1"
  local git_email="$2"

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

# Step 1: Get user information
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
    read -p "Your name (for Git/SSH): " user_name
    read -p "Your email (for Git/SSH): " user_email
  fi
else
  read -p "Your name (for Git/SSH): " user_name
  read -p "Your email (for Git/SSH): " user_email
fi

if [[ -z "$user_name" || -z "$user_email" ]]; then
  echo -e "${RED}✗ Name and email are required${NC}"
  script_exit 1
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

# Step 7: Setup SSH config
echo -e "\n${YELLOW}Step 7: Setting up SSH configuration${NC}"
setup_ssh_config

# Step 8: Setup Vim
echo -e "\n${YELLOW}Step 8: Configuring Vim${NC}"
setup_vim_config

# Step 9: Setup Git
echo -e "\n${YELLOW}Step 9: Configuring Git${NC}"
setup_git_config "$user_name" "$user_email"

# Configure GPG signing if we have a GPG key
previous_signing_key=""
if [[ -n "$gpg_key_id" ]]; then
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

# Inform user about revert option
echo ""
echo -e "${YELLOW}Note:${NC} All changes have been logged to: ${YELLOW}$LOG_FILE${NC}"
echo -e "To revert these changes later, run: ${YELLOW}$0 --revert${NC}"
echo ""

# Step 10: Display completion summary
echo -e "${GREEN}=== Setup Complete! ===${NC}\n"

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
else
  echo "4. Your SSH key passphrase will be loaded on next login via keychain"
  echo "   (no need to run keychain manually)"
fi
echo ""

echo -e "${GREEN}Happy coding!${NC}"
