<#
.SYNOPSIS
    Alpha Logic Hub — Backtest Runner
.DESCRIPTION
    Runs backtests on XAUUSD using MT5 data. Wrapper around the Python scripts.
.EXAMPLE
    .\run_backtest.ps1 -Strategy sma_crossover -Period 1y
    .\run_backtest.ps1 -Strategy rsi_reversal -Period 2y -Spread 25
    .\run_backtest.ps1 -Strategy optimize -ParamGrid '{"fast_period":[10,20,30],"slow_period":[50,100]}'
#>

param(
    [Parameter(Position=0)]
    [string]$Strategy = "sma_crossover",

    [Parameter(Position=1)]
    [string]$Symbol = "XAUUSD",

    [string]$Period = "1y",
    [string]$Start,
    [string]$End,

    [ValidateSet("mt5", "yfinance")]
    [string]$Source = "mt5",

    [int]$Capital = 10000,
    [int]$Spread = 20,
    [string]$Interval = "1d",
    [string]$Params,
    [string]$ParamGrid,
    [switch]$List,
    [switch]$Quiet,
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BacktestPy = Join-Path $ProjectRoot "scripts\backtest.py"
$OptimizePy = Join-Path $ProjectRoot "scripts\optimize.py"
$FetchDataPy = Join-Path $ProjectRoot "scripts\fetch_data.py"

function Show-Help {
    Write-Host @"

Alpha Logic Hub — Backtest Runner
===================================
Usage:
  .\run_backtest.ps1 sma_crossover -Period 1y
  .\run_backtest.ps1 rsi_reversal -Period 2y -Spread 25
  .\run_backtest.ps1 optimize -ParamGrid '{"fast_period":[10,20],"slow_period":[50,100]}'
  .\run_backtest.ps1 fetch -Period 2y
  .\run_backtest.ps1 list

Strategies:
  sma_crossover    SMA golden/death cross (fast, slow)
  ema_crossover    EMA cross (fast, slow)
  rsi_reversal     RSI oversold/overbought (period, oversold, overbought)
  macd             MACD signal cross (fast, slow, signal)
  bollinger_bands  Bollinger mean reversion (period, std_dev)
  breakout         Price breakout (lookback, threshold)
  mean_reversion   Z-score mean reversion (period, z_threshold)
  momentum         Rate of change (period, threshold)

Params JSON examples:
  --Params '{"fast_period":10,"slow_period":50}'
  --Params '{"period":14,"oversold":30,"overbought":70}'

Optimization grid:
  --ParamGrid '{"fast_period":[10,20,30],"slow_period":[50,100,150,200]}'
"@
    exit
}

if ($Help) { Show-Help }

# Handle special commands
if ($Strategy -eq "list") {
    python $BacktestPy --list
    exit
}

if ($Strategy -eq "fetch") {
    $fetchArgs = @("--symbol", $Symbol, "--period", $Period, "--source", $Source, "--interval", $Interval)
    if ($Start) { $fetchArgs += @("--start", $Start) }
    if ($End)   { $fetchArgs += @("--end", $End) }
    python $FetchDataPy @fetchArgs
    exit
}

if ($Strategy -eq "optimize") {
    if (-not $ParamGrid) {
        Write-Error "ParamGrid is required for optimization. Example: '{\"fast_period\":[10,20],\"slow_period\":[50,100]}'"
        exit 1
    }
    $optArgs = @(
        "--strategy", "sma_crossover",
        "--symbol", $Symbol,
        "--param-grid", $ParamGrid,
        "--period", $Period,
        "--capital", $Capital,
        "--spread", $Spread,
        "--source", $Source
    )
    if ($Start) { $optArgs += @("--start", $Start) }
    if ($End)   { $optArgs += @("--end", $End) }
    python $OptimizePy @optArgs
    exit
}

# Run backtest
$args = @(
    "--strategy", $Strategy,
    "--symbol", $Symbol,
    "--period", $Period,
    "--capital", $Capital,
    "--spread", $Spread,
    "--interval", $Interval,
    "--source", $Source
)
if ($Start)   { $args += @("--start", $Start) }
if ($End)     { $args += @("--end", $End) }
if ($Params)  { $args += @("--params", $Params) }
if ($Quiet)   { $args += "--quiet" }

Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Alpha Logic Hub — Backtest Engine                    ║" -ForegroundColor Cyan
Write-Host "║   $Strategy  |  $Symbol  |  $Period          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

python $BacktestPy @args

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Backtest complete!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Backtest failed (exit code $LASTEXITCODE)" -ForegroundColor Red
}
