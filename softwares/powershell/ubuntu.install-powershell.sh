#!/bin/bash

# modified from https://learn.microsoft.com/zh-cn/powershell/scripting/install/install-ubuntu?view=powershell-7.4

###################################
# Prerequisites

# Update the list of packages
sudo apt-get update

# Install pre-requisite packages.
sudo apt-get install -y wget

# Download the PowerShell package file
fn=powershell_7.4.1-1.deb_amd64.deb
if [[ ! -e $fn ]]; then
    wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/$fn
fi

###################################
# Install the PowerShell package
sudo dpkg -i $fn

# Resolve missing dependencies and finish the install (if necessary)
sudo apt-get install -f

# Delete the downloaded package file
rm $fn
# rm powershell_7.4.1-1.deb_amd64.deb

# Start PowerShell Preview
# pwsh-lts