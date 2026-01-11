#!/bin/bash
# install-claude-wrapper.sh
# Force reinstall of claude-wrapper, removing old files and downloading fresh

INSTALL_DIR="$HOME/bin"
WRAPPER_PATH="$INSTALL_DIR/claude-wrapper.sh"
SYMLINK_PATH="$INSTALL_DIR/claude"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Claude Wrapper Force Reinstall${NC}"
echo ""

# Remove old wrapper and symlink
if [[ -f "$WRAPPER_PATH" ]]; then
  echo "Removing old wrapper: $WRAPPER_PATH"
  rm -f "$WRAPPER_PATH"
  echo -e "${GREEN}✓${NC} Removed old wrapper"
fi

if [[ -L "$SYMLINK_PATH" ]]; then
  echo "Removing old symlink: $SYMLINK_PATH"
  rm -f "$SYMLINK_PATH"
  echo -e "${GREEN}✓${NC} Removed old symlink"
elif [[ -e "$SYMLINK_PATH" ]]; then
  echo "Removing old file: $SYMLINK_PATH"
  rm -f "$SYMLINK_PATH"
  echo -e "${GREEN}✓${NC} Removed old file"
fi

echo ""

# Create ~/bin if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Download fresh wrapper from GitHub
echo "Downloading fresh wrapper from GitHub..."
if curl -fsSL -o "$WRAPPER_PATH" https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh; then
  echo -e "${GREEN}✓${NC} Downloaded wrapper script"
else
  echo -e "${RED}✗ Failed to download wrapper script${NC}" >&2
  exit 1
fi

# Make it executable
chmod +x "$WRAPPER_PATH"
echo -e "${GREEN}✓${NC} Made wrapper executable"

# Create symlink
ln -s "claude-wrapper.sh" "$SYMLINK_PATH"
echo -e "${GREEN}✓${NC} Created symlink ~/bin/claude"

echo ""
echo -e "${GREEN}=== Reinstall Complete! ===${NC}"
echo ""
echo "You can now run the claude wrapper:"
echo ""
echo "  claude                # Launch with Haiku (fast/default)"
echo "  claude sonnet         # Launch with Sonnet (balanced)"
echo "  claude opus           # Launch with Opus (most capable)"
echo "  claude --local        # Use local LLM (requires LOCAL_ANTHROPIC_BASE_URL)"
echo ""
