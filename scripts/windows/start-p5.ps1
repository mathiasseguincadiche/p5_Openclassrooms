[CmdletBinding()]
param([string]$DistroName = 'p5-devops')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

if (-not (Test-P5WslDistro -Name $DistroName)) {
    throw "Distribution '$DistroName' absente."
}

& wsl.exe -d $DistroName -- bash -lc 'true'
if ($LASTEXITCODE -ne 0) {
    throw "Demarrage de '$DistroName' en echec."
}

$ip = (Invoke-P5Wsl -Distro $DistroName -Command 'hostname -I | tr " " "\n" | head -n 1' | Select-Object -First 1).Trim()
Write-Host "P5 demarre : $DistroName"
Write-Host "IPv4 WSL    : $ip"
Write-Host "Connexion   : wsl -d $DistroName"
