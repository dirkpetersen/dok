# Python

Python development setup and package management using modern tools.

## Overview

This setup uses two modern package managers:
- **UV**: Fast, reliable Python package manager and project tool
- **Pixi**: Cross-platform package manager compatible with conda

## Installing Indigo (Python Binary Distribution)

For a clean, optimized Python environment, use Indigo - a standalone Python distribution.

### Download and Install

1. **Download the latest Indigo release**

```bash
curl -L https://github.com/indygreg/python-build-standalone/releases/download/20240713/cpython-3.13.0b4+20240713-x86_64-unknown-linux-gnu.tar.zst -o python.tar.zst
```

2. **Extract to your home directory**

```bash
mkdir -p ~/.python
tar -I zstd -xf python.tar.zst -C ~/.python
```

3. **Add to PATH**

Add this to your shell configuration (`.bashrc`, `.zshrc`):

```bash
export PATH="$HOME/.python/python/install/bin:$PATH"
```

4. **Verify Installation**

```bash
python --version
```

## UV Package Manager

UV is a fast, reliable package manager for Python projects.

### Installation

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
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
