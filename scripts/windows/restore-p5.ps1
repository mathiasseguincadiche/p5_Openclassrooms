[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BackupPath,
    [string]$NewDistroName = 'p5-devops-restored',
    [string]$InstallLocation = 'D:\WSL\p5-devops-restored'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

if (-not (Test-Path -LiteralPath $BackupPath)) {
    throw "Sauvegarde introuvable : $BackupPath"
}
if ([IO.Path]::GetExtension($BackupPath) -ne '.vhdx') {
    throw 'La restauration P5 attend une sauvegarde .vhdx.'
}
if (Test-P5WslDistro -Name $NewDistroName) {
    throw "La distribution '$NewDistroName' existe deja. Aucun remplacement automatique n'est autorise."
}

$hashPath = "$BackupPath.sha256"
if (Test-Path -LiteralPath $hashPath) {
    $expected = ((Get-Content -LiteralPath $hashPath -Raw).Trim() -split '\s+')[0]
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $BackupPath).Hash.ToLower()
    if ($actual -ne $expected.ToLower()) {
        throw 'Le controle SHA-256 du VHDX a echoue. Restauration annulee.'
    }
    Write-Host 'SHA-256 du VHDX : OK'
} else {
    Write-Warning 'Aucun fichier .sha256 associe : integrite non verifiee.'
}

if (Test-Path -LiteralPath $InstallLocation) {
    if (Get-ChildItem -LiteralPath $InstallLocation -Force | Select-Object -First 1) {
        throw "Le dossier d'installation n'est pas vide : $InstallLocation"
    }
} else {
    New-Item -ItemType Directory -Path $InstallLocation -Force | Out-Null
}

Write-Host "Import de $BackupPath sous le nom $NewDistroName..."
& wsl.exe --import $NewDistroName $InstallLocation $BackupPath --vhd --version 2
if ($LASTEXITCODE -ne 0) {
    throw 'Import WSL en echec.'
}

& wsl.exe -d $NewDistroName -- bash -lc 'true'
if ($LASTEXITCODE -ne 0) {
    throw "Import termine, mais premier demarrage de '$NewDistroName' en echec."
}

Write-Host "Restauration OK : $NewDistroName"
Write-Host "Emplacement     : $InstallLocation"
Write-Host "Connexion       : wsl -d $NewDistroName"
Write-Host ''
Write-Host 'La distribution d'origine n'a pas ete modifiee.'
