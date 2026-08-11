[CmdletBinding()]
param([string]$DistroName = 'p5-devops')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

if (-not (Test-P5WslDistro -Name $DistroName)) {
    Write-Host "Distribution : $DistroName"
    Write-Host 'Etat         : ABSENTE'
    exit 1
}

$state = Get-P5WslState -Distro $DistroName
Write-Host "Distribution : $DistroName"
Write-Host "Etat         : $state"

if ($state -eq 'Running') {
    $ip = (Invoke-P5Wsl -Distro $DistroName -Command 'hostname -I | tr " " "\n" | head -n 1' | Select-Object -First 1).Trim()
    $cpu = (Invoke-P5Wsl -Distro $DistroName -Command 'nproc' | Select-Object -First 1).Trim()
    $mem = (Invoke-P5Wsl -Distro $DistroName -Command 'free -h | awk ''/^Mem:/ {print $2}''' | Select-Object -First 1).Trim()
    $pid1 = (Invoke-P5Wsl -Distro $DistroName -Command 'ps -p 1 -o comm=' | Select-Object -First 1).Trim()
    Write-Host "IPv4 WSL     : $ip"
    Write-Host "CPU          : $cpu"
    Write-Host "RAM          : $mem"
    Write-Host "PID 1        : $pid1"
}
