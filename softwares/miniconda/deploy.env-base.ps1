#!/bin/pwsh

if ($env:CONDA_DEFAULT_ENV -ne "base") {
    Write-Host "Not in base conda environment, stop"
    exit 200
}

$packagelist = @"
numpy
pandas
ipython
jupyter
matplotlib
"@

$packagelist | Set-Content -Path "requirements.txt"

conda install --file requirements.txt

Remove-Item requirements.txt
