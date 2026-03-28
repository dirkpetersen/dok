#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up a WSL2 Ubuntu dev environment with kanna-code.

.DESCRIPTION
    Idempotent script that:
    1. Installs WSL (if not present)
    2. Installs Windows Terminal (if not present)
    3. Installs Ubuntu in WSL2 with default user "claude"
    4. Runs dev-station-install.sh inside Ubuntu
    5. Installs Bun and kanna-code
    6. Launches kanna

.NOTES
    Run from PowerShell:
        Set-ExecutionPolicy Bypass -Scope Process -Force
        .\setup-wsl-claude-kanna.ps1
#>

# --- Self-elevate if not running as Administrator ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Not running as Administrator. Attempting to elevate..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList (
            "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
        )
    } catch {
        Write-Host @"

ERROR: This script requires Administrator privileges.
Please run PowerShell as Administrator and execute:

    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\setup-wsl-claude-kanna.ps1

"@ -ForegroundColor Red
    }
    exit
}

Write-Host "=== WSL + Claude + Kanna Setup ===" -ForegroundColor Cyan

# --- Step 1: Install WSL ---
Write-Host "`n[1/6] Checking WSL..." -ForegroundColor Green
$wslInstalled = Get-Command wsl.exe -ErrorAction SilentlyContinue
if ($wslInstalled) {
    Write-Host "WSL is already installed. Skipping." -ForegroundColor Gray
} else {
    Write-Host "Installing WSL..."
    wsl --install --no-distribution
    Write-Host "WSL installed. A reboot may be required. Re-run this script after reboot." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

# --- Step 2: Install Windows Terminal ---
Write-Host "`n[2/6] Checking Windows Terminal..." -ForegroundColor Green
$wtInstalled = Get-Command wt.exe -ErrorAction SilentlyContinue
if (-not $wtInstalled) {
    # Also check via AppxPackage
    $wtPackage = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
    if ($wtPackage) {
        $wtInstalled = $true
    }
}
if ($wtInstalled) {
    Write-Host "Windows Terminal is already installed. Skipping." -ForegroundColor Gray
} else {
    Write-Host "Installing Windows Terminal via winget..."
    winget install --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "winget install failed. Trying Microsoft Store method..." -ForegroundColor Yellow
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.WindowsTerminal_8wekyb3d8bbwe
    }
    Write-Host "Windows Terminal installed." -ForegroundColor Gray
}

# --- Step 3: Install Ubuntu in WSL2 ---
Write-Host "`n[3/6] Checking Ubuntu in WSL..." -ForegroundColor Green
$distros = wsl -l -q 2>$null | Where-Object { $_ -match "Ubuntu" }
if ($distros) {
    Write-Host "Ubuntu is already installed in WSL. Skipping." -ForegroundColor Gray
} else {
    Write-Host "Installing Ubuntu..."
    wsl --install -d Ubuntu
    Write-Host "Ubuntu installed. Setting up default user 'claude'..."
    # Set default user to claude with no password
    wsl -d Ubuntu -- bash -c "
        if ! id claude &>/dev/null; then
            useradd -m -s /bin/bash -G sudo claude
            passwd -d claude
            echo 'claude ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/claude
        fi
    "
    # Set claude as the default user for this distro
    wsl -d Ubuntu -- bash -c "
        echo -e '[user]\ndefault=claude' > /etc/wsl.conf
    "
    # Restart the distro to apply the default user
    wsl --terminate Ubuntu
    Write-Host "Ubuntu configured with default user 'claude'." -ForegroundColor Gray
}

# --- Step 4: Run dev-station-install.sh ---
Write-Host "`n[4/6] Checking dev-station..." -ForegroundColor Green
wsl -d Ubuntu -u claude -- bash -c "
    if [ -f ~/.dev-station-installed ]; then
        echo 'dev-station already installed. Skipping.'
        exit 0
    fi
    echo 'Installing dev-station...'
    curl -fsSL 'https://raw.githubusercontent.com/dirkpetersen/dok/main/scripts/dev-station-install.sh' | bash
    touch ~/.dev-station-installed
"

# --- Step 5: Install Bun and kanna-code ---
Write-Host "`n[5/6] Checking Bun and kanna-code..." -ForegroundColor Green
wsl -d Ubuntu -u claude -- bash -c "
    export HOME=/home/claude
    # Install Bun if not present
    if ! command -v bun &>/dev/null && [ ! -f ~/.bun/bin/bun ]; then
        echo 'Installing Bun...'
        curl -fsSL https://bun.sh/install | bash
    else
        echo 'Bun already installed. Skipping.'
    fi
    # Source bun into PATH
    source ~/.bashrc 2>/dev/null || true
    export PATH=\"\$HOME/.bun/bin:\$PATH\"
    # Install kanna-code if not present
    if ! command -v kanna &>/dev/null; then
        echo 'Installing kanna-code...'
        bun install -g kanna-code
    else
        echo 'kanna-code already installed. Skipping.'
    fi
"

# --- Step 6: Launch kanna ---
Write-Host "`n[6/6] Launching kanna..." -ForegroundColor Green
wsl -d Ubuntu -u claude -- bash -c "
    source ~/.bashrc 2>/dev/null || true
    export PATH=\"\$HOME/.bun/bin:\$PATH\"
    kanna
"

Write-Host "`nSetup complete!" -ForegroundColor Cyan
