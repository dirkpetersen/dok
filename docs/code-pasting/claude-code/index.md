# Claude Code

Documentation for Claude Code, an AI-powered development tool integrated into this workflow.

## Overview

Claude Code provides AI-assisted development capabilities for code generation, analysis, and problem-solving. This setup uses AWS Bedrock for model inference, enabling local-first Claude Code execution.

!!! warning "Prerequisites: Shell Environment Required"
    Claude Code depends on a properly configured shell environment with git and GitHub working correctly. Before installing Claude Code, ensure your shell is set up properly. If you need help with shell configuration, SSH keys, or Git setup, see our **[Shell Setup Guide](../../shell/index.md)** for automated configuration.

## Setup

### 1. Configure AWS Credentials and Region

Add your AWS credentials to `~/.aws/credentials`:

```ini
[bedrock]
aws_access_key_id = XXXXXXXXXXX
aws_secret_access_key = YYYYYYYYYYYYYYYYY
```

Add the Bedrock profile to `~/.aws/config`:

```ini
[profile bedrock]
region = us-west-2
```

!!! tip "Use AWS CLI to configure credentials"
    You can use the AWS CLI to set up your credentials conveniently. See the [AWS documentation](../../clouds/aws/index.md) for detailed instructions on configuring AWS CLI.

### 2. Install Claude Code

Install Claude Code using the official binary installer:

```bash
curl -fsSL https://claude.ai/install.sh | bash -s latest
```

!!! note "Having issues?"
    If this installation doesn't work for some reason, see the [legacy npm-based installation](#alternative-npm-based-installation-legacy) at the end of this guide.

### 3. Install Claude Code Wrapper

Install the wrapper script that provides easy model switching and proper permission handling:

```bash
curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/claude-wrapper.sh?$(date +%s)" | bash
```

This wrapper script will:
- Automatically find your Claude Code installation
- Install itself to `~/bin/claude-wrapper.sh`
- Create a symlink `~/bin/claude` pointing to the wrapper
- Configure AWS Bedrock integration
- Enable easy model switching (haiku/sonnet/opus)
- Set appropriate permissions for the current directory

??? info "View script contents"
    ```bash linenums="1"
    --8<-- "scripts/claude-wrapper.sh"
    ```

### 4. Test Claude Code

Create a test project and launch Claude Code:

```bash
# Create a test directory
mkdir -p ~/test-project
cd ~/test-project
git init

# Launch Claude Code with default Haiku model
claude
```

!!! note "First Time Setup: Reload Shell if Needed"
    If `~/bin` was not already in your PATH before running the wrapper installation, you'll need to reload your shell first:

    ```bash
    . ~/.bashrc   # For Bash
    . ~/.zshrc    # For Zsh
    ```

    You can check if reload is needed by running: `echo $PATH | grep -q "$HOME/bin" && echo "Ready!" || echo "Please reload shell"`

When Claude Code launches for the first time, it will:
1. Ask for your SSH keychain passphrase (cached for 4 hours)
2. Initialize the Claude Code environment
3. Start the interactive session in the git repository

## Important: Git Repository Requirement

**Claude Code must always be initialized inside a git repository.** This is a requirement for the tool to function properly.

### Setting Up a Git Repository

You have two options:

#### Option 1: Create a Local Repository

```bash
mkdir my-project
cd my-project
git init
```

Then run Claude Code inside this directory:

```bash
claude
```

#### Option 2: Create a Repository on GitHub

1. Visit [github.com/new](https://github.com/new) to create a new repository
2. Clone it to your local machine using SSH:

```bash
git clone git@github.com:YOUR_USERNAME/my-project.git
cd my-project
```

!!! note "SSH vs HTTPS"
    This example uses SSH for secure authentication. SSH requires setting up an SSH key pair. See the [SSH setup guide](../../shell/ssh/index.md) for detailed instructions on generating and configuring SSH keys for GitHub.

3. Run Claude Code:

```bash
claude
```

## Model Comparison

Understanding the differences between the three available models helps you choose the right tool for each task:

| Aspect | Haiku | Sonnet | Opus |
|--------|-------|--------|------|
| **Speed** | ⚡ Fast | ⚡⚡ Medium | 🐌 Slow |
| **Cost** | 💰 $1.00/MTok | 💰💰 $3.00/MTok | 💰💰💰 $5.00/MTok |
| **Performance** | Excellent | Very Good | Superior |
| **Complex Tasks** | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐⭐ Excellent |
| **Coding Skills** | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐⭐ Excellent |

## Usage

### Default (Haiku - Fast)

Run Claude Code with the default fast Haiku model for quick fixes and simple tasks:

```bash
claude /path/to/project
```

**Best for:**
- Quick bug fixes
- Simple code generation
- Refactoring small sections
- Cost-conscious tasks

### Sonnet (Balanced)

Run with the balanced Sonnet model for most development work:

```bash
claude sonnet /path/to/project
```

**Best for:**
- Complex feature development
- Detailed code analysis
- Medium-complexity problems
- Good balance of speed and capability

### Opus (Most Capable)

Run with the most capable Opus model for challenging problems:

```bash
claude opus /path/to/project
```

**Best for:**
- Difficult architectural decisions
- Complex problem-solving
- Full-project analysis
- Maximum capability required

## Configuration Notes

- **Bedrock Integration**: Uses AWS Bedrock for model inference
- **Context Window**: Defaults to 1M context window for Sonnet
- **No Confirmation**: Configured to skip permission prompts for streamlined workflow
- **Model Selection**: Easy switching between Haiku (fast), Sonnet (balanced), and Opus (capable)

## Important Addon Tools

While Claude Code is powerful on its own, certain tools can dramatically improve its effectiveness when working with codebases. These tools enhance Claude's ability to search, understand, and navigate code.

### Enhanced Code Search with mgrep

Traditional `grep` searches line-by-line for text patterns, which limits Claude Code's ability to understand code structure and context. Modern search tools provide semantic understanding, multiline pattern matching, and structural analysis - leading to significantly better results when Claude analyzes your codebase.

The term "mgrep" (multiline grep) has become shorthand for these enhanced search capabilities that can deliver up to 250% better results compared to traditional text search. Read more about this approach in [this article on mgrep and Claude Code](https://medium.com/coding-nexus/me-and-claude-are-in-love-with-mgrep-for-250-better-results-6357351eaac0).

#### Recommended Search Tools

**1. ripgrep with Multiline Mode** - Fast and Practical

The quickest way to enhance Claude's code search is enabling multiline mode in ripgrep:

```bash
# Install ripgrep
sudo apt install ripgrep  # Ubuntu/Debian
brew install ripgrep      # macOS

# Create mgrep alias for multiline search
echo "alias mgrep='rg -U'" >> ~/.bashrc
source ~/.bashrc
```

Usage examples:
```bash
# Find function definitions spanning multiple lines
mgrep 'function.*\{[\s\S]*?return'

# Find class definitions with their methods
mgrep 'class \w+.*\{[\s\S]*?\}'

# Search with context lines
rg -C 3 'pattern'
```

**Why it helps Claude Code:**
- Search patterns spanning multiple lines (function definitions, class structures)
- Much faster than traditional grep on large codebases
- Respects `.gitignore` automatically, reducing noise from dependencies

**2. ast-grep** - Structural Code Search

For structural understanding of code patterns:

```bash
# Install via npm
npm install -g @ast-grep/cli

# Or via pip
pip install ast-grep-cli
```

Usage examples:
```bash
# Find all function calls with specific structure
ast-grep --pattern 'console.log($ARG)' --lang js

# Find and replace code patterns
ast-grep --pattern 'var $NAME = $VALUE' \
         --rewrite 'const $NAME = $VALUE' \
         --lang ts
```

**Why it helps Claude Code:**
- Understands code structure, not just text
- Identifies patterns based on Abstract Syntax Trees (AST)
- Reduces false positives in search results
- Excellent for refactoring and identifying deprecated patterns

**3. SeaGOAT** - Semantic Code Search (Advanced)

For semantic understanding using AI embeddings (fully local, privacy-safe):

```bash
# Requires Python 3.11+
pip install seagoat

# Start server for a repository
seagoat-server start /path/to/your/repo

# Search with natural language
gt "Where are the numbers rounded"
gt "Find authentication functions"
```

**Why it helps Claude Code:**
- Natural language queries instead of exact pattern matching
- Context-aware search based on code meaning
- Finds related functionality across the codebase
- All processing happens locally (privacy-safe)

#### Quick Setup for Enhanced Search

Add these aliases to your shell configuration:

```bash
# Add to ~/.bashrc or ~/.zshrc
cat >> ~/.bashrc <<'EOF'
# Enhanced search tools for Claude Code
alias mgrep='rg -U'           # Multiline grep
alias cgrep='ast-grep'        # Structural code search
alias sgrep='gt'              # Semantic search (requires SeaGOAT server)
EOF

source ~/.bashrc
```

#### When to Use Each Tool

| Tool | Best For | Example Use Case |
|------|----------|------------------|
| **ripgrep -U (mgrep)** | Multiline patterns | Finding function definitions, class structures |
| **ast-grep (cgrep)** | Structural patterns, refactoring | Identifying all uses of deprecated APIs |
| **SeaGOAT (sgrep)** | Semantic exploration | "Find where user permissions are checked" |

These tools help Claude Code provide more accurate analysis, better code suggestions, and faster navigation through your codebase.

## Secure Setup: Sandboxed Claude Code with Bubblewrap

For maximum security when working with sensitive projects, you can run Claude Code in an isolated sandbox using bubblewrap (bwrap). This approach protects your AWS credentials and SSH keys by:

- Limiting AWS credentials to only the Bedrock profile (not your entire credentials file)
- Making SSH keys available read-only for authentication without exposing private keys
- Creating temporary in-memory filesystems for sensitive data that are wiped when the session ends

### Prerequisites

Install bubblewrap on your system:

```bash
# Ubuntu/Debian
sudo apt-get install bubblewrap

# macOS (via Homebrew)
brew install bubblewrap

# Fedora/RHEL
sudo dnf install bubblewrap
```

### Setup Steps

**1. Extract Bedrock credentials to a separate file:**

```bash
grep -F -A 2 '[bedrock]' ~/.aws/credentials > ~/.aws/credentials.bedrock
```

This creates a minimal credentials file containing only your Bedrock profile.

**2. Run Claude Code in sandbox:**

```bash
bwrap \
  --bind / / \
  --tmpfs ~/.ssh \
  --bind ~/.ssh/known_hosts ~/.ssh/known_hosts \
  --bind ~/.ssh/config ~/.ssh/config \
  --tmpfs ~/.aws \
  --bind ~/.aws/credentials.bedrock ~/.aws/credentials \
  --bind ~/.aws/config ~/.aws/config \
  --dev /dev \
  --proc /proc \
  claude
```

### How It Works

- `--bind / /` - Bind the entire filesystem as read-only
- `--tmpfs ~/.ssh` - Create an in-memory temporary filesystem for SSH (sensitive keys stay in agent memory)
- `--bind ~/.ssh/known_hosts` - Mount only the known hosts file (no private keys)
- `--bind ~/.aws/credentials.bedrock ~/.aws/credentials` - Mount only Bedrock credentials, not your full credentials file
- `--tmpfs ~/.aws` - Create in-memory temporary filesystem for AWS config
- `--dev /dev --proc /proc` - Provide necessary system interfaces

### Security Benefits

✅ **Limited AWS Credentials** - Claude Code only sees the Bedrock profile, not other AWS account credentials
✅ **SSH Key Protection** - Private keys remain in ssh-agent; Claude Code only accesses known hosts
✅ **Temporary Storage** - Sensitive files exist only in RAM and are wiped when the sandbox exits
✅ **Filesystem Isolation** - Reduces risk of accidental credential leakage to untrusted projects

!!! note "Convenience vs Security Trade-off"
    This sandbox approach provides maximum security but requires more setup. For routine development with trusted projects, the standard setup is sufficient. Use sandboxing for sensitive work or unfamiliar codebases.

## Tips and Best Practices

- Use **Haiku** for quick fixes and simple tasks
- Use **Sonnet** for complex development and analysis
- Use **Opus** for challenging problems requiring maximum capability
- Ensure AWS credentials are properly configured before use
- The wrapper script automatically handles model selection and AWS environment setup

## Alternative: npm-based Installation (Legacy)

If the binary installer doesn't work or you prefer npm, follow these steps:

### Check and Install npm

Before installing Claude Code via npm, verify that npm is available and properly configured.

**Copy and paste this command into your terminal:**

```bash
curl -fsSL "https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/nodejs-install-check.sh?$(date +%s)" | bash
```

??? info "View script contents"
    ```bash linenums="1"
    --8<-- "scripts/nodejs-install-check.sh"
    ```

This script will:

- Check if npm is installed
- Attempt to load nodejs module (for HPC systems)
- Install nvm and Node.js 24 if needed
- Configure npm to install global packages in your home directory
- Set up the correct PATH configuration

### Install Claude Code via npm

Once npm is set up, install Claude Code globally:

```bash
npm i -g @anthropic-ai/claude-code
```

!!! note "Legacy Method"
    This is a fallback if the primary binary installation doesn't work for you.

## Next: Complete Project Development Workflow

Ready to develop a full project with Claude Code? Follow the **[Claude Code Tutorial](tutorial.md)** for the complete step-by-step workflow using the recommended Haiku → Sonnet → Opus escalation strategy.
