<#
.SYNOPSIS
    Alpha Logic Hub - Backtest Runner
.DESCRIPTION
    Runs backtests on XAUUSD using MT5 data. Wrapper around the Python scripts.
.EXAMPLE
    .\run_backtest.ps1 sma_crossover -Period 1y
    .\run_backtest.ps1 rsi_reversal -Period 2y -Spread 25
    .\run_backtest.ps1 optimize -ParamGrid '{"fast_period":[10,20,30],"slow_period":[50,100]}'
#>

param(
    [Parameter(Position=0)]
    [string]$Command = "backtest",

    [Parameter(Position=1)]
    [string]$Symbol = "XAUUSD",

    [string]$Strategy = "sma_crossover",
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
    [int]$Windows = 6,
    [string]$Mode = "bootstrap",
    [int]$Simulations = 1000,
    [switch]$List,
    [switch]$Quiet,
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = $ScriptDir
$BacktestPy = Join-Path $ProjectRoot "scripts\backtest.py"
$OptimizePy = Join-Path $ProjectRoot "scripts\optimize.py"
$FetchDataPy = Join-Path $ProjectRoot "scripts\fetch_data.py"
$WalkForwardPy = Join-Path $ProjectRoot "scripts\walk_forward.py"
$MonteCarloPy = Join-Path $ProjectRoot "scripts\monte_carlo.py"

function Show-Help {
    Write-Host @"

Alpha Logic Hub - Backtest Runner
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
  supply_demand    Supply & demand zone trading (min_impulse_pct, min_cons_bars)

Commands:
  backtest (default)  Run a standard backtest
  optimize            Grid search over parameter grid
  wfa                 Walk-Forward Analysis (robustness test)
  mc                  Monte Carlo simulation (risk analysis)
  fetch               Download market data
  list                List available strategies

Params JSON examples:
  --Params '{"fast_period":10,"slow_period":50}'
  --Params '{"period":14,"oversold":30,"overbought":70}'

Optimization grid:
  --ParamGrid '{"fast_period":[10,20,30],"slow_period":[50,100,150,200]}'

WFA mode:
  .\run_backtest.ps1 wfa -Strategy sma_crossover -Period 3y -Windows 4

Monte Carlo mode:
  .\run_backtest.ps1 mc -Strategy supply_demand -Period 3y -Mode bootstrap -Simulations 1000
"@
    exit
}

if ($Help) { Show-Help }

# === Handle special commands ===
switch ($Command) {
    "list" {
        python $BacktestPy --list
        exit
    }
    "fetch" {
        $fetchArgs = @("--symbol", $Symbol, "--period", $Period, "--source", $Source, "--interval", $Interval)
        if ($Start) { $fetchArgs += @("--start", $Start) }
        if ($End)   { $fetchArgs += @("--end", $End) }
        python $FetchDataPy @fetchArgs
        exit
    }
    "optimize" {
        if (-not $ParamGrid) {
            Write-Error "ParamGrid is required for optimization. Example: '{\"fast_period\":[10,20],\"slow_period\":[50,100]}'"
            exit 1
        }
        $optArgs = @(
            "--strategy", $Strategy,
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
    "wfa" {
        $wfaArgs = @(
            "--strategy", $Strategy,
            "--symbol", $Symbol,
            "--period", $Period,
            "--source", $Source,
            "--capital", $Capital,
            "--spread", $Spread,
            "--windows", $Windows
        )
        if ($Start)    { $wfaArgs += @("--start", $Start) }
        if ($End)      { $wfaArgs += @("--end", $End) }
        if ($ParamGrid) { $wfaArgs += @("--param-grid", $ParamGrid) }
        if ($Params)   { $wfaArgs += @("--params", $Params) }
        python $WalkForwardPy @wfaArgs
        if ($LASTEXITCODE -eq 0) { Write-Host "[OK] WFA complete!" -ForegroundColor Green }
        exit
    }
    "mc" {
        $mcArgs = @(
            "--strategy", $Strategy,
            "--symbol", $Symbol,
            "--period", $Period,
            "--source", $Source,
            "--capital", $Capital,
            "--spread", $Spread,
            "--simulations", $Simulations,
            "--mode", $Mode,
            "--seed", 42
        )
        if ($Params)  { $mcArgs += @("--params", $Params) }
        if ($Start)   { $mcArgs += @("--start", $Start) }
        if ($End)     { $mcArgs += @("--end", $End) }
        python $MonteCarloPy @mcArgs
        if ($LASTEXITCODE -eq 0) { Write-Host "[OK] Monte Carlo complete!" -ForegroundColor Green }
        exit
    }
}

# === Default: Run backtest ===
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

Write-Host "+-----------------------------------------------+"
Write-Host "| Alpha Logic Hub - Backtest Engine            |"
Write-Host "| $Strategy | $Symbol | $Period |"
Write-Host "+-----------------------------------------------+"
Write-Host ""

python $BacktestPy @args

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Backtest complete!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Backtest failed (exit code $LASTEXITCODE)" -ForegroundColor Red
}
