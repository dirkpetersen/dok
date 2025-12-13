#!/bin/bash
#
# Install latest Python Build Standalone (Indigo) for current OS and architecture
# Supports: x86_64-linux, aarch64-linux, macOS (x86_64 and ARM64)
#
# Usage: bash python-build-standalone-install.sh [target_dir]
# Default target_dir: ~/.python
#

set -euo pipefail

# Configuration
TARGET_DIR="${1:-$HOME/.python}"
GITHUB_REPO="indygreg/python-build-standalone"
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Detect OS and architecture
detect_system() {
    local os
    local arch

    os=$(uname -s)
    arch=$(uname -m)

    case "$os" in
        Linux)
            case "$arch" in
                x86_64)
                    echo "x86_64-unknown-linux-gnu"
                    ;;
                aarch64)
                    echo "aarch64-unknown-linux-gnu"
                    ;;
                *)
                    echo "Error: Unsupported Linux architecture: $arch" >&2
                    return 1
                    ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                x86_64)
                    echo "x86_64-apple-darwin"
                    ;;
                arm64)
                    echo "aarch64-apple-darwin"
                    ;;
                *)
                    echo "Error: Unsupported macOS architecture: $arch" >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Unsupported OS: $os" >&2
            return 1
            ;;
    esac
}

# Fetch latest release info from GitHub API
fetch_latest_release() {
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases/latest"

    echo "Fetching latest release information..." >&2
    curl -fsSL "$api_url"
}

# Find the download URL for a specific target
find_download_url() {
    local target="$1"
    local release_json="$2"

    # Extract download URLs and find the one matching our target
    echo "$release_json" | grep -o '"browser_download_url": "[^"]*' | grep -o 'https[^"]*' | grep "$target" | grep "\.tar\.zst$" | head -1
}

# Extract version from download URL
extract_version() {
    local url="$1"
    local filename=$(basename "$url")
    # Remove .tar.zst extension and get the version part
    filename="${filename%.tar.zst}"
    echo "$filename"
}

main() {
    echo "Python Build Standalone Installer"
    echo "===================================="
    echo ""

    # Detect system
    TARGET=$(detect_system)
    echo "Detected system: $TARGET"
    echo ""

    # Fetch latest release
    echo "Fetching latest release from GitHub..."
    RELEASE_JSON=$(fetch_latest_release)

    # Find download URL
    DOWNLOAD_URL=$(find_download_url "$TARGET" "$RELEASE_JSON")

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "Error: Could not find release for target: $TARGET" >&2
        echo "Available targets may vary. Check: https://github.com/$GITHUB_REPO/releases/latest" >&2
        return 1
    fi

    VERSION=$(extract_version "$DOWNLOAD_URL")
    echo "Latest release: $VERSION"
    echo "Download URL: $DOWNLOAD_URL"
    echo ""

    # Download
    echo "Downloading Python Build Standalone..."
    curl -fsSL --progress-bar -o "$TEMP_DIR/python.tar.zst" "$DOWNLOAD_URL"
    echo ""

    # Extract
    echo "Extracting to $TARGET..."
    mkdir -p "$TARGET"
    tar -I zstd -xf "$TEMP_DIR/python.tar.zst" -C "$TARGET"
    echo ""

    # Verify
    PYTHON_BIN="$TARGET/python/install/bin/python"
    if [ -x "$PYTHON_BIN" ]; then
        echo "✓ Installation successful!"
        echo ""
        echo "Next steps:"
        echo "1. Add to your PATH by adding this to ~/.bashrc or ~/.zshrc:"
        echo ""
        echo "   export PATH=\"\$HOME/.python/python/install/bin:\$PATH\""
        echo ""
        echo "2. Reload your shell:"
        echo ""
        echo "   source ~/.bashrc  # or ~/.zshrc"
        echo ""
        echo "3. Verify installation:"
        echo ""
        echo "   python --version"
        echo ""
        echo "Python version:"
        "$PYTHON_BIN" --version
    else
        echo "Error: Python binary not found at $PYTHON_BIN" >&2
        return 1
    fi
}

main "$@"
