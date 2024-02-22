

#@ reference https://gist.github.com/estsaon/b27452c3ba105c369a5d7c9b1f10c6e7

#@ prepare
#@ .check-windows
if ($PSVersionTable.PSEdition -eq "Core" -and -not $IsWindows) {
    Write-Host "`e[31m Error! `e[0m This script can only be run in Windows."
    Read-Host "Press Enter to quit."
    exit 200
}
#@ .check-admin
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch as an elevated process:
    Start-Process powershell.exe "-ExecutionPolicy", "bypass", "-File", ('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}


#@ core
# Install the OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Install the OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
if (-not $?) {
    Read-Host "Press Enter to quit."
    exit 200
}

# Start the sshd service
Start-Service sshd

# OPTIONAL but recommended:
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "WIN-sshd" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'WIN-sshd' does not exist, creating it..."
    New-NetFirewallRule -Name 'WIN-sshd' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
else {
    Write-Output "Firewall rule 'WIN-sshd' has been created and exists."
}


Read-Host "Press Enter to quit."
