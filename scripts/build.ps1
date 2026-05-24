# Alpha MQL5 Experts — Local Build Script
# Usage: .\scripts\build.ps1 -EA "EA_MA_RSI_Trend"
# Requires: MetaTrader 5 installed

param(
    [Parameter(Mandatory=$true)]
    [string]$EA
)

Write-Host "=== Alpha MQL5 Build Pipeline ===" -ForegroundColor Cyan

# Pre-compile audit
Write-Host "`n[1/4] Pre-compile Audit..." -ForegroundColor Yellow
$eaDir = "Expert\$EA"
if (Select-String -Path "$eaDir\*.mqh" -Pattern "#pragma once") {
    Write-Host "❌ #pragma once found! MQL5 does not support this." -ForegroundColor Red
    exit 1
}
Write-Host "✅ No #pragma once" -ForegroundColor Green

if (Select-String -Path "$eaDir\*.mqh" -Pattern '\bColor\b') {
    Write-Host "❌ Uppercase 'Color' found! Must be 'color'." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Naming conventions OK" -ForegroundColor Green

# Count risk guardrail compliance
$slCount = (Select-String -Path "$eaDir\*.mqh","Shared\Risk\*.mqh" -Pattern "GetMinStopDistance").Count
if ($slCount -eq 0) {
    Write-Host "⚠️ GetMinStopDistance() not found — RISK-003 may be violated" -ForegroundColor Yellow
} else {
    Write-Host "✅ RISK-003: GetMinStopDistance found ($slCount refs)" -ForegroundColor Green
}

# Compile
Write-Host "`n[2/4] Compiling $EA..." -ForegroundColor Yellow
$metaeditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$eaPath = (Get-Item "$eaDir\$EA.mq5").FullName

if (Test-Path $metaeditor) {
    & $metaeditor /compile:"$eaPath" /log:"logs\compile_$EA.log" /s
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Compilation successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Compilation failed — check logs\compile_$EA.log" -ForegroundColor Red
        Get-Content "logs\compile_$EA.log" -Tail 20
        exit 1
    }
} else {
    Write-Host "⚠️ MetaEditor64 not found at $metaeditor" -ForegroundColor Yellow
    Write-Host "   Skipping compilation. Run manually in MetaEditor." -ForegroundColor Yellow
}

# Verify .ex5
Write-Host "`n[3/4] Verifying .ex5..." -ForegroundColor Yellow
$ex5 = Join-Path (Split-Path $eaPath -Parent) "$EA.ex5"
if (Test-Path $ex5) {
    Write-Host "✅ .ex5 generated: $ex5" -ForegroundColor Green
} else {
    Write-Host "❌ .ex5 not found" -ForegroundColor Red
}

# Sync skill registry
Write-Host "`n[4/4] Syncing skill registry..." -ForegroundColor Yellow
$skills = Get-ChildItem ".skills" -Directory | ForEach-Object { $_.Name }
Write-Host "Skills ready: $($skills -join ', ')" -ForegroundColor Green

Write-Host "`n=== Build Complete ===" -ForegroundColor Cyan
