

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


$ExistingPort = 2222
$NewPort = 2222

if ((wsl.exe -e bash -c "ifconfig eth0 | grep 'inet '") -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}') {
    $WslIp = $matches[0]

    netsh advfirewall firewall show rule name='WSL2-sshd-forwarding' | Out-Null
    if (-not $?) {
        netsh advfirewall firewall add rule name='WSL2-sshd-forwarding' dir=in action=allow protocol=TCP localport=2222
    }

    Write-Output "Delete old portproxy:"
    Write-Output "`tlistenaddress=0.0.0.0"
    Write-Output "`tlistenport=$ExistingPort"
    Invoke-Expression "netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$ExistingPort"

    Write-Output ""
    Write-Output "Add new portproxy:"
    Write-Output "`tlistenaddress=0.0.0.0"
    Write-Output "`tlistenport=$NewPort"
    Write-Output "`tconnectaddress=$WslIp"
    Write-Output "`tconnectport=$NewPort"
    Invoke-Expression "netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$NewPort connectaddress=$WslIp connectport=$NewPort"
}
else {
    Write-Host "`e[31m Error! `e[0m Cannot retrieve the WSL ip address from wsl.exe."
    exit 200
}

Read-Host "Press Enter to quit."
