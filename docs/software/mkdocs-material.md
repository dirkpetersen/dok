# MkDocs Material Documentation Setup

Complete guide to creating your own personal documentation site using MkDocs Material, GitHub Pages, and Claude Code for automated management.

## Overview

This guide walks you through creating a documentation site that:

- Uses **MkDocs Material** theme for beautiful, modern documentation
- Automatically deploys to **GitHub Pages** via GitHub Actions
- Is managed entirely by **Claude Code** using the GitHub CLI
- Includes a local development server in a virtual environment
- Auto-restarts the server after each commit for live testing

## Prerequisites

Before starting, ensure you have:

- GitHub account with SSH authentication configured
- GitHub CLI (`gh`) installed and authenticated
- Claude Code installed and configured
- Git configured with your name and email
- SSH key added to your GitHub account

??? tip "Verify Prerequisites"
    ```bash
    # Check GitHub CLI authentication
    gh auth status

    # Verify SSH key is added to GitHub
    ssh -T git@github.com

    # Check git configuration
    git config --global user.name
    git config --global user.email
    ```

## Step 1: Create GitHub Repository

Create a new repository for your documentation using the GitHub CLI:

```bash
# Create a new public repository named 'dok'
gh repo create dok --public --description "Personal documentation site"

# Alternative: Create with a different name
gh repo create my-docs --public --description "My personal documentation"
```

**Repository Naming:**
- Suggested name: `dok` (short for "documentation")
- Alternative names: `docs`, `my-docs`, `knowledge-base`
- The repository name doesn't affect the final site URL

## Step 2: Clone Repository

Clone your new repository using SSH:

```bash
# Clone the repository (replace YOUR_USERNAME with your GitHub username)
git clone git@github.com:YOUR_USERNAME/dok.git

# Navigate into the repository
cd dok

# Verify remote is configured
git remote -v
```

## Step 3: Create README.md

Create a README.md file that explains your intent to use Claude Code for managing the documentation:

```bash
# Create README.md with initial content
cat > README.md << 'EOF'
# Documentation

Personal documentation site built with MkDocs Material and managed by Claude Code.

## Purpose

This documentation site will be maintained using Claude Code with the following features:

- **MkDocs Material Theme**: Modern, responsive documentation theme
- **GitHub Pages**: Automatic deployment on every push to main
- **Claude Code Management**: All site management done via Claude Code AI assistant
- **GitHub CLI Integration**: Repository operations handled by `gh` command
- **Local Development Server**: Testing via mkdocs serve in .venv virtual environment

## Workflow

1. Edit this README.md to describe documentation topics
2. Launch Claude Code in this directory
3. Run `/init` to create CLAUDE.md and initialize project structure
4. Claude Code will:
   - Create mkdocs.yml configuration
   - Set up docs/ directory structure
   - Create GitHub Actions workflow for deployment
   - Start local development server in .venv
   - Restart server after each commit for testing

## Topics to Cover

[Add your documentation topics here, for example:]

- Development environment setup
- Programming guides and tutorials
- Tool configurations
- Project notes and references

## Development

The local server runs at http://127.0.0.1:8000/ and automatically reloads when files change.

Claude Code manages the server lifecycle:
- Starts server in .venv on first build
- Kills and restarts server after commits
- Ensures clean state for testing changes
EOF

# Add and commit the README
git add README.md
git commit -m "Initial commit: Add README with Claude Code documentation plan"
git push origin main
```

## Step 4: Launch Claude Code

Now start Claude Code to initialize your documentation project:

```bash
# Launch Claude Code in the repository directory
claude .
```

## Step 5: Run /init Command

Once Claude Code is running, execute the `/init` command:

```
/init
```

**What `/init` Does:**

The `/init` command will analyze your repository and README.md, then:

1. **Create CLAUDE.md** - Guidance file for future Claude Code sessions
2. **Generate mkdocs.yml** - MkDocs configuration with Material theme
3. **Create docs/ Structure** - Documentation directory with initial pages
4. **Set up GitHub Actions** - Workflow for automatic deployment
5. **Initialize Virtual Environment** - Python venv at .venv/
6. **Install Dependencies** - mkdocs and mkdocs-material packages
7. **Start Development Server** - Local server at http://127.0.0.1:8000/

??? example "Example /init Output"
    ```
    I'll analyze your repository and initialize the MkDocs Material documentation site.

    Creating project structure:
    ✓ Created CLAUDE.md
    ✓ Created mkdocs.yml
    ✓ Created docs/index.md
    ✓ Created .github/workflows/deploy.yml
    ✓ Created .gitignore

    Setting up Python environment:
    ✓ Created virtual environment at .venv/
    ✓ Installed mkdocs==1.6.1
    ✓ Installed mkdocs-material==9.6.23

    Starting development server:
    ✓ Server running at http://127.0.0.1:8000/

    Your documentation site is ready! Visit http://127.0.0.1:8000/ to preview.
    ```

## Step 6: Working with Your Documentation

### Making Changes

Claude Code manages your documentation workflow:

**Adding Content:**
```
Please add a new page about Python package managers to docs/python/package-managers.md
```

**Updating Configuration:**
```
Update mkdocs.yml to add a new section for Cloud Platforms
```

**Modifying Theme:**
```
Change the primary color to teal and enable dark mode by default
```

### Automatic Server Management

Claude Code automatically manages the development server:

1. **After Initialization**: Server starts in .venv and runs continuously
2. **After Commits**: Server is killed and restarted with fresh changes
3. **After Errors**: Server is restarted if it crashes or encounters issues

This ensures you always see the latest changes at http://127.0.0.1:8000/

### Committing Changes

When you're ready to commit, Claude Code will:

```bash
# Claude Code executes these steps automatically:

# 1. Stage all changes
git add -A

# 2. Create descriptive commit message
git commit -m "Add Python package managers documentation"

# 3. Push to GitHub
git push origin main

# 4. Kill existing mkdocs server
pkill -f "mkdocs serve"

# 5. Restart server in virtual environment
source .venv/bin/activate && mkdocs serve &
```

## Project Structure

After initialization, your repository will have this structure:

```
dok/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions deployment workflow
├── .venv/                      # Python virtual environment (gitignored)
├── docs/                       # Documentation source files
│   ├── index.md               # Homepage
│   └── [topic-folders]/       # Organized by topic
├── site/                       # Built site (gitignored)
├── .gitignore                  # Ignore .venv, site/, etc.
├── CLAUDE.md                   # Guidance for Claude Code
├── mkdocs.yml                  # MkDocs configuration
├── README.md                   # Repository description
└── LICENSE                     # License file (optional)
```

## GitHub Actions Deployment

The deployment workflow (`.github/workflows/deploy.yml`) automatically:

1. Triggers on every push to `main` branch
2. Sets up Python 3.12
3. Installs mkdocs and mkdocs-material
4. Builds the documentation site
5. Deploys to `gh-pages` branch
6. Makes site available at: `https://YOUR_USERNAME.github.io/dok/`

??? example "Deployment Workflow"
    ```yaml
    name: Deploy to GitHub Pages

    on:
      push:
        branches:
          - main

    jobs:
      build-and-deploy:
        runs-on: ubuntu-latest
        permissions:
          contents: write
        steps:
          - uses: actions/checkout@v4

          - name: Set up Python
            uses: actions/setup-python@v4
            with:
              python-version: '3.12'

          - name: Install dependencies
            run: |
              pip install mkdocs mkdocs-material

          - name: Build documentation
            run: mkdocs build

          - name: Deploy to GitHub Pages
            uses: peaceiris/actions-gh-pages@v3
            with:
              github_token: ${{ secrets.GITHUB_TOKEN }}
              publish_dir: ./site
    ```

## Viewing Your Site

### Local Development

While working on documentation:

- **URL**: http://127.0.0.1:8000/
- **Live Reload**: Changes appear automatically
- **Server Management**: Claude Code handles start/stop/restart

### Published Site

After pushing to GitHub:

1. GitHub Actions builds and deploys (takes 1-2 minutes)
2. Site becomes available at: `https://YOUR_USERNAME.github.io/dok/`
3. Updates appear within minutes of pushing changes

??? tip "Check Deployment Status"
    ```bash
    # View recent workflow runs
    gh run list --limit 5

    # Watch current deployment
    gh run watch

    # View deployment logs if there are issues
    gh run view --log
    ```

## Common Commands

### Local Development

```bash
# Start server manually (if needed)
source .venv/bin/activate && mkdocs serve

# Build site locally
mkdocs build

# Stop server
pkill -f "mkdocs serve"
```

### Repository Management via Claude Code

Instead of running commands manually, ask Claude Code:

```
Commit these changes with a descriptive message and push to GitHub
```

```
Show me the deployment status of the latest push
```

```
Add a new section to the navigation for Cloud Platforms
```

```
Update the theme to use a different color scheme
```

## MkDocs Material Features

Your documentation site includes these Material theme features:

### Navigation

- **Instant loading** - Fast page transitions
- **Navigation tabs** - Top-level sections in tabs
- **Sticky navigation** - Navigation stays visible while scrolling
- **Table of contents** - Right sidebar with page sections

### Search

- **Search suggestions** - As-you-type search suggestions
- **Search highlighting** - Highlights search terms in results
- **Search sharing** - Share search results via URL

### Content

- **Code highlighting** - Syntax highlighting with line numbers
- **Code copying** - One-click code block copying
- **Admonitions** - Call-out boxes for notes, warnings, tips
- **Task lists** - Interactive checkboxes in markdown

### Appearance

- **Dark/Light mode** - Automatic theme switching
- **Color customization** - Configurable primary and accent colors
- **Typography** - Beautiful, readable fonts
- **Responsive design** - Works on all device sizes

## Customization

### Theme Colors

Ask Claude Code to update colors in `mkdocs.yml`:

```
Change the primary color to teal and accent color to amber
```

### Adding Sections

Structure your documentation by topic:

```
Create a new section for AWS documentation with pages for:
- EC2 instances
- S3 storage
- IAM policies
```

### Custom Homepage

Customize `docs/index.md` as your landing page:

```
Update the homepage to include:
- Brief introduction
- Quick start guide
- Links to main sections
```

## Troubleshooting

### Server Won't Start

If the development server fails to start:

```
The mkdocs server isn't working. Please diagnose and fix the issue.
```

Claude Code will:
1. Check if port 8000 is in use
2. Verify virtual environment is set up correctly
3. Check mkdocs installation
4. Restart the server on an alternative port if needed

### Deployment Failures

If GitHub Actions deployment fails:

```
The latest deployment failed. Please check the workflow logs and fix the issue.
```

Claude Code will:
1. Fetch workflow logs using `gh run view --log`
2. Identify the error
3. Fix the issue (usually dependencies or configuration)
4. Commit and push the fix

### Build Errors

If `mkdocs build` reports errors:

```
There are build errors in the documentation. Please review and fix them.
```

Common issues:
- Broken links in markdown files
- Missing files referenced in navigation
- Invalid YAML in mkdocs.yml
- Malformed markdown syntax

## Best Practices

### Documentation Structure

Organize content logically:

```
docs/
├── index.md                    # Homepage
├── getting-started/
│   ├── index.md               # Section overview
│   ├── installation.md
│   └── quickstart.md
├── guides/
│   ├── index.md
│   ├── beginner/
│   └── advanced/
└── reference/
    ├── index.md
    └── api.md
```

### Writing Content

- **Clear headings**: Use descriptive section titles
- **Code examples**: Include practical, working examples
- **Screenshots**: Add images to docs/images/ directory
- **Links**: Use relative links between pages
- **Search keywords**: Include relevant terms for searchability

### Git Workflow

Let Claude Code manage commits:

- **Descriptive messages**: Claude Code writes clear commit messages
- **Logical grouping**: Related changes committed together
- **Automatic pushing**: Changes deploy immediately after commit

### Server Management

Trust Claude Code to handle the server:

- Starts automatically after `/init`
- Restarts after commits for testing
- Runs in background without terminal blocking
- Uses .venv for clean dependency isolation

## Advanced Topics

### Custom Domain

To use a custom domain (e.g., docs.example.com):

1. Add CNAME file to docs/ directory:
   ```bash
   echo "docs.example.com" > docs/CNAME
   ```

2. Configure DNS:
   ```
   CNAME record: docs.example.com → YOUR_USERNAME.github.io
   ```

3. Update `site_url` in mkdocs.yml:
   ```yaml
   site_url: https://docs.example.com/
   ```

### Additional Plugins

Ask Claude Code to add plugins:

```
Add the mkdocs-awesome-pages-plugin for flexible navigation ordering
```

```
Install mkdocs-mermaid2-plugin for diagram support
```

Common plugins:
- `mkdocs-awesome-pages-plugin` - Flexible page ordering
- `mkdocs-mermaid2-plugin` - Mermaid diagram rendering
- `mkdocs-git-revision-date-localized-plugin` - Last updated timestamps
- `mkdocs-minify-plugin` - Minify HTML/CSS/JS

### Multiple Repositories

Create separate documentation sites for different projects:

```bash
# Personal knowledge base
gh repo create knowledge --public
cd knowledge
# ... follow setup steps ...

# Project-specific docs
gh repo create project-docs --public
cd project-docs
# ... follow setup steps ...
```

Each repository gets its own:
- GitHub Pages site at `YOUR_USERNAME.github.io/REPO_NAME/`
- Development server on localhost
- Independent content and configuration

## Example: This Documentation Site

This very documentation site you're reading was created using this exact process:

1. Created repository: `dirkpetersen/dok`
2. Cloned via SSH
3. Wrote README.md describing documentation goals
4. Launched Claude Code and ran `/init`
5. Claude Code created:
   - CLAUDE.md with project guidance
   - mkdocs.yml with Material theme configuration
   - docs/ structure with shell, cloud, and code-pasting sections
   - GitHub Actions workflow for deployment
   - Virtual environment and local server

The entire site is managed by Claude Code:
- All commits made via Claude Code
- Server automatically restarts after changes
- Documentation organized into logical sections
- Deployed automatically to GitHub Pages

View the source: [github.com/dirkpetersen/dok](https://github.com/dirkpetersen/dok)

## Summary

Creating a personal documentation site with Claude Code:

1. **Create repo**: `gh repo create dok --public`
2. **Clone**: `git clone git@github.com:USERNAME/dok.git`
3. **Write README.md**: Describe documentation intent and topics
4. **Launch Claude Code**: `claude .`
5. **Initialize**: Run `/init` command
6. **Develop**: Ask Claude Code to add content, make changes
7. **Automatic deployment**: Push triggers GitHub Actions
8. **Live site**: Available at `https://USERNAME.github.io/dok/`

Claude Code handles:
- Project structure creation
- Virtual environment setup
- Server start/stop/restart
- Git commits and pushes
- Configuration updates
- Content organization

You focus on:
- Describing what you want
- Reviewing changes
- Writing content (with Claude Code's help)

The result: beautiful, automatically-deployed documentation with minimal manual work.
