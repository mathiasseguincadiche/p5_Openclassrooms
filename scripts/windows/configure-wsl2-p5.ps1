[CmdletBinding()]
param(
    [string]$DistroName = 'p5-devops',
    [string]$Hostname = 'p5-devops'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

Assert-P5Windows11
Assert-WslCommand

if (-not (Test-P5WslDistro -Name $DistroName)) {
    throw "Distribution '$DistroName' absente. Lancez d'abord install-wsl2-p5.ps1."
}

$linuxUser = (Invoke-P5Wsl -Distro $DistroName -Command 'id -un' | Select-Object -First 1).Trim()
if (-not $linuxUser -or $linuxUser -eq 'root') {
    throw "Aucun utilisateur Ubuntu standard detecte. Lancez d'abord 'wsl -d $DistroName' et terminez la creation de l'utilisateur."
}

$wslConf = @"
[boot]
systemd=true

[network]
hostname=$Hostname
generateHosts=true
generateResolvConf=true

[user]
default=$linuxUser
"@

$bytes = [Text.Encoding]::UTF8.GetBytes($wslConf)
$base64 = [Convert]::ToBase64String($bytes)
Invoke-P5Wsl -Distro $DistroName -User root -Command "printf '%s' '$base64' | base64 -d > /etc/wsl.conf && chmod 0644 /etc/wsl.conf" | Out-Null

& wsl.exe --set-default $DistroName
if ($LASTEXITCODE -ne 0) {
    throw "Impossible de definir '$DistroName' comme distribution WSL par defaut."
}

& wsl.exe --terminate $DistroName
if ($LASTEXITCODE -ne 0) {
    throw "Impossible d'arreter '$DistroName' pour appliquer /etc/wsl.conf."
}

Start-Sleep -Seconds 2
& wsl.exe -d $DistroName -- bash -lc 'true'
if ($LASTEXITCODE -ne 0) {
    throw "Impossible de relancer '$DistroName'."
}

$pid1 = (Invoke-P5Wsl -Distro $DistroName -Command 'ps -p 1 -o comm=' | Select-Object -First 1).Trim()
if ($pid1 -ne 'systemd') {
    throw "systemd n'est pas PID 1 apres redemarrage (detecte : $pid1)."
}

Write-Host "Distribution : $DistroName"
Write-Host "Utilisateur  : $linuxUser"
Write-Host "Hostname     : $Hostname"
Write-Host 'systemd      : OK'
Write-Host ''
Write-Host 'Configuration WSL2 P5 appliquee. Lancez maintenant :'
Write-Host '  .\scripts\windows\check-wsl2-p5.ps1'
