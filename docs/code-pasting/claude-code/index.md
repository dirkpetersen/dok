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

## Important Addon Tools for Enhanced Code Search

While Claude Code has built-in code search capabilities, these addon tools can significantly improve your development workflow by providing semantic and structural code search that goes beyond simple text matching.

### mgrep: Semantic Code Search

[mgrep](https://www.npmjs.com/package/@mixedbread-ai/mgrep) is a semantic code search tool that understands code meaning rather than just matching text patterns. According to [this analysis](https://medium.com/coding-nexus/me-and-claude-are-in-love-with-mgrep-for-250-better-results-6357351eaac0), mgrep can provide dramatically better search results by understanding code semantics and context.

**Key Benefits:**

- **Semantic Understanding**: Finds code by meaning, not just keywords
- **Better Claude Code Integration**: Provides more relevant context to Claude Code's AI models
- **Cross-Language Support**: Works across multiple programming languages
- **Improved Accuracy**: Reduces false positives compared to regex-based search

**Installation:**

```bash
npm install -g @mixedbread-ai/mgrep
```

**Basic Usage:**

```bash
# Search for code related to authentication
mgrep "user authentication logic"

# Search in specific directory
mgrep "database connection" ./src
```

### ripgrep: Lightning-Fast Text Search

[ripgrep (rg)](https://github.com/BurntSushi/ripgrep) is an extremely fast command-line search tool that recursively searches directories for regex patterns. It's faster than grep, ag, and ack, with smart defaults like respecting `.gitignore` files.

**Installation:**

```bash
# Ubuntu/Debian
sudo apt-get install ripgrep

# Fedora/RHEL
sudo dnf install ripgrep

# macOS
brew install ripgrep
```

**Basic Usage:**

```bash
# Search for a pattern in current directory
rg "function.*authenticate"

# Search with context lines
rg -C 3 "TODO"

# Search specific file types
rg -t py "import.*requests"
```

### ast-grep: Structural Code Search

[ast-grep (sg)](https://ast-grep.github.io/) searches code based on Abstract Syntax Tree (AST) patterns, making it perfect for finding structural patterns regardless of formatting or variable names.

**Key Benefits:**

- **Structural Matching**: Find code patterns by structure, not just text
- **Language-Aware**: Understands syntax of different programming languages
- **Refactoring Support**: Great for finding code patterns to refactor
- **No Login Required**: Completely open-source and local

**Installation:**

```bash
# Using cargo (Rust package manager)
cargo install ast-grep

# Or download pre-built binary from releases
curl -L https://github.com/ast-grep/ast-grep/releases/latest/download/ast-grep-x86_64-unknown-linux-gnu.zip -o ast-grep.zip
unzip ast-grep.zip
sudo mv sg /usr/local/bin/
```

**Basic Usage:**

```bash
# Find all function definitions
sg --pattern 'function $NAME($$$) { $$$ }'

# Find specific React patterns
sg --pattern 'useState($$$)' -l tsx
```

### Choosing the Right Tool

- **Use mgrep** when you need semantic understanding and want to find code by meaning
- **Use ripgrep** for fast text-based searches with regex patterns
- **Use ast-grep** when searching for structural code patterns or doing refactoring

These tools complement each other and can be used together to provide comprehensive code search capabilities for Claude Code workflows.

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
