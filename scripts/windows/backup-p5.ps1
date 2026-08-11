[CmdletBinding()]
param(
    [string]$DistroName = 'p5-devops',
    [string]$Destination = 'D:\WSL-Backups',
    [switch]$NoRestart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

if (-not (Test-P5WslDistro -Name $DistroName)) {
    throw "Distribution '$DistroName' absente."
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = Join-Path $Destination "$DistroName-$stamp.vhdx"
$wasRunning = (Get-P5WslState -Distro $DistroName) -eq 'Running'

if ($wasRunning) {
    Write-Host "Arret propre de $DistroName avant export..."
    & wsl.exe --terminate $DistroName
    if ($LASTEXITCODE -ne 0) {
        throw "Impossible d'arreter '$DistroName'."
    }
    Start-Sleep -Seconds 2
}

Write-Host "Export VHDX : $backupPath"
& wsl.exe --export $DistroName $backupPath --vhd
if ($LASTEXITCODE -ne 0) {
    throw 'Export WSL en echec.'
}

if (-not (Test-Path -LiteralPath $backupPath)) {
    throw "Le fichier de sauvegarde n'a pas ete cree : $backupPath"
}

$file = Get-Item -LiteralPath $backupPath
if ($file.Length -le 0) {
    throw "Le VHDX cree est vide : $backupPath"
}

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $backupPath
$hashPath = "$backupPath.sha256"
"$($hash.Hash.ToLower())  $($file.Name)" | Set-Content -Encoding ascii -LiteralPath $hashPath

Write-Host "Sauvegarde OK : $backupPath"
Write-Host ('Taille        : {0:N2} GiB' -f ($file.Length / 1GB))
Write-Host "SHA-256       : $($hash.Hash)"

if ($wasRunning -and -not $NoRestart) {
    & wsl.exe -d $DistroName -- bash -lc 'true'
    if ($LASTEXITCODE -ne 0) {
        throw "Sauvegarde valide, mais relance de '$DistroName' en echec."
    }
    Write-Host "Distribution relancee : $DistroName"
}
