# Python

Python development setup and package management using modern tools.

## Overview

This setup uses two modern package managers:
- **UV**: Fast, reliable Python package manager and project tool
- **Pixi**: Cross-platform package manager compatible with conda

## Installing Python Build Standalone (Indigo)

For a clean, optimized Python environment, use Python Build Standalone - a high-quality standalone Python distribution that works on Linux (x86_64 and ARM64) and macOS (Intel and Apple Silicon).

### Quick Install (Recommended)

Use the automated installer script that automatically detects your OS and architecture:

```bash
curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/python-build-standalone-install.sh?$(date +%s)" | bash
```

This script will:
- Automatically detect your OS and architecture (x86_64 Linux, ARM64 Linux, macOS Intel, macOS Apple Silicon)
- Fetch the latest release from GitHub
- Download and extract Python to `~/.python`
- Verify the installation
- Display next steps to add Python to your PATH

!!! tip "Custom Installation Directory"
    To install to a different directory, pass it as an argument:
    ```bash
    curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/python-build-standalone-install.sh?$(date +%s)" | bash -s /opt/python
    ```

### Manual Installation (All Platforms)

If you prefer to install manually or the script doesn't work, follow these steps:

**1. Detect your system's target identifier:**

```bash
# Linux x86_64
echo "x86_64-unknown-linux-gnu"

# Linux ARM64
echo "aarch64-unknown-linux-gnu"

# macOS Intel (x86_64)
echo "x86_64-apple-darwin"

# macOS Apple Silicon (ARM64)
echo "aarch64-apple-darwin"
```

**2. Visit the releases page** to find the latest version:
[github.com/indygreg/python-build-standalone/releases](https://github.com/indygreg/python-build-standalone/releases)

**3. Download the appropriate release** (replace `YOUR_TARGET` with your system's identifier):

```bash
RELEASE_TAG="20241217"  # Replace with latest tag from releases page
TARGET="x86_64-unknown-linux-gnu"  # Replace with your target

curl -fsSL "https://github.com/indygreg/python-build-standalone/releases/download/$RELEASE_TAG/cpython-3.13.$RELEASE_TAG-$TARGET.tar.zst" -o python.tar.zst
```

**4. Extract to your home directory:**

```bash
mkdir -p ~/.python
tar -I zstd -xf python.tar.zst -C ~/.python
```

**5. Add to PATH**

Add this to your shell configuration (`.bashrc`, `.zshrc`):

```bash
export PATH="$HOME/.python/python/install/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

**6. Verify Installation**

```bash
python --version
```

## UV Package Manager

UV is a fast, reliable package manager for Python projects.

### Installation

```bash
curl -fsSL https://astral.sh/uv/install.sh | sh
```

### Creating a New Project

```bash
uv init my-project
cd my-project
```

### Adding Dependencies

```bash
uv add requests
uv add --dev pytest
```

### Running Python Scripts

```bash
uv run script.py
```

### Installing from pyproject.toml

```bash
uv sync
```

### Creating a Virtual Environment

```bash
uv venv
. .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

## Pixi Package Manager

Pixi is a cross-platform package manager compatible with conda environments, great for data science and scientific computing.

### Installation

```bash
curl -fsSL https://pixi.sh/install.sh | bash
```

### Creating a New Project

```bash
pixi init my-data-project
cd my-data-project
```

### Adding Dependencies

```bash
pixi add numpy pandas
pixi add --pypi requests
```

### Running Commands

```bash
pixi run python script.py
```

### Creating Environments

```bash
pixi create -e analysis
pixi run -e analysis python analysis.py
```

### Conda Compatibility

Pixi automatically handles conda channels and environments:

```bash
pixi add -c conda-forge numpy
```

## Choosing Between UV and Pixi

| Use Case | Tool |
|----------|------|
| Standard Python projects | UV |
| Data science / Jupyter | Pixi |
| Machine learning | Pixi |
| Web development | UV |
| CLI tools | UV |
| Scientific computing | Pixi |
| Mixed dependencies (PyPI + conda) | Pixi |

## Virtual Environments

### With UV

```bash
# Create virtual environment
uv venv

# Activate
. .venv/bin/activate

# Deactivate
deactivate
```

### With Pixi

```bash
# Create environment
pixi create -e myenv

# Use environment
pixi run -e myenv python script.py
```

## Best Practices

- **Always use virtual environments** to isolate project dependencies
- **Use UV for most Python projects** - it's faster and simpler
- **Use Pixi for data science** - better conda ecosystem support
- **Commit lock files** (`uv.lock` or `pixi.lock`) to version control
- **Document dependencies** in `pyproject.toml` or `pixi.toml`
