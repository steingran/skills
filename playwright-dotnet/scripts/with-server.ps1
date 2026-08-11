<#
.SYNOPSIS
    Start one or more servers, wait for their ports, run a command, then clean up.

.DESCRIPTION
    Each -Server entry is launched through pwsh (so '&&', 'cd', and env-var prefixes work)
    and polled on the matching -Port entry until it accepts TCP connections. Once every
    server is ready, -Run executes; its exit code becomes this script's exit code. All
    servers (and their child processes) are killed on the way out, including when the
    command fails or the script is interrupted.

    A port that is already open is treated as an already-running server and left alone.
    Server stdout/stderr is captured to temp files; the tail is printed if a server dies
    or never opens its port.

.PARAMETER Server
    One or more server commands. Must have the same number of entries as -Port.

.PARAMETER Port
    The TCP port each server listens on, in the same order as -Server.

.PARAMETER Run
    The command to run once all servers are ready, as a single quoted string. Quote it so
    its own flags are not parsed as parameters of this script.

.PARAMETER TimeoutSec
    Seconds to wait for each server to open its port. Default 60.

.EXAMPLE
    pwsh with-server.ps1 -Server "dotnet run --project src/Web --urls http://localhost:5000" -Port 5000 -Run "dotnet run smoke.cs"

.EXAMPLE
    pwsh with-server.ps1 -Server "dotnet run --project src/Api --urls http://localhost:5000","npm run dev" -Port 5000,5173 -Run "dotnet test tests/UiTests"
#>


[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory)][string[]]$Server,
    [Parameter(Mandatory)][int[]]$Port,
    [Parameter(Mandatory)][string]$Run,
    [int]$TimeoutSec = 60
)

$ErrorActionPreference = 'Stop'

if ($Server.Count -ne $Port.Count) {
    Write-Error "Number of -Server ($($Server.Count)) and -Port ($($Port.Count)) entries must match"
    exit 2
}

function Test-PortOpen([int]$p) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        if ($client.ConnectAsync('127.0.0.1', $p).Wait(1000)) { return $client.Connected }
        return $false
    } catch { return $false }
    finally { $client.Dispose() }
}

function Show-Log([string]$path, [string]$label) {
    if ((Test-Path $path) -and (Get-Item $path).Length -gt 0) {
        Write-Host "--- $label ---"
        Get-Content $path -Tail 30 | ForEach-Object { Write-Host "  $_" }
    }
}

$started = @()

try {
    for ($i = 0; $i -lt $Server.Count; $i++) {
        $cmd = $Server[$i]
        $p = $Port[$i]
        Write-Host "Starting server $($i + 1)/$($Server.Count): $cmd"

        if (Test-PortOpen $p) {
            Write-Host "  Port $p already in use - assuming this server is already running, skipping."
            continue
        }

        $out = [System.IO.Path]::GetTempFileName()
        $err = [System.IO.Path]::GetTempFileName()
        $proc = Start-Process -FilePath (Get-Process -Id $PID).Path `
            -ArgumentList '-NoProfile', '-NonInteractive', '-Command', $cmd `
            -PassThru -RedirectStandardOutput $out -RedirectStandardError $err `
            -WindowStyle Hidden
        $started += [pscustomobject]@{ Proc = $proc; Port = $p; Out = $out; Err = $err; Cmd = $cmd }

        Write-Host "  Waiting for port $p..."
        $deadline = (Get-Date).AddSeconds($TimeoutSec)
        $ready = $false
        while ((Get-Date) -lt $deadline) {
            if (Test-PortOpen $p) { $ready = $true; break }
            if ($proc.HasExited) { break }
            Start-Sleep -Milliseconds 400
        }

        if (-not $ready) {
            $why = if ($proc.HasExited) { "process exited with code $($proc.ExitCode)" } else { "timed out after ${TimeoutSec}s" }
            Show-Log $out "stdout: $cmd"
            Show-Log $err "stderr: $cmd"
            throw "Server failed to open port ${p}: $why"
        }
        Write-Host "  Ready on port $p"
    }

    Write-Host "`nAll $($Server.Count) server(s) ready"
    Write-Host "Running: $Run`n"

    $global:LASTEXITCODE = 0
    Invoke-Expression $Run
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    exit $exitCode
}
finally {
    if ($started.Count -gt 0) {
        Write-Host "`nStopping $($started.Count) server(s)..."
        foreach ($s in $started) {
            try {
                if (-not $s.Proc.HasExited) { $s.Proc.Kill($true) }  # $true = entire process tree
                $null = $s.Proc.WaitForExit(5000)
            } catch { Write-Host "  Could not stop '$($s.Cmd)': $($_.Exception.Message)" }
            Remove-Item $s.Out, $s.Err -ErrorAction SilentlyContinue
        }
        Write-Host "All servers stopped"
    }
}
