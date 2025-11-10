:q# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a documentation site repository for documentation written by Dirk Petersen. The site will be built using **mkdocs-material** and hosted on GitHub Pages at `https://dirkpetersen.github.io/docs`.

The documentation will cover the following topics:
- Claude Code
- WSL
- AWS
- Nvidia

The site theme is based on the Oregon State University website theme.

## Architecture

The repository follows a standard mkdocs structure:
- Documentation source files will be placed in a `docs/` directory
- The built site will be generated in the `site/` directory (which is gitignored)
- Configuration is managed through `mkdocs.yml`

## Common Commands

### Setup
```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install mkdocs, material theme, and addons
pip install mkdocs mkdocs-material
```

Always use the `.venv` virtual environment when working with this project.

### Development
```bash
# Serve documentation locally with live reload
mkdocs serve
```

Visit `http://localhost:8000` in your browser to preview changes in real-time.

### Build
```bash
# Build the static site
mkdocs build
```

The output will be in the `site/` directory.

### Deployment

GitHub Actions automatically builds and deploys the site to GitHub Pages on every push to main. The workflow:
1. Installs mkdocs and material theme
2. Builds the documentation
3. Deploys to the `gh-pages` branch

Manual deployment (if needed):
```bash
# Deploy to GitHub Pages
mkdocs gh-deploy
```

## Project Structure

- `CLAUDE.md` - This file
- `README.md` - Project overview
- `LICENSE` - MIT license
- `mkdocs.yml` - mkdocs configuration (to be created)
- `docs/` - Documentation source files (to be created)

## Key Notes

- The repository uses Python tooling (Python-based .gitignore indicates this)
- GitHub Pages deployment uses the standard mkdocs gh-deploy workflow
