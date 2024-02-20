#!/bin/pwsh



#@ hint Ignore condition that user runs sshd standalone

if ($IsLinux) {
    if ($(bash -c "[[ -w /etc ]] && echo 1 || echo 0") -eq "0") {
        Write-Host "`e[31m Error! `e[0m Require sudo authority when deploying sshd_config"
        exit 200
    }
    if (-not(Test-Path "/etc/ssh/sshd_config.ori")) {
        Copy-Item -Path "/etc/ssh/sshd_config" -Destination "/etc/ssh/sshd_config.ori"
    }
    Get-Content -Path "/etc/ssh/sshd_config" | ForEach-Object {
        if ($_.Contains("Port ")) {
            return "Port 2222"
        }
        elseif ($_.Contains("ListenAddress 0.0.0.0")) {
            return "ListenAddress 0.0.0.0"
        }
        else {
            return $_
        }
    } |  Set-Content -Path "/etc/ssh/sshd_config"

    #@ wsl
    if ($null -eq $env:WSL_DISTRO_NAME) {
        Write-Host "Update ssh_config, But there remains some windows operation for WSL-sshd, please `e[32m run `e[0m the `e[33m post.WSL-sshd-in-win.ps1`e[0m"
    }
}

