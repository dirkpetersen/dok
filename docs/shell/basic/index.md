# Shell - Basic Setup

Essential shell configuration for a productive Unix environment.

## Quick setup of script folders in correct path 

Make sure you create these 2 folders, ~/.local/bin is where many installers but their scripts and ~/bin is the folder you should use for your scripts and wrappers. 

```bash
mkdir -p ~/bin ~/.local/bin
```

then add this line at the end of your shell config file (`.bashrc` for Linux or `.zshrc` for Mac).

```bash
[ -d "$HOME/bin" ] && export PATH="$HOME/bin:"$HOME/.local/bin:$PATH"
```

everything below is optional 

## File Creation Permissions

### Set umask

Control file creation permissions to ensure security:

```bash
# Set umask to 0007
# This makes new files group-writable but not world-readable
umask 0007
```

**What this does:**
- `0007` sets permissions to `u=rwx, g=rwx, o=---`
- Files created are `660` (rw-rw----)
- Directories created are `770` (rwxrwx----)
- Group members can read/write, others cannot access
- Balances security with team collaboration

Add this early in your shell profile (`.bashrc` for Linux or `.zshrc` for Mac).

## PATH Configuration

### Organize Your PATH

Properly structure your PATH for predictable binary resolution:

```bash
# User-local binaries (takes precedence)
export PATH="$HOME/.local/bin:$PATH"

# Traditional user bin directory
export PATH="$PATH:$HOME/bin"

# Cargo binaries (Rust)
export PATH="$PATH:$HOME/.cargo/bin"
```

**Order matters:**
- `~/.local/bin` first - User-installed tools take precedence
- System PATH in middle - Standard locations
- `~/bin` last - Legacy user directory
- `~/.cargo/bin` last - Rust binaries

### Set Micromamba as Default Conda

If using micromamba for environment management:

```bash
# Set micromamba as default conda
export CONDA_EXE="$(command -v micromamba)"
export MAMBA_EXE="${CONDA_EXE}"
```

## Rootless Container Configuration

### Podman/Docker Support

For rootless Podman or Docker:

```bash
# Set runtime directory for rootless containers
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Alias docker to podman if available
if command -v podman &> /dev/null; then
    alias docker='podman'
fi
```

**Why this matters:**
- Allows running containers without root privileges
- XDG_RUNTIME_DIR provides runtime file storage
- `docker=podman` alias simplifies workflow if migrating from Docker

## Shell Profile Setup

### Bash Configuration

**Interactive Shell Config** - Edit `~/.bashrc`:

```bash
# File creation permissions
umask 0007

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# Set default editor
export EDITOR=vim
export GIT_EDITOR=vim

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Conda/Micromamba
export CONDA_EXE="$(command -v micromamba)"

# Rootless container support
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Container aliases
if command -v podman &> /dev/null; then
    alias docker='podman'
fi

# Add useful aliases
alias ll='ls -lah'
alias cd..='cd ..'
alias clear-cache='rm -rf ~/.cache'
```

**Login Shell Config** - Edit `~/.profile` or `~/.bash_profile`:

```bash
# Source .bashrc for interactive login shells
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# SSH Keychain - ONLY in login shell (skip in Slurm PTY)
if [[ -z "$SLURM_PTY_PORT" ]]; then
    eval $(~/.local/bin/keychain --quiet --eval id_ed25519)
fi
```

### Zsh Configuration

**Interactive Shell Config** - Edit `~/.zshrc`:

```bash
# File creation permissions
umask 0007

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# Set default editor
export EDITOR=vim
export GIT_EDITOR=vim

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Conda/Micromamba
export CONDA_EXE="$(command -v micromamba)"

# Rootless container support
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Container aliases
if command -v podman &> /dev/null; then
    alias docker='podman'
fi

# Add useful aliases
alias ll='ls -lah'
alias cd..='cd ..'
```

**Login Shell Config** - Edit `~/.zprofile`:

```bash
# SSH Keychain - ONLY in login shell (skip in Slurm PTY)
if [[ -z "$SLURM_PTY_PORT" ]]; then
    eval $(~/.local/bin/keychain --quiet --eval id_ed25519)
fi
```

## Essential Environment Variables

Set these in your shell configuration:

```bash
# Editor (for Git, system tools)
export EDITOR=vim
export GIT_EDITOR=vim

# Language and encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# File creation permissions
umask 0007

# Container support
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
```

## Color Schemes

### Directory Colors for Better Visibility

Add to your shell configuration for improved readability:

```bash
# Export LS_COLORS with improved directory visibility
# Change directory color from dark blue (01;34) to cyan (01;36)
export LS_COLORS="di=01;36:ln=01;36:so=01;31:pi=40;33:ex=01;32:bd=40;33;01:cd=40;33;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzop=01;31:*.xz=01;31:*.zst=01;31:*.zstd=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:"
```

**Key color changes:**
- `di=01;36` - Directories in cyan (easier to see than dark blue)
- `ln=01;36` - Symlinks in cyan
- `ex=01;32` - Executables in green

### Vim Color Scheme

Configure Vim for better visibility in `~/.vimrc`:

```vim
" Enable syntax highlighting
syntax on

" Use desert color scheme
colorscheme desert
```

## Command History

Keep your shell history clean and effective:

```bash
# Increase history size
export HISTSIZE=10000
export HISTFILESIZE=10000

# Ignore duplicate commands
export HISTCONTROL=ignoredups

# Ignore common commands from history
export HISTIGNORE="ls:cd:pwd:history"
```

## SSH Keychain Auto-Loading

### Smart Keychain Initialization

**IMPORTANT:** Add SSH keychain to your **login shell profile** ONLY (`.profile`, `.bash_profile`, or `.zprofile`), NOT to `.bashrc` or `.zshrc`:

```bash
# SSH Keychain - Skip in Slurm computing environment
# This avoids conflicts with Slurm's PTY management
# ONLY add this to login profiles: ~/.profile, ~/.bash_profile, or ~/.zprofile
if [[ -z "$SLURM_PTY_PORT" ]]; then
    eval $(~/.local/bin/keychain --quiet --eval id_ed25519)
fi
```

**Why login shell profile only?**
- Login shells (`.profile`, `.zprofile`) run once per login session
- Interactive shells (`.bashrc`, `.zshrc`) run for every new shell
- SSH agent should only be initialized once, not repeatedly
- Prevents multiple keychain processes and agent conflicts

**Why the Slurm check?**
- Slurm (job scheduler) has its own PTY management
- Loading keychain in Slurm context can cause conflicts
- Check `$SLURM_PTY_PORT` to detect Slurm environment
- Skip keychain loading in compute jobs

## Complete Configuration Example

### Full ~/.bashrc (Interactive Shell Config)

```bash
# File creation permissions
umask 0007

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# Editor
export EDITOR=vim
export GIT_EDITOR=vim

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Container support
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Conda/Micromamba
export CONDA_EXE="$(command -v micromamba)"

# Directory colors (cyan for better visibility)
export LS_COLORS="di=01;36:..."

# History
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups
export HISTIGNORE="ls:cd:pwd:history"

# Container aliases
if command -v podman &> /dev/null; then
    alias docker='podman'
fi

# Useful aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'
alias l='ls -la'
alias cls='clear'
alias py='python'
alias serve='python -m http.server'
alias clear-cache='rm -rf ~/.cache'
```

### Full ~/.profile (Login Shell Config)

```bash
# Source .bashrc if it exists
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# SSH Keychain - ONLY in login shell (skip in Slurm)
# DO NOT add this to .bashrc!
if [[ -z "$SLURM_PTY_PORT" ]]; then
    eval $(~/.local/bin/keychain --quiet --eval id_ed25519)
fi
```

## Secure Development Environment

Your shell environment should be:

- **Secure**: SSH keys with passphrases, keychain for convenience, restricted permissions (umask)
- **Clean**: Well-organized PATH, proper binary resolution
- **Productive**: Useful aliases, good history management, proper colors
- **Isolated**: Virtual environments, container support, environment detection (Slurm)
- **Collaborative**: Group-writable files (umask 0007) for team projects
