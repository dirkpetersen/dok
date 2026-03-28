# Shell - Windows Subsystem for Linux (WSL)

Setup and configuration guide for Windows Subsystem for Linux.

## Overview

WSL enables running a Linux environment directly on Windows, providing a native Linux development experience without dual-boot or virtualization overhead. This is essential for developers using Windows who want access to Unix tools and workflows.

## WSL Versions

- **WSL 2** (Recommended): Full Linux kernel, better performance, Docker support
- **WSL 1**: Compatibility layer, lower resource usage

We recommend **WSL 2** for modern development.

## Installation

### Prerequisites

- Windows 10 version 2004+ or Windows 11
- Administrator access

### Install WSL 2

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This installs:
- WSL 2
- Linux kernel
- Default distribution (Ubuntu)

Restart your computer after installation.

### Verify Installation

```bash
wsl --version
```

Should show WSL 2 with Linux kernel version.

## Linux Distribution Setup

### Choose Your Distribution

After WSL 2 installation, you have Ubuntu by default. You can also install other distributions:

```powershell
# List available distributions
wsl --list --online

# Install a specific distribution
wsl --install -d Debian
```

### Launch WSL Terminal

From Windows:

```powershell
# Launch default distribution
wsl

# Launch specific distribution
wsl -d Ubuntu
```

Or use Windows Terminal (recommended) for better UX.

## Essential WSL Configuration

### Optimize Performance

Create or edit `~/.wslconfig` on Windows (in your Windows user directory):

```ini
[interop]
enabled = true
appendWindowsPath = true

[wsl2]
memory = 4GB
processors = 4
swap = 2GB
localhostForwarding = true

[boot]
systemd = true
```

Adjust `memory` and `processors` based on your system.

### Enable systemd

WSL 2 now supports systemd (system daemon). Add to `~/.wslconfig`:

```ini
[boot]
systemd = true
```

Then restart WSL:

```bash
wsl --shutdown
wsl
```

This enables services like SSH, Docker, and other daemons.

## Development Environment in WSL

### Update Package Manager

```bash
sudo apt-get update
sudo apt-get upgrade
```

### Install Essential Tools

```bash
# Git
sudo apt-get install git

# Build tools
sudo apt-get install build-essential

# Text editors
sudo apt-get install vim nano

# Development utilities
sudo apt-get install curl wget
```

### Install Development Runtimes

Install languages and runtimes you use:

```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install nodejs

# Python
sudo apt-get install python3 python3-pip

# Go
sudo apt-get install golang-go
```

## File System Integration

### Access Windows Files from WSL

Windows drives are mounted at `/mnt/c`, `/mnt/d`, etc.:

```bash
# Navigate to Windows home
cd /mnt/c/Users/YourUsername

# List Windows files
ls /mnt/d/Projects
```

### Access WSL Files from Windows

WSL files are accessible via `\\wsl$\` in Windows Explorer:

```
\\wsl$\Ubuntu\home\username
```

Or in PowerShell:

```powershell
cd \\wsl$\Ubuntu\home\username\
```

## SSH and Git in WSL

### Configure SSH

WSL integrates with your host SSH setup. Your WSL SSH commands can use your Windows SSH keys or generate WSL-specific ones.

Generate a new key in WSL:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
```

### Git Configuration

Set up Git in WSL (see [Git](../git/index.md) section for detailed setup):

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor vim
```

## Common WSL Commands

```bash
# List running distributions
wsl --list --verbose

# Terminate a distribution
wsl --terminate Ubuntu

# Shutdown all WSL instances
wsl --shutdown

# Export distribution for backup
wsl --export Ubuntu ubuntu-backup.tar

# Import distribution
wsl --import UbuntuBackup c:\wsl\ubuntu-backup ubuntu-backup.tar
```

## Performance Tips

### Use Native Storage

- Store projects in WSL filesystem (faster): `~/projects`
- Avoid Windows filesystem when possible: `/mnt/c/...`
- Cross-filesystem operations are slower

### Mount Options

WSL 2 automatically optimizes mounts, but you can configure specific options in `/etc/wsl.conf`:

```ini
[interop]
enabled = true
appendWindowsPath = true

[automount]
enabled = true
root = /mnt
```

### Docker Desktop Integration

Install Docker Desktop for Windows with WSL 2 backend for best performance.

## Troubleshooting

### WSL Hangs or Freezes

```bash
# From PowerShell, terminate WSL
wsl --shutdown

# Restart
wsl
```

### Out of Memory

Increase allocated memory in `~/.wslconfig`:

```ini
[wsl2]
memory = 8GB
```

### Networking Issues

If `localhost` doesn't work, ensure in `~/.wslconfig`:

```ini
[wsl2]
localhostForwarding = true
```

## Integration with Development Tools

### Visual Studio Code

Install [WSL Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) for seamless development.

```bash
# Open current directory in VS Code
code .

# From Windows, open WSL directory
code \\wsl$\Ubuntu\home\username\project
```

### Terminal Emulators

**Windows Terminal** (Recommended):
- Integrates WSL naturally
- Multiple tabs and panes
- Customizable profiles

**Other Options**:
- Hyper
- Alacritty
- Kitty

## Best Practices

- ✅ Use WSL 2 for better performance
- ✅ Install dev tools in WSL, not Windows
- ✅ Store projects in WSL filesystem
- ✅ Use Windows Terminal for better UX
- ✅ Enable systemd for daemon support
- ✅ Regularly update WSL and distributions
- ❌ Don't mix Windows and WSL paths in the same project
- ❌ Don't edit WSL files from Windows (permission issues)

## WSL Coding Appliance (kanna-code)

For a zero-friction AI coding appliance on Windows, use the `setup-wsl-claude-kanna.ps1` script. It turns a fresh Windows machine into a fully configured Linux dev environment running [kanna-code](https://github.com/PuneetGopinath/kanna) in a single PowerShell command.

### What it sets up

The script runs six idempotent steps — safe to re-run at any time:

1. **WSL 2** — installs if missing, prompts for reboot if needed
2. **Windows Terminal** — installs via `winget` if missing
3. **Ubuntu** — installs as the WSL distro with a default user `claude` (passwordless sudo)
4. **dev-station** — runs [`dev-station-install.sh`](../../scripts/dev-station-install.sh) inside Ubuntu (shell setup, claude-wrapper, Node.js, AWS CLI)
5. **Bun + kanna-code** — installs the [Bun](https://bun.sh) runtime and `kanna-code` globally
6. **Launches kanna** — starts the kanna interactive session

### Quick start

Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/setup-wsl-claude-kanna.ps1" -OutFile setup-wsl-claude-kanna.ps1
.\setup-wsl-claude-kanna.ps1
```

Or, if you have already cloned this repo:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\setup-wsl-claude-kanna.ps1
```

!!! note "First-time reboot"
    If WSL is not yet installed, the script will install it and ask you to reboot. Simply re-run the script after rebooting — all steps are idempotent and will skip anything already done.

!!! tip "Default user"
    The Ubuntu distro is configured with a `claude` user (passwordless sudo). You can add your own user and change the WSL default later via `/etc/wsl.conf`.

### Source

Script: [`scripts/setup-wsl-claude-kanna.ps1`](https://github.com/dirkpetersen/dok/blob/main/scripts/setup-wsl-claude-kanna.ps1)
