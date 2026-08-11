[CmdletBinding()]
param([string]$DistroName = 'p5-devops')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

if (-not (Test-P5WslDistro -Name $DistroName)) {
    throw "Distribution '$DistroName' absente."
}

$state = Get-P5WslState -Distro $DistroName
if ($state -eq 'Stopped') {
    Write-Host "P5 deja arrete : $DistroName"
    exit 0
}

& wsl.exe --terminate $DistroName
if ($LASTEXITCODE -ne 0) {
    throw "Arret de '$DistroName' en echec."
}

Write-Host "P5 arrete : $DistroName"
Write-Host 'Les donnees de la distribution sont conservees.'
