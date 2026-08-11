[CmdletBinding()]
param(
    [string]$DistroName = 'p5-devops',
    [switch]$RequireTools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib-wsl2-p5.ps1')

$errors = 0

function Check-Value {
    param([bool]$Condition, [string]$OkMessage, [string]$KoMessage)
    if ($Condition) {
        Write-P5Result -Level OK -Message $OkMessage
    } else {
        Write-P5Result -Level KO -Message $KoMessage
        $script:errors++
    }
}

Assert-P5Windows11
Assert-WslCommand

Write-Host 'P5 WSL2 STATUS'
Write-Host '==============='

Check-Value (Test-P5WslDistro -Name $DistroName) "distribution $DistroName presente" "distribution $DistroName absente"
if ($errors -gt 0) { exit 1 }

$kernel = (Invoke-P5Wsl -Distro $DistroName -Command 'uname -r' | Select-Object -First 1).Trim()
$cpu = [int]((Invoke-P5Wsl -Distro $DistroName -Command 'nproc' | Select-Object -First 1).Trim())
$memoryMiB = [int]((Invoke-P5Wsl -Distro $DistroName -Command "awk '/MemTotal:/ {printf \"%.0f\", `$2/1024}' /proc/meminfo" | Select-Object -First 1).Trim())
$pid1 = (Invoke-P5Wsl -Distro $DistroName -Command 'ps -p 1 -o comm=' | Select-Object -First 1).Trim()
$hostname = (Invoke-P5Wsl -Distro $DistroName -Command 'hostname' | Select-Object -First 1).Trim()
$ip = (Invoke-P5Wsl -Distro $DistroName -Command "hostname -I | awk '{print `$1}'" | Select-Object -First 1).Trim()
$gateway = (Invoke-P5Wsl -Distro $DistroName -Command "ip route show default | awk '{print `$3; exit}'" | Select-Object -First 1).Trim()
$route = (Invoke-P5Wsl -Distro $DistroName -Command 'ip route show default' | Select-Object -First 1).Trim()

Check-Value ($kernel -match '(?i)microsoft.*WSL2|WSL2.*microsoft') "noyau WSL2 : $kernel" "noyau WSL2 non confirme : $kernel"
Check-Value ($cpu -ge 6) "CPU disponibles : $cpu (cible >= 6)" "CPU insuffisants : $cpu (cible >= 6)"
Check-Value ($memoryMiB -ge 15000) "RAM disponible : $memoryMiB MiB (cible 16 Go)" "RAM insuffisante : $memoryMiB MiB (cible 16 Go)"
Check-Value ($pid1 -eq 'systemd') 'systemd actif en PID 1' "systemd inactif (PID 1 : $pid1)"
Check-Value ($hostname -eq 'p5-devops') "hostname : $hostname" "hostname inattendu : $hostname"
Check-Value ([bool]$ip) "IPv4 WSL detectee : $ip" 'adresse IPv4 WSL introuvable'
Check-Value ([bool]$gateway) "passerelle WSL detectee : $gateway" 'passerelle WSL introuvable'
Check-Value ([bool]$route) "route par defaut : $route" 'route par defaut absente'

$dnsOk = $false
try {
    Invoke-P5Wsl -Distro $DistroName -Command 'getent ahostsv4 github.com >/dev/null' | Out-Null
    $dnsOk = $true
} catch {}
Check-Value $dnsOk 'resolution DNS : OK' 'resolution DNS : KO'

$internetOk = $false
try {
    Invoke-P5Wsl -Distro $DistroName -Command 'curl -fsSIL --max-time 10 https://github.com >/dev/null' | Out-Null
    $internetOk = $true
} catch {}
Check-Value $internetOk 'sortie HTTPS : OK' 'sortie HTTPS : KO'

Write-Host ''
Write-Host 'Outils DevOps'
$toolFailures = 0
foreach ($tool in @('git','python3','terraform','ansible-playbook','aws','docker','node','npm')) {
    $present = $true
    try {
        Invoke-P5Wsl -Distro $DistroName -Command "command -v $tool >/dev/null" | Out-Null
    } catch {
        $present = $false
    }
    if ($present) {
        Write-P5Result -Level OK -Message $tool
    } elseif ($RequireTools) {
        Write-P5Result -Level KO -Message "$tool absent"
        $toolFailures++
    } else {
        Write-P5Result -Level INFO -Message "$tool absent (bootstrap P5 a executer)"
    }
}

$errors += $toolFailures
Write-Host ''
if ($errors -eq 0) {
    Write-Host 'Verdict : P5 WSL2 READY'
    exit 0
}

Write-Host "Verdict : P5 WSL2 NON CONFORME ($errors anomalie(s))"
exit 1
