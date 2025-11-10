# GitHub

Essential setup and configuration for working with GitHub repositories.

## SSH Key Setup

SSH key generation and keychain management are covered in the [Shell](../../shell/index.md) section. Follow that guide first to:

1. Generate your SSH key with a passphrase
2. Configure SSH permissions
3. Set up SSH keychain to cache your passphrase

After completing the Shell setup, come back here to push your key to GitHub.

## Add SSH Key to GitHub

### Option 1: Quick Setup with GitHub CLI (Recommended)

The fastest way to add your SSH key to GitHub is using the GitHub CLI:

1. **Install GitHub CLI**

```bash
# On Ubuntu/WSL
sudo apt-get update
sudo apt-get install gh

# On macOS
brew install gh

# Or download from https://github.com/cli/cli/releases
```

2. **Authenticate with GitHub**

```bash
gh auth login
```

Follow the prompts:
- Select "GitHub.com"
- Select "SSH" for git protocol
- Use your existing SSH key
- Authorize GitHub CLI to manage SSH keys

3. **Automatic SSH key upload**

GitHub CLI will automatically detect your SSH key and upload it to your GitHub account during `gh auth login`.

4. **Verify setup**

```bash
gh auth status
```

You should see confirmation of your authenticated account.

### Option 2: Manual GitHub Web Interface

If you prefer the web interface:

1. Display your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

2. Copy the entire output

3. Go to GitHub Settings → SSH and GPG keys → [New SSH key](https://github.com/settings/ssh/new)

4. Paste your public key and give it a descriptive title (e.g., "My Laptop")

5. Click "Add SSH key"

## Test SSH Connection

Verify your SSH setup works with GitHub:

```bash
ssh -T git@github.com
```

You should see:

```
Hi YOUR_USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```

## Basic Git Workflow

### Clone a Repository

```bash
git clone git@github.com:USERNAME/repository.git
cd repository
```

### Create and Switch Branches

```bash
git checkout -b feature/my-feature
```

### Make Changes and Commit

```bash
git add .
git commit -m "Describe your changes"
```

### Push to GitHub

```bash
git push origin feature/my-feature
```

### Create a Pull Request

After pushing, visit your repository on GitHub and create a pull request to merge your branch.

## Cloning Your First Repository

Your first GitHub repository can be cloned locally:

```bash
git clone git@github.com:YOUR_USERNAME/your-repo.git
cd your-repo
```

Then you can run Claude Code inside:

```bash
claude .
```
