# Shell - SSH Configuration

**SSH key management, keychain setup, and connection optimization.** 

Secure shell access is critical for development work. This section covers SSH setup with password-protected keys and keychain integration.

## Generating SSH Keys

The frist step is to create an SSH key which is essential for many workflows, e.g. GitHub. You should always use a passphrase for security. When generating keys, use a strong password that you can remember:

```bash
ssh-keygen -t ed25519
```

or better 

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
```

**Important**: When prompted for a passphrase, enter a strong password. This protects your key if it's ever compromised.

## Configure SSH Keychain / Key agent 

Use SSH keychain to securely store your SSH key passphrase in memory, eliminating the need to re-enter it for every SSH command. Install keychain this way

**On Ubuntu/WSL:**

```bash
sudo apt-get install keychain
```

**On macOS / RHEL flavours**

```bash
curl -s https://raw.githubusercontent.com/danielrobbins/keychain/refs/heads/master/keychain.sh -o ~/bin/keychain
chmod +x ~/bin/keychain
```

Then add to one of login shell configuration files (`~/.profile` or `~/.bash_profile` or `~/.zprofile`, but not `~/.bashrc` or `~/.zshrc`):

```bash
# SSH Keychain - loads SSH key passphrase into memory
# Only run on interactive login shells (not in Slurm jobs)
[ -z $SLURM_PTY_PORT ] && eval $(keychain --quiet --eval id_ed25519)
```

!!! tip "Why use login shell config files?"
    The keychain setup should be in `~/.profile`, `~/.bash_profile`, or `~/.zprofile` (not `~/.bashrc` or `~/.zshrc`) because:

    - **Login shell files** run only on login shells (when you first log in)
    - **Interactive shell files** (`.bashrc`, `.zshrc`) run on every shell invocation, including non-interactive ones
    - This prevents redundant keychain initialization and improves shell startup performance

!!! pro-tip "HPC Systems: Slurm Compatibility"
    The `[ -z $SLURM_PTY_PORT ]` check is critical for HPC users:

    - **What it does**: Prevents keychain from running inside Slurm job steps
    - **Why**: Slurm manages PTY (pseudo-terminal) resources for job steps, and keychain interferes with this
    - **Result**: Your keychain works on login nodes but correctly disables within compute job allocations

    Without this check, keychain initialization can cause issues or hangs when running jobs on Slurm clusters.

**How It Works**

1. On your first SSH/Git command after login, you'll be prompted for your SSH key passphrase
2. Enter your password - it's stored securely in your system keychain
3. The passphrase persists in the keychain **until you reboot your computer**
4. All subsequent SSH connections reuse the cached passphrase without prompting
5. After reboot, you'll be prompted for your passphrase again on first use

This approach provides both security (your key is protected with a passphrase) and exceptional convenience (you only type your passphrase once per boot, not per session).

## SSH Configuration for Jump Hosts

**Note: You only need Jumphosts if you do not use VPN.** 

If you are using an ssh bastion or jump host in an enterprise/university environment, there are often no ssh keys allowed because of MFA autehntication needs. In that case you need to use the SSH controlmaster option if you do not want to enter your password all the time.

Create or edit `~/.ssh/config` to simplify SSH connections and optimize performance:

```bash
# SSH Connection Multiplexing and Global Defaults
Host *
    ControlPath ~/.ssh/controlmasters/%r@%h:%p
    ControlMaster auto
    ControlPersist 10m
    ServerAliveInterval 10
    ServerAliveCountMax 3
    User your-username

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes

# Jump Host Example
Host jumphost
    HostName jump.example.com
    ControlMaster auto
    DynamicForward 1080

# Remote Server Behind Jump Host
Host remote-server
    HostName server.example.com
    ProxyJump jumphost
```

**Key Configuration Options:**

- `ControlPath`: Directory for multiplexed connections (creates `.ssh/controlmasters/` dir)
- `ControlMaster auto`: Automatically reuse connections
- `ControlPersist 10m`: Keep connections alive for 10 minutes
- `ServerAliveInterval 10`: Send keepalive every 10 seconds
- `ServerAliveCountMax 3`: Disconnect after 3 missed keepalives
- `ProxyJump`: Chain connections through jump host
- `DynamicForward`: Enable SOCKS proxy through host

**Setup multiplexing directory:**

```bash
mkdir -p ~/.ssh/controlmasters
chmod 700 ~/.ssh/controlmasters
```

**Benefits:**

- **Faster connections**: Reuses SSH connections, eliminates repeated authentication
- **Reliable**: Keepalive prevents timeouts on idle connections
- **Secure**: Jump host proxy keeps direct connections private
- **Flexible**: Works with any remote host configuration

## Troubleshooting

### SSH Key Permissions

Ensure proper permissions on your SSH keys - incorrect permissions can prevent SSH authentication:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Explanation:**
- `~/.ssh` directory: `700` (rwx------) - only owner can access
- Private key: `600` (rw-------) - only owner can read/write
- Public key: `644` (rw-r--r--) - readable by others, writable only by owner

### Keychain Not Working

If prompted repeatedly for your passphrase:

```bash
# Check if ssh-agent is running
ps aux | grep ssh-agent

# Manually start ssh-agent
eval $(ssh-agent -s)

# Add key manually
ssh-add ~/.ssh/id_ed25519
```

### SSH Connection Issues

- Test connections with `ssh -v` for verbose debugging
- Check SSH config syntax: `ssh -T git@github.com`
- Verify remote host is accepting your key
- Ensure firewall isn't blocking port 22

## SSH Security Best Practices

### Keep SSH Keys Secure

- Never commit SSH keys to version control
- Never share your private key
- Always use strong passphrases
- Rotate keys periodically
- Use key files only for automated systems

### SSH Agent Security

- Let keychain manage your passphrase
- Don't store unencrypted passphrases
- Lock your computer when stepping away

### SSH Connection Best Practices

- Use SSH keys instead of passwords
- Keep SSH config clean and organized
- Monitor SSH access logs regularly
- Disable root login on remote servers
