[CmdletBinding()]
param(
    [string]$DistroName = 'p5-devops',
    [string]$UbuntuDistribution = 'Ubuntu-26.04'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

Assert-P5Windows11
Assert-WslCommand

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$wslConfigSource = Join-Path $projectRoot 'environment\wsl2\.wslconfig.example'
$wslConfigTarget = Join-Path $env:USERPROFILE '.wslconfig'

if (-not (Test-Path $wslConfigSource)) {
    throw "Modele WSL introuvable : $wslConfigSource"
}

Write-Host 'Mise a jour de WSL...'
& wsl.exe --update
if ($LASTEXITCODE -ne 0) {
    throw 'La mise a jour de WSL a echoue.'
}

& wsl.exe --set-default-version 2
if ($LASTEXITCODE -ne 0) {
    throw 'Impossible de definir WSL2 comme version par defaut.'
}

$desiredConfig = Get-Content -Raw -LiteralPath $wslConfigSource
$currentConfig = if (Test-Path $wslConfigTarget) {
    Get-Content -Raw -LiteralPath $wslConfigTarget
} else {
    $null
}

if ($currentConfig -ne $desiredConfig) {
    if (Test-Path $wslConfigTarget) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backup = "$wslConfigTarget.$stamp.bak"
        Copy-Item -LiteralPath $wslConfigTarget -Destination $backup
        Write-Host "Ancien .wslconfig sauvegarde : $backup"
    }
    Copy-Item -LiteralPath $wslConfigSource -Destination $wslConfigTarget -Force
    Write-Host "Configuration WSL appliquee : $wslConfigTarget"
} else {
    Write-Host '.wslconfig deja conforme.'
}

if (Test-P5WslDistro -Name $DistroName) {
    Write-Host "Distribution '$DistroName' deja presente : installation ignoree."
} else {
    $online = (& wsl.exe --list --online | Out-String)
    if ($LASTEXITCODE -ne 0 -or $online -notmatch ('(?m)^\s*' + [regex]::Escape($UbuntuDistribution) + '\s')) {
        throw "La distribution '$UbuntuDistribution' n'apparait pas dans 'wsl --list --online'. Mettez WSL a jour puis relancez."
    }

    Write-Host "Installation de $UbuntuDistribution sous le nom $DistroName..."
    & wsl.exe --install -d $UbuntuDistribution --name $DistroName --no-launch
    if ($LASTEXITCODE -ne 0) {
        throw 'Installation de la distribution WSL en echec.'
    }
}

& wsl.exe --shutdown

Write-Host ''
Write-Host 'Installation Windows/WSL2 terminee.'
Write-Host "1. Lancez une fois : wsl -d $DistroName"
Write-Host '2. Terminez la creation de votre utilisateur Ubuntu.'
Write-Host '3. Revenez sous PowerShell et lancez :'
Write-Host '   .\scripts\windows\configure-wsl2-p5.ps1'
