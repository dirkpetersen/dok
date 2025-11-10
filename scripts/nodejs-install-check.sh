#!/bin/bash
# nodejs-install-check.sh
# Script to check and install Node.js/npm with proper configuration

# Function to detect user's login shell and add npm bin directory to PATH
add_to_end_of_path() {
  local npm_bin_path="$HOME/.npm/global/bin"
  local shell_rc=""
  local shell_name=""
  local login_shell=""

  # Check if npm bin directory is already in PATH
  if [[ ":$PATH:" == *":$npm_bin_path:"* ]]; then
    echo "✓ npm bin directory already in PATH environment variable"
    return 0
  fi

  # Get the user's login shell from the SHELL environment variable
  # This is reliable across Linux and macOS
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
      echo "Warning: Detected shell '$login_shell'. Please manually add this line to your shell RC file:"
      echo "export PATH=$npm_bin_path:\$PATH"
      return 1
      ;;
  esac

  # Add npm bin directory to the shell RC file
  echo "" >> "$shell_rc"
  echo "# Add npm global bin directory to PATH" >> "$shell_rc"
  echo "export PATH=$npm_bin_path:\$PATH" >> "$shell_rc"
  echo "✓ Added npm bin directory to $shell_name configuration ($shell_rc)"

  return 0
}

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "npm not found. Attempting to install Node.js..."

  # Try loading nodejs module (for HPC systems)
  if command -v module &> /dev/null; then
    module load nodejs
  else
    # Install nvm and Node.js
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

    # Load nvm (in lieu of restarting the shell)
    source "$HOME/.nvm/nvm.sh"

    # Download and install Node.js
    nvm install 24
  fi
fi

# Ensure npm installs global packages in home directory
npm_prefix=$(npm config get prefix)
if [[ "$npm_prefix" != "$HOME"* ]]; then
  echo "Configuring npm to install global packages in home directory..."
  npm config set prefix ~/.npm/global

  # Create the directory if it doesn't exist
  mkdir -p ~/.npm/global

  # Add npm bin directory to PATH using the function
  add_to_end_of_path
fi

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
