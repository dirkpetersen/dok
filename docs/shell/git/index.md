# Shell - Git Configuration

Git setup, configuration, and shell aliases for efficient version control workflows.

## Git Essentials 

at the very least execute these commands initially  

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main

```

everything below is optional 

## Git Aliases

Add these convenient aliases to your shell configuration:

```bash
# Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log'
```

## Global Git Configuration

Set up your global Git configuration with modern 2025 best practices:

```bash
# User identity (required)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Editor and diff
git config --global core.editor vim
git config --global diff.tool vimdiff

# Default branch name (modern standard)
git config --global init.defaultBranch main

# Line endings (prevents git conflicts across OS)
git config --global core.autocrlf input  # On macOS/Linux
# git config --global core.autocrlf true  # On Windows/WSL

# Rebase by default for cleaner history
git config --global pull.rebase true
git config --global rebase.autoStash true

# Safe pushing - only push current branch
git config --global push.default current

# Fast-forward only on pull
git config --global merge.ff only

# Sign commits with GPG (security best practice)
git config --global commit.gpgsign false  # Set to true if using GPG keys

# Better merge conflict handling
git config --global merge.conflictStyle zdiff3

# Show helpful status output
git config --global status.showStash true
git config --global status.showUntrackedFiles all
```

## Complete Global Git Configuration File

View your complete Git configuration at `~/.gitconfig`:

```ini
[user]
    name = Your Name
    email = your.email@example.com

[core]
    editor = vim
    autocrlf = input
    pager = less -x2

[init]
    defaultBranch = main

[pull]
    rebase = true

[rebase]
    autoStash = true

[push]
    default = current

[merge]
    ff = only
    conflictStyle = zdiff3

[commit]
    gpgsign = false
    # Set to true if using GPG:
    # gpgsign = true

[status]
    showStash = true
    showUntrackedFiles = all

[diff]
    tool = vimdiff

[difftool]
    prompt = false

[alias]
    # Status commands
    st = status
    ss = status --short
    unstage = restore --staged
    discard = restore

    # Branch commands
    br = branch
    bra = branch -a
    brv = branch -vv

    # Checkout/switch
    co = checkout
    sw = switch

    # Commit commands
    ci = commit
    amend = commit --amend --no-edit

    # Log commands
    lg = log --oneline --graph --decorate --all
    last = log -1 HEAD
    recent = log --oneline -10

    # Stash commands
    stash-all = stash save -u

    # Useful utilities
    aliases = config --get-regexp alias
    count = rev-list --count HEAD
```


## 2025 Best Practices

### Default Branch Name

Modern projects use `main` instead of `master`:

```bash
git config --global init.defaultBranch main
```

### Safer Pushing

Prevent accidental pushes to wrong branches:

```bash
git config --global push.default current
```

### Clean History

Enable rebase on pull for linear, clean commit history:

```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
```

### Merge Conflict Resolution

Use modern conflict resolution strategy:

```bash
git config --global merge.conflictStyle zdiff3
```

This shows three-way diffs for better conflict understanding.

### Commit Signing (Optional)

For security, sign commits with GPG (requires setup):

```bash
# After GPG key setup
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID
```

### Line Ending Management

Prevent line ending issues across platforms:

```bash
git config --global core.autocrlf input     # macOS/Linux
git config --global core.safecrlf true      # Warn on mixed line endings
```

## Common Git Workflows

### Initialize a Repository

```bash
mkdir my-project
cd my-project
git init
```

### Clone a Repository

```bash
git clone git@github.com:USERNAME/repository.git
cd repository
```

### Create and Switch Branches

```bash
git checkout -b feature/my-feature
```

### Stage and Commit Changes

```bash
# Stage specific files
git add path/to/file

# Stage all changes
git add .

# Commit with message
git commit -m "Describe your changes"
```

### Push to Remote

```bash
# Push current branch
git push origin feature/my-feature

# Push all branches
git push --all

# Force push (use with caution!)
git push --force-with-lease
```

### Pull Changes

```bash
# Pull with rebase (recommended)
git pull --rebase

# Pull normally
git pull
```

### View History

```bash
# View commit log
git log

# View log with graph
git log --oneline --graph --all

# View commits by author
git log --author="Name"
```

## Git Best Practices

### Commit Messages

Write clear, descriptive commit messages:

```bash
# Good
git commit -m "Fix authentication bug in login flow"

# Bad
git commit -m "Fix bug"
```

Follow the format:
- **First line**: Short summary (50 chars max)
- **Blank line**
- **Body**: Explain what and why (wrap at 72 chars)

### Branch Naming

Use descriptive branch names:

```bash
# Features
git checkout -b feature/user-authentication

# Bug fixes
git checkout -b bugfix/login-redirect

# Improvements
git checkout -b improvement/performance-optimization

# Release
git checkout -b release/v1.2.0
```

### Keeping History Clean

```bash
# Rebase before pushing to clean up commits
git rebase -i origin/main

# Squash commits
git rebase -i HEAD~3  # Interactive rebase last 3 commits

# Amend last commit
git commit --amend --no-edit
```

## Git Environment Variables

Set these in your shell configuration:

```bash
# Git editor
export GIT_EDITOR=vim

# Avoid being asked for credentials repeatedly
export GIT_ASKPASS=/usr/bin/git-credential-osxkeychain  # macOS
```

## Helpful Git Commands

```bash
# Check status
git status

# Show unstaged changes
git diff

# Show staged changes
git diff --cached

# Show changes in specific file
git diff path/to/file

# Stash changes temporarily
git stash

# Apply stashed changes
git stash pop

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard last commit completely
git reset --hard HEAD~1

# View who changed each line
git blame path/to/file

# Search commit history
git log -S "search term"
```

## SSH Integration with Git

Ensure your SSH key is configured for Git authentication:

```bash
# Test SSH connection to GitHub
ssh -T git@github.com

# Should output: Hi USERNAME! You've successfully authenticated...
```

Your SSH configuration from the [SSH section](../ssh/index.md) enables secure Git operations without storing credentials.
