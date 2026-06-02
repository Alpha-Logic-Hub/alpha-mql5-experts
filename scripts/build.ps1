# Alpha MQL5 Experts — Local Build Script
# Usage: .\scripts\build.ps1 -Expert "EA_MA_RSI_Trend"
#        .\scripts\build.ps1 -Expert "EA_PrecisionSniper" -MainFile "PrecisionSniper_EA.mq5"
#        .\scripts\build.ps1 EA_PrecisionSniper
# Requires: MetaTrader 5 installed

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Expert,

    [Parameter(Mandatory=$false)]
    [string]$MainFile = "",

    [Parameter(Mandatory=$false)]
    [string]$TerminalDataPath = ""
)

Write-Host "=== Alpha MQL5 Build Pipeline ===" -ForegroundColor Cyan

# Pre-compile audit
Write-Host "`n[1/4] Pre-compile Audit..." -ForegroundColor Yellow
$eaDir = "Expert\$Expert"
if (!(Test-Path -LiteralPath $eaDir)) {
    Write-Host "ERROR: EA directory not found: $eaDir" -ForegroundColor Red
    exit 1
}

$sourceFiles = @(
    Get-ChildItem -LiteralPath $eaDir -File -Recurse |
        Where-Object { $_.Extension -in @(".mq5", ".mqh") }
)

if ($sourceFiles.Count -eq 0) {
    Write-Host "ERROR: No MQL5 source files found in $eaDir" -ForegroundColor Red
    exit 1
}

if (Select-String -Path $sourceFiles.FullName -Pattern "#pragma once" -CaseSensitive) {
    Write-Host "ERROR: #pragma once found! MQL5 does not support this." -ForegroundColor Red
    exit 1
}
Write-Host "OK: No #pragma once" -ForegroundColor Green

if (Select-String -Path $sourceFiles.FullName -Pattern '\bColor\b' -CaseSensitive) {
    Write-Host "ERROR: Uppercase 'Color' found! Must be 'color'." -ForegroundColor Red
    exit 1
}
Write-Host "OK: Naming conventions OK" -ForegroundColor Green

# Count risk guardrail compliance
$slCount = (Select-String -Path "$eaDir\*.mqh","Shared\Risk\*.mqh" -Pattern "GetMinStopDistance").Count
if ($slCount -eq 0) {
    Write-Host "WARN: GetMinStopDistance() not found - RISK-003 may be violated" -ForegroundColor Yellow
} else {
    Write-Host "OK: RISK-003: GetMinStopDistance found ($($slCount) refs)" -ForegroundColor Green
}

# Compile
Write-Host "`n[2/4] Compiling $Expert..." -ForegroundColor Yellow
$metaeditor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
if ([string]::IsNullOrWhiteSpace($MainFile)) {
    $defaultMain = Join-Path $eaDir "$Expert.mq5"
    if (Test-Path -LiteralPath $defaultMain) {
        $MainFile = "$Expert.mq5"
    } else {
        $mq5Files = @(Get-ChildItem -LiteralPath $eaDir -Filter "*.mq5" -File)
        if ($mq5Files.Count -eq 1) {
            $MainFile = $mq5Files[0].Name
        } else {
            Write-Host "ERROR: Cannot determine main .mq5 file for $Expert. Pass -MainFile explicitly." -ForegroundColor Red
            exit 1
        }
    }
}

$eaPath = (Get-Item -LiteralPath (Join-Path $eaDir $MainFile)).FullName
Write-Host "Main file: $eaPath" -ForegroundColor Gray

if (Test-Path $metaeditor) {
    if (!(Test-Path -LiteralPath "logs")) {
        New-Item -ItemType Directory -Path "logs" | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($TerminalDataPath)) {
        $terminalRoots = @(
            Get-ChildItem -LiteralPath (Join-Path $env:APPDATA "MetaQuotes\Terminal") -Directory |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "MQL5\Experts") } |
                Sort-Object LastWriteTime -Descending
        )

        if ($terminalRoots.Count -eq 0) {
            Write-Host "ERROR: No MetaTrader terminal data path found under APPDATA\MetaQuotes\Terminal" -ForegroundColor Red
            exit 1
        }

        $TerminalDataPath = $terminalRoots[0].FullName
    }

    $expertsRoot = Join-Path $TerminalDataPath "MQL5\Experts"
    $stageRoot = Join-Path $expertsRoot "AlphaLogicHub"
    Write-Host "Staging sources to: $stageRoot" -ForegroundColor Gray

    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $stageRoot | Out-Null
    Copy-Item -LiteralPath "Expert" -Destination $stageRoot -Recurse -Force
    Copy-Item -LiteralPath "Shared" -Destination $stageRoot -Recurse -Force

    $compilePath = Join-Path $stageRoot (Join-Path $eaDir $MainFile)
    $compileLog = (Join-Path (Get-Location) "logs\compile_$Expert.log").ToString()
    & $metaeditor /compile:"$compilePath" /log:"$compileLog"
    $compileOk = ($LASTEXITCODE -eq 0)
    if (!$compileOk -and (Test-Path -LiteralPath $compileLog)) {
        $logText = Get-Content $compileLog -Raw
        if ($logText -match "(?i)result:?\s+0\s+errors,\s+0\s+warnings") {
            Write-Host "WARN: MetaEditor returned exit code $LASTEXITCODE but log reports 0 errors, 0 warnings" -ForegroundColor Yellow
            $compileOk = $true
        }
    }

    if ($compileOk) {
        Write-Host "OK: Compilation successful" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Compilation failed - check $compileLog" -ForegroundColor Red
        if (Test-Path -LiteralPath $compileLog) {
            Get-Content $compileLog -Tail 20
        } else {
            Write-Host "WARN: MetaEditor did not create compile log at $compileLog" -ForegroundColor Yellow
        }
        exit 1
    }
} else {
    Write-Host "ERROR: MetaEditor64 not found at $metaeditor" -ForegroundColor Red
    exit 1
}

# Verify .ex5
Write-Host "`n[3/4] Verifying .ex5..." -ForegroundColor Yellow
$ex5Name = [System.IO.Path]::ChangeExtension((Split-Path $compilePath -Leaf), ".ex5")
$ex5 = Join-Path (Split-Path $compilePath -Parent) $ex5Name
for ($i = 0; $i -lt 10 -and !(Test-Path -LiteralPath $ex5); $i++) {
    Start-Sleep -Milliseconds 500
}

if (Test-Path $ex5) {
    Write-Host "OK: .ex5 generated: $ex5" -ForegroundColor Green
} else {
    Write-Host "ERROR: .ex5 not found" -ForegroundColor Red
    exit 1
}

# Build summary
Write-Host "`n[4/4] Build evidence..." -ForegroundColor Yellow
Write-Host "Compile log: $compileLog" -ForegroundColor Green
Write-Host "Artifact: $ex5" -ForegroundColor Green

Write-Host "`n=== Build Complete ===" -ForegroundColor Cyan
