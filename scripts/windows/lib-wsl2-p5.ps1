Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-P5Windows11 {
    $os = Get-CimInstance Win32_OperatingSystem
    if ($os.Caption -notmatch 'Windows 11') {
        throw "Windows 11 est requis. Systeme detecte : $($os.Caption)"
    }
}

function Assert-WslCommand {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        throw 'wsl.exe est introuvable. Activez WSL avant de poursuivre.'
    }
}

function Get-P5WslDistros {
    Assert-WslCommand
    $raw = & wsl.exe --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($raw | ForEach-Object { $_.Trim("`0", ' ') } | Where-Object { $_ })
}

function Test-P5WslDistro {
    param([Parameter(Mandatory)][string]$Name)
    return (Get-P5WslDistros) -contains $Name
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
    $lines = & wsl.exe --list --verbose 2>$null
    if ($LASTEXITCODE -ne 0) { return 'Unknown' }
    foreach ($line in $lines) {
        $clean = $line.Trim("`0")
        if ($clean -match ('^\s*\*?\s*' + [regex]::Escape($Distro) + '\s+(Running|Stopped)\s+([12])\s*$')) {
            return $Matches[1]
        }
    }
    return 'Unknown'
}

function Write-P5Result {
    param(
        [Parameter(Mandatory)][ValidateSet('OK','KO','INFO')][string]$Level,
        [Parameter(Mandatory)][string]$Message
    )
    '{0,-4} {1}' -f $Level, $Message
}
