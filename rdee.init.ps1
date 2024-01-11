#Requires -Version 7

# >>>>>>>>>>>>>>>>>>>>>>>>>>> [prepare]
$myDir = $PSScriptRoot;
$GitReposDir = [IO.Path]::GetFullPath("$myDir/..")

$projs = "rdeeToolkit", "reSync"

# <<<


# >>>>>>>>>>>>>>>>>>>>>>>>>>> [init 1-by-1]
foreach ($p in $projs) {
    if (-not (Test-Path $GitReposDir\$p)) {
        Write-Error "No G::rdeeToolkit found, git clone first! (Manually now)" -ErrorAction Stop
    }
}
foreach ($p in $projs) {
    Write-Output "init $p"
    . $GitReposDir\$p\init\init.Windows.ps1
}
# <<<

