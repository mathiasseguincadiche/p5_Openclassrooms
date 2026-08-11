Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-P5Windows11 {
    $os = Get-CimInstance Win32_OperatingSystem
    if ($os.Caption -notmatch 'Windows 11') {
        throw "Windows 11 est requis. Systeme detecte : $($os.Caption)"
    }
}

function Assert-P5Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw 'Ce script doit etre lance depuis PowerShell en tant qu administrateur.'
    }
}

function Assert-WslCommand {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        throw 'wsl.exe est introuvable. Activez WSL avant de poursuivre.'
    }
}

function ConvertFrom-P5WslList {
    param([object[]]$Raw)
    return @($Raw | ForEach-Object { $_.Trim("`0", ' ') } | Where-Object { $_ })
}

function Get-P5WslDistros {
    Assert-WslCommand
    $raw = & wsl.exe --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return ConvertFrom-P5WslList -Raw $raw
}

function Get-P5RunningWslDistros {
    Assert-WslCommand
    $raw = & wsl.exe --list --running --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return ConvertFrom-P5WslList -Raw $raw
}

function Test-P5WslDistro {
    param([Parameter(Mandatory)][string]$Name)
    return (Get-P5WslDistros) -contains $Name
}

function Test-P5WslRunning {
    param([Parameter(Mandatory)][string]$Name)
    return (Get-P5RunningWslDistros) -contains $Name
}

function Invoke-P5Wsl {
    param(
        [Parameter(Mandatory)][string]$Distro,
        [Parameter(Mandatory)][string]$Command,
        [string]$User
    )

    $arguments = @('-d', $Distro)
    if ($User) { $arguments += @('--user', $User) }
    $arguments += @('--', 'bash', '-lc', $Command)

    $output = & wsl.exe @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Commande WSL en echec dans '$Distro' : $Command"
    }
    return $output
}

function Get-P5WslState {
    param([Parameter(Mandatory)][string]$Distro)
    if (-not (Test-P5WslDistro -Name $Distro)) { return 'Absent' }
    if (Test-P5WslRunning -Name $Distro) { return 'Running' }
    return 'Stopped'
}

function Write-P5Result {
    param(
        [Parameter(Mandatory)][ValidateSet('OK','KO','INFO')][string]$Level,
        [Parameter(Mandatory)][string]$Message
    )
    '{0,-4} {1}' -f $Level, $Message
}
