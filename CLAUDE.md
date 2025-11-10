# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MkDocs-based documentation site that provides comprehensive guides for development environment setup, cloud platforms, and AI-assisted development workflows. The site is built with mkdocs-material (theme inspired by Oregon State University website) and automatically deployed to GitHub Pages at `https://dirkpetersen.github.io/dok`.

## Architecture

### Documentation Structure

The repository follows a standard MkDocs structure with organized topic sections:

- `docs/` - All markdown documentation files organized by topic
  - `shell/` - Shell configuration (basic, SSH, Git, WSL)
  - `code-pasting/` - AI-assisted development workflow (Claude Code, GitHub, Markdown, Python)
  - `clouds/` - Cloud platform guides (AWS, Azure, GCP)
  - `nvidia/` - GPU and CUDA configuration
  - `software/` - Software reference dictionary
  - `tutorials/` - Step-by-step guides
- `scripts/` - Utility scripts referenced in documentation
  - `claude-wrapper.sh` - AWS Bedrock wrapper for Claude Code with model switching
  - `shell-setup.sh` - Comprehensive shell and SSH setup automation
  - `nodejs-install-check.sh` - Node.js installation verification
- `mkdocs.yml` - Site configuration with navigation structure
- `.github/workflows/deploy.yml` - Automated GitHub Pages deployment

### Key Scripts

The scripts directory contains production-ready automation tools documented in the site:

1. **claude-wrapper.sh**: Wraps Claude Code CLI with AWS Bedrock integration, providing easy model switching (opus/sonnet/haiku) and permission management. Self-installs to `~/bin/claude`.

2. **shell-setup.sh**: Idempotent setup script that configures a complete development environment including PATH, SSH keys with passphrases, GPG keys for Git signing, keychain for SSH key management, and Vim configuration. Supports `--force` mode with backups and `--revert` to undo all changes.

## Common Commands

### Local Development

```bash
# Option 1: Install dependencies using system Python (simpler)
pip install mkdocs mkdocs-material

# Option 2: Use virtual environment (isolated)
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install mkdocs mkdocs-material

# Serve documentation locally with live reload at http://localhost:8000
mkdocs serve

# Build static site to site/ directory
mkdocs build
```

Note: Either approach works. The `.venv` directory is gitignored if you choose to use a virtual environment.

### Testing Scripts

```bash
# Test claude-wrapper.sh installation
./scripts/claude-wrapper.sh --install

# Run shell setup (interactive mode)
./scripts/shell-setup.sh

# Force reconfiguration with backups
./scripts/shell-setup.sh --force

# Revert all changes made by shell-setup.sh
./scripts/shell-setup.sh --revert
```

### Deployment

GitHub Actions automatically deploys to GitHub Pages on every push to main:
1. Sets up Python 3.12
2. Installs mkdocs and mkdocs-material
3. Runs `mkdocs build`
4. Deploys `site/` directory to gh-pages branch using peaceiris/actions-gh-pages@v3

Manual deployment (if needed):
```bash
mkdocs gh-deploy
```

## Documentation Philosophy

This documentation follows a "Code Pasting" philosophy - writing clear, comprehensive requirements in Markdown that AI assistants like Claude Code can use to generate high-quality code. Key principles:

1. **Clear Requirements**: Documentation serves as both user guide and AI specification
2. **Security-First**: SSH keys require passphrases, proper AWS IAM profiles, least-privilege patterns
3. **Idempotent Scripts**: All automation scripts can be run repeatedly without breaking existing configurations
4. **Practical Examples**: Real-world configurations with explanations, not generic templates

## Working with Documentation

### Adding New Pages

1. Create markdown file in appropriate `docs/` subdirectory
2. Update navigation in `mkdocs.yml` under the `nav:` section
3. Follow existing page structure with clear headers and code examples
4. Use MkDocs markdown extensions configured in mkdocs.yml:
   - Admonitions for notes/warnings
   - Code highlighting with line numbers
   - Task lists
   - Table of contents with permalinks

### Modifying Scripts

The scripts in `scripts/` are referenced and explained in the documentation:

- **claude-wrapper.sh** is documented in `docs/code-pasting/claude-code/index.md`
- **shell-setup.sh** is documented throughout `docs/shell/` sections

When modifying scripts:
1. Maintain backward compatibility
2. Update corresponding documentation pages
3. Test both interactive and force modes
4. Ensure logging and revert functionality works

### Style Guidelines

- Use descriptive headers with clear hierarchy
- Include command examples with expected output
- Explain the "why" behind configurations, not just the "what"
- Link to official documentation for external tools
- Use admonitions for warnings, tips, and important notes
- Keep security considerations prominent
