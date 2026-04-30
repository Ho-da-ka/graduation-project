param(
    [int]$BackendPort = 8080,
    [int]$FrontendPort = 5173,
    [switch]$NoBackend,
    [switch]$NoFrontend
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $RootDir "Code\backend-service\ManagementPlatform"
$FrontendDir = Join-Path $RootDir "Code\admin-panel"
$RunLogsDir = Join-Path $RootDir "run-logs"
$PidFile = Join-Path $RunLogsDir "dev-processes.json"

function Resolve-JavaHome {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
        return $env:JAVA_HOME
    }

    $candidates = @()
    $javaRoot = "C:\Program Files\Java"
    if (Test-Path $javaRoot) {
        $candidates += Get-ChildItem $javaRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^jdk' } |
            Sort-Object Name -Descending
    }

    $temurinRoot = "C:\Program Files\Eclipse Adoptium"
    if (Test-Path $temurinRoot) {
        $candidates += Get-ChildItem $temurinRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^jdk' } |
            Sort-Object Name -Descending
    }

    foreach ($item in $candidates) {
        $javaExe = Join-Path $item.FullName "bin\java.exe"
        if (Test-Path $javaExe) {
            return $item.FullName
        }
    }

    return $null
}

function Stop-ProcessSafe {
    param(
        [Parameter(Mandatory = $true)][int]$TargetPid,
        [Parameter(Mandatory = $true)][string]$Reason
    )
    if ($TargetPid -le 0) { return }
    try {
        $proc = Get-Process -Id $TargetPid -ErrorAction Stop
        Stop-Process -Id $TargetPid -Force -ErrorAction Stop
        Write-Host "[STOP] PID=$TargetPid Name=$($proc.ProcessName) ($Reason)"
    } catch {
        # ignore
    }
}

function Get-PidsByPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port
    )
    $pids = @()
    try {
        $pids = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
    } catch {
        $pids = @()
    }
    if (-not $pids -or $pids.Count -eq 0) {
        $matches = netstat -ano | Select-String ":$Port\s+.*LISTENING\s+(\d+)$"
        $pids = $matches | ForEach-Object { [int]$_.Matches[0].Groups[1].Value } | Select-Object -Unique
    }
    return @($pids)
}

function Stop-ByPort {
    param(
        [Parameter(Mandatory = $true)][int]$Port
    )
    $portPids = Get-PidsByPort -Port $Port
    foreach ($portPid in $portPids) {
        Stop-ProcessSafe -TargetPid $portPid -Reason "port $Port"
    }
}

function Wait-PortReady {
    param(
        [Parameter(Mandatory = $true)][int]$Port,
        [int]$TimeoutSeconds = 60
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $client = $null
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $iar = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
            $connected = $iar.AsyncWaitHandle.WaitOne(1200, $false)
            if ($connected -and $client.Connected) {
                $client.EndConnect($iar) | Out-Null
                $client.Close()
                return $true
            }
        } catch {
            # ignore and retry
        } finally {
            if ($client -ne $null) {
                $client.Close()
            }
        }
        Start-Sleep -Milliseconds 800
    }
    return $false
}

if (-not (Test-Path $BackendDir)) {
    throw "Backend directory not found: $BackendDir"
}
if (-not (Test-Path $FrontendDir)) {
    throw "Frontend directory not found: $FrontendDir"
}

New-Item -ItemType Directory -Path $RunLogsDir -Force | Out-Null

Write-Host "=== Step 1/3: Stop old launcher processes ==="
if (Test-Path $PidFile) {
    try {
        $oldPids = Get-Content -Raw -Path $PidFile | ConvertFrom-Json
        if ($oldPids.backendPid) { Stop-ProcessSafe -TargetPid ([int]$oldPids.backendPid) -Reason "old backend launcher" }
        if ($oldPids.frontendPid) { Stop-ProcessSafe -TargetPid ([int]$oldPids.frontendPid) -Reason "old frontend launcher" }
    } catch {
        Write-Warning "PID file exists but cannot be parsed: $PidFile"
    }
}

Write-Host "=== Step 2/3: Stop processes occupying target ports ==="
if (-not $NoBackend) { Stop-ByPort -Port $BackendPort }
if (-not $NoFrontend) { Stop-ByPort -Port $FrontendPort }

Write-Host "=== Step 3/3: Start services ==="
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$current = @{}
$javaHome = Resolve-JavaHome

if (-not $NoBackend) {
    if (-not $javaHome) {
        throw "Cannot find JDK. Please install JDK 17 and set JAVA_HOME."
    }
    $backendOut = Join-Path $RunLogsDir "backend-$timestamp.log"
    $backendErr = Join-Path $RunLogsDir "backend-$timestamp.err.log"
    $backendCmd = "set `"JAVA_HOME=$javaHome`" && set `"PATH=%JAVA_HOME%\bin;%PATH%`" && cd /d `"$BackendDir`" && call mvnw.cmd spring-boot:run"
    $backendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $backendCmd `
        -PassThru -WindowStyle Hidden -RedirectStandardOutput $backendOut -RedirectStandardError $backendErr
    $current.backendLauncherPid = $backendProc.Id
    $current.backendPid = $backendProc.Id
    $current.backendLog = $backendOut
    $current.backendErrLog = $backendErr
    Write-Host "[START] Backend PID=$($backendProc.Id) JAVA_HOME=$javaHome"
}

if (-not $NoFrontend) {
    $frontendOut = Join-Path $RunLogsDir "frontend-$timestamp.log"
    $frontendErr = Join-Path $RunLogsDir "frontend-$timestamp.err.log"
    $frontendCmd = "cd /d `"$FrontendDir`" && npm run dev -- --host 0.0.0.0 --port $FrontendPort"
    $frontendProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $frontendCmd `
        -PassThru -WindowStyle Hidden -RedirectStandardOutput $frontendOut -RedirectStandardError $frontendErr
    $current.frontendLauncherPid = $frontendProc.Id
    $current.frontendPid = $frontendProc.Id
    $current.frontendLog = $frontendOut
    $current.frontendErrLog = $frontendErr
    Write-Host "[START] Frontend PID=$($frontendProc.Id)"
}

$current | ConvertTo-Json | Set-Content -Path $PidFile -Encoding UTF8

if (-not $NoBackend) {
    if (Wait-PortReady -Port $BackendPort -TimeoutSeconds 90) {
        $listeningBackendPid = (Get-PidsByPort -Port $BackendPort | Select-Object -First 1)
        if ($listeningBackendPid) {
            $current.backendPid = [int]$listeningBackendPid
        }
        Write-Host "[OK] Backend is ready: http://localhost:$BackendPort"
    } else {
        Write-Warning "[WARN] Backend port $BackendPort is not ready yet. Check log: $($current.backendErrLog)"
    }
}

if (-not $NoFrontend) {
    if (Wait-PortReady -Port $FrontendPort -TimeoutSeconds 45) {
        $listeningFrontendPid = (Get-PidsByPort -Port $FrontendPort | Select-Object -First 1)
        if ($listeningFrontendPid) {
            $current.frontendPid = [int]$listeningFrontendPid
        }
        Write-Host "[OK] Frontend is ready: http://localhost:$FrontendPort"
    } else {
        Write-Warning "[WARN] Frontend port $FrontendPort is not ready yet. Check log: $($current.frontendErrLog)"
    }
}

$current | ConvertTo-Json | Set-Content -Path $PidFile -Encoding UTF8

Write-Host ""
Write-Host "Done."
Write-Host "PID file: $PidFile"
Write-Host "Logs dir: $RunLogsDir"
