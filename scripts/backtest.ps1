# Alpha MQL5 Experts — Strategy Tester Automation
# Usage: .\scripts\backtest.ps1 -Expert "EA_PrecisionSniper" -Symbol "XAUUSD" -Period "M15"
#        .\scripts\backtest.ps1 EA_PrecisionSniper -DryRun
# Requires: MetaTrader 5 installed and terminal data path available.

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Expert,

    [Parameter(Mandatory=$false)]
    [string]$MainFile = "",

    [Parameter(Mandatory=$false)]
    [string]$Symbol = "XAUUSD",

    [Parameter(Mandatory=$false)]
    [ValidateSet("M1", "M5", "M15", "M30", "H1", "H4", "D1")]
    [string]$Period = "M15",

    [Parameter(Mandatory=$false)]
    [string]$FromDate = "2024.01.01",

    [Parameter(Mandatory=$false)]
    [string]$ToDate = "2025.12.31",

    [Parameter(Mandatory=$false)]
    [int]$Deposit = 10000,

    [Parameter(Mandatory=$false)]
    [string]$Currency = "USD",

    [Parameter(Mandatory=$false)]
    [int]$Leverage = 100,

    [Parameter(Mandatory=$false)]
    [int]$Model = 4,

    [Parameter(Mandatory=$false)]
    [string]$TerminalDataPath = "",

    [Parameter(Mandatory=$false)]
    [string]$TerminalExe = "C:\Program Files\MetaTrader 5\terminal64.exe",

    [Parameter(Mandatory=$false)]
    [int]$TimeoutSeconds = 900,

    [Parameter(Mandatory=$false)]
    [switch]$CloseRunningTerminal,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

function Resolve-TerminalDataPath {
    param([string]$ProvidedPath)

    if (![string]::IsNullOrWhiteSpace($ProvidedPath)) {
        if (!(Test-Path -LiteralPath (Join-Path $ProvidedPath "MQL5\Experts"))) {
            throw "TerminalDataPath does not contain MQL5\Experts: $ProvidedPath"
        }
        return $ProvidedPath
    }

    $terminalRoot = Join-Path $env:APPDATA "MetaQuotes\Terminal"
    $terminalRoots = @(
        Get-ChildItem -LiteralPath $terminalRoot -Directory |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "MQL5\Experts") } |
            Sort-Object LastWriteTime -Descending
    )

    if ($terminalRoots.Count -eq 0) {
        throw "No MetaTrader terminal data path found under $terminalRoot"
    }

    return $terminalRoots[0].FullName
}

function Resolve-MainFile {
    param([string]$ExpertName, [string]$RequestedMainFile)

    $eaDir = "Expert\$ExpertName"
    if (!(Test-Path -LiteralPath $eaDir)) {
        throw "EA directory not found: $eaDir"
    }

    if (![string]::IsNullOrWhiteSpace($RequestedMainFile)) {
        return $RequestedMainFile
    }

    $defaultMain = Join-Path $eaDir "$ExpertName.mq5"
    if (Test-Path -LiteralPath $defaultMain) {
        return "$ExpertName.mq5"
    }

    $mq5Files = @(Get-ChildItem -LiteralPath $eaDir -Filter "*.mq5" -File)
    if ($mq5Files.Count -eq 1) {
        return $mq5Files[0].Name
    }

    throw "Cannot determine main .mq5 file for $ExpertName. Pass -MainFile explicitly."
}

function Convert-ToTesterExpertPath {
    param([string]$ExpertName, [string]$ResolvedMainFile)

    $mainWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ResolvedMainFile)
    return "AlphaLogicHub\Expert\$ExpertName\$mainWithoutExtension"
}

Write-Host "=== Alpha MQL5 Strategy Tester ===" -ForegroundColor Cyan

if (!(Test-Path -LiteralPath $TerminalExe)) {
    Write-Host "ERROR: terminal64.exe not found at $TerminalExe" -ForegroundColor Red
    exit 1
}

$resolvedTerminalDataPath = Resolve-TerminalDataPath -ProvidedPath $TerminalDataPath
$resolvedMainFile = Resolve-MainFile -ExpertName $Expert -RequestedMainFile $MainFile
$expertPath = Convert-ToTesterExpertPath -ExpertName $Expert -ResolvedMainFile $resolvedMainFile

$setPath = Join-Path (Get-Location) "configs\backtests\$Expert.set"
if (!(Test-Path -LiteralPath $setPath)) {
    Write-Host "ERROR: parameter set not found: $setPath" -ForegroundColor Red
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$generatedDir = Join-Path (Get-Location) "logs\tester"
$rawReportDir = Join-Path (Get-Location) "reports\backtests\raw"
New-Item -ItemType Directory -Path $generatedDir -Force | Out-Null
New-Item -ItemType Directory -Path $rawReportDir -Force | Out-Null

$testerConfig = Join-Path $generatedDir "${timestamp}_${Expert}.ini"
$testerReport = Join-Path $rawReportDir "${timestamp}_${Expert}_${Symbol}_${Period}.html"

Write-Host "[1/3] Compile/stage expert..." -ForegroundColor Yellow
& .\scripts\build.ps1 -Expert $Expert -MainFile $resolvedMainFile -TerminalDataPath $resolvedTerminalDataPath
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: build gate failed; tester will not run." -ForegroundColor Red
    exit 1
}

Write-Host "[2/3] Generate tester config..." -ForegroundColor Yellow
$configText = @"
[Tester]
Expert=$expertPath
ExpertParameters=$setPath
Symbol=$Symbol
Period=$Period
Model=$Model
Optimization=0
FromDate=$FromDate
ToDate=$ToDate
ForwardMode=0
Deposit=$Deposit
Currency=$Currency
Leverage=$Leverage
Visual=0
Report=$testerReport
ReplaceReport=1
ShutdownTerminal=1
"@

Set-Content -LiteralPath $testerConfig -Value $configText -Encoding ASCII
Write-Host "Tester config: $testerConfig" -ForegroundColor Green
Write-Host "Expected report: $testerReport" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN: not launching terminal64.exe" -ForegroundColor Yellow
    exit 0
}

Write-Host "[3/3] Run Strategy Tester..." -ForegroundColor Yellow
$runningTerminals = @(
    Get-Process terminal64 -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $TerminalExe }
)

if ($runningTerminals.Count -gt 0) {
    if (!$CloseRunningTerminal) {
        Write-Host "ERROR: terminal64.exe is already running. MT5 may ignore /config while an instance is active." -ForegroundColor Red
        Write-Host "       Re-run with -CloseRunningTerminal to close the active terminal before the automated test." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "WARN: Closing running terminal64.exe instance(s) before automated test." -ForegroundColor Yellow
    $runningTerminals | Stop-Process -Force
    Start-Sleep -Seconds 3
}

$process = Start-Process -FilePath $TerminalExe -ArgumentList "/config:`"$testerConfig`"" -PassThru

if (!$process.WaitForExit($TimeoutSeconds * 1000)) {
    Write-Host "ERROR: Strategy Tester timed out after $TimeoutSeconds seconds. Killing terminal process." -ForegroundColor Red
    Stop-Process -Id $process.Id -Force
    exit 1
}

Start-Sleep -Seconds 2

if (Test-Path -LiteralPath $testerReport) {
    Write-Host "OK: Strategy Tester report generated: $testerReport" -ForegroundColor Green
    exit 0
}

Write-Host "ERROR: Strategy Tester report was not generated: $testerReport" -ForegroundColor Red
Write-Host "Check terminal tester logs under: $resolvedTerminalDataPath\Tester" -ForegroundColor Yellow
exit 1
