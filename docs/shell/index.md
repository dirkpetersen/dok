# Shell

Unix shell configuration, SSH setup, and Git workflows for a productive development environment.

## Overview

The Shell section is organized into three key areas:

1. **[Basic](basic/index.md)** - Shell profiles, environment variables, aliases, and history management
2. **[SSH](ssh/index.md)** - SSH keys, keychain integration, connection multiplexing, and security best practices
3. **[Git](git/index.md)** - Git configuration, aliases, workflows, and commit best practices

## Quick Start

### Automated Setup (Recommended)

Run the comprehensive shell setup script to automatically configure everything:

```bash
curl -o /tmp/shell-setup.sh https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/shell-setup.sh && bash /tmp/shell-setup.sh
```

This script will:
- Add `~/bin` and `~/.local/bin` to your PATH
- Generate SSH keys with passphrase protection
- Install and configure keychain
- Set up SSH multiplexing and optional jump host configuration
- Configure Git globally
- Provide instructions for adding your SSH key to GitHub

??? info "View script contents"
    ```bash linenums="1"
    --8<-- "scripts/shell-setup.sh"
    ```

### Manual Setup

If you prefer to set up components manually:

1. **Set Up Your Environment** - Start with [Basic](basic/index.md) to configure your shell profile with essential environment variables and aliases.

2. **Configure SSH** - Follow [SSH](ssh/index.md) to generate SSH keys with passphrases and set up keychain for secure, convenient authentication.

3. **Configure Git** - Finally, set up [Git](git/index.md) with global configuration, aliases, and workflows for efficient version control.

## Key Components

### Basic Shell

- Shell profile configuration (Bash/Zsh)
- Environment variables
- Useful aliases
- Command history management

### SSH Configuration

- Ed25519 key generation with passphrases
- SSH key permissions and security
- SSH multiplexing for faster connections
- SSH keychain for passphrase caching
- Jump host proxy configuration
- Connection optimization

### Git Workflows

- Git configuration and aliases
- Commit message best practices
- Branch naming conventions
- Common Git workflows
- Helpful Git commands
- SSH integration with Git

## Security-First Approach

This setup emphasizes:

- 🔐 **SSH keys with passphrases** - Protecting your keys even if compromised
- 🔄 **Keychain caching** - Convenience without sacrificing security
- 🚀 **Connection multiplexing** - Faster, more reliable remote access
- 📝 **Clear Git workflows** - Organized, traceable development history
- 🛡️ **Best practices** - Industry standards for secure shell usage

## Topics by Use Case

### Remote Server Access
1. Generate SSH keys ([SSH](ssh/index.md))
2. Configure SSH multiplexing ([SSH](ssh/index.md))
3. Set up jump hosts for secure access ([SSH](ssh/index.md))

### Git Development
1. Configure Git globally ([Git](git/index.md))
2. Add Git aliases for productivity ([Git](git/index.md))
3. Follow branch naming conventions ([Git](git/index.md))

### Shell Productivity
1. Set up shell profile ([Basic](basic/index.md))
2. Add useful aliases ([Basic](basic/index.md))
3. Configure environment variables ([Basic](basic/index.md))
