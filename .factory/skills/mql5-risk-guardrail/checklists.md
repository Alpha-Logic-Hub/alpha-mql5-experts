# Checklists — mql5-risk-guardrail

## Post-Refactor Verification Checklist

```
COMPILACION:
□ metaeditor64 compila sin errores?
□ Warnings de compilacion revisados?

INCLUDES:
□ .mq5 principal incluye RiskGuardrail.mqh (no RiskManager.mqh)?
□ .mq5 principal incluye Analysis/Indicators.mqh?
□ .mq5 principal incluye Analysis/Session.mqh?

GLOBAL STATE:
□ RiskState g_state; declarada en .mq5?
□ effRiskPercent, effRR, effShieldPercent eliminadas como vars sueltas?
□ lastShieldResetDay, startOfDayEquity, dailyPL eliminadas como vars sueltas?

FUNCIONES RENOMBRADAS (sin rastros viejos en callers):
□ CalculateLot → CalculateLotSize(InpMaxLot, InpFixedLot, effRiskPercent, _Symbol)
□ GetMinStopDist → GetMinStopDistance()
□ GetEAPnL → CalculateDailyPnL(InpMagicNumber, _Symbol, pos)
□ IsShieldTriggered() → IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, ...)
□ CountActivePositions() → CountActivePositions(InpMagicNumber, _Symbol, pos)
□ dailyPL → g_state.dailyPL (en Print y HUD)
□ startOfDayEquity → g_state.startOfDayEquity
□ effShieldPercent → g_state.effShieldPercent

SOULZBTC COMPLIANCE:
□ RISK-001: effRiskPercent ≤ 1.0? (ApplyRiskProfile cap + OnInit validation)
□ RISK-002: Sin hardcoded lots? grep "0\.0[1-9]" = 0 hits en RiskGuardrail.mqh
□ RISK-003: GetMinStopDistance retorna MathMax(userSL, atrSL, stopLevel+10)?
□ RISK-003: IsShieldTriggered bloquea cuando dailyPL ≤ maxLoss?
□ RISK-004: Sin logica de multiplicacion de lote en perdidas?
□ ERR-003: Print() en shield trigger, daily reset, lot calculation?
```

## Pre-Compile Checklist

```powershell
# 1. Verificar includes (PowerShell)
Select-String -Path "SupplyDemandCVD_EA_Math_Elite.mq5" -Pattern '#include' | 
   Select-String "RiskManager"  # ← debe dar 0 hits

# 2. Verificar nombres viejos en callers
$patterns = @("CalculateLot\(", "GetMinStopDist\(", "GetEAPnL\(", "IsShieldTriggered\(\)", "CountActivePositions\(\)")
foreach ($p in $patterns) {
   $hits = Select-String -Path "MQL5\Include\SupplyDemandCVD\Execution\*.mqh","MQL5\Include\SupplyDemandCVD\Analysis\*.mqh","MQL5\Include\SupplyDemandCVD\UI\*.mqh" -Pattern $p
   if ($hits) { Write-Warning "OLD NAME FOUND: $p"; $hits }
}

# 3. Verificar vars globales viejas
$oldVars = @("(?<!g_state\.)(?<!\w)effRiskPercent(?!\w)", "(?<!g_state\.)(?<!\w)effRR(?!\w)", 
             "(?<!g_state\.)(?<!\w)effShieldPercent(?!\w)", "(?<!g_state\.)(?<!\w)dailyPL(?!\w)",
             "(?<!g_state\.)(?<!\w)startOfDayEquity(?!\w)")
foreach ($v in $oldVars) {
   $hits = Select-String -Path "MQL5\Include\SupplyDemandCVD\*.mqh" -Pattern $v
   if ($hits) { Write-Warning "OLD GLOBAL FOUND: $v"; $hits }
}
```

## Lot Sizing Smoke Test

| Account Size | Profile | Risk % | Expected Lot @ 20pip SL | Formula |
|-------------|---------|--------|------------------------|---------|
| $10,000 | 0 (Conservative) | 0.075% | ~0.04 | $10k × 0.075% / (20 × $10) |
| $10,000 | 1 (Balanced) | 0.15% | ~0.08 | $10k × 0.15% / (20 × $10) |
| $10,000 | 2 (Aggressive) | 0.225% | ~0.11 | $10k × 0.225% / (20 × $10) |
| $50,000 | 1 (Balanced) | 0.15% | ~0.38 | $50k × 0.15% / (20 × $10) |
| $100,000 | 1 (Balanced) | 0.15% | ~0.75 | $100k × 0.15% / (20 × $10) |

Note: Actual values depend on `SymbolInfoDouble(SYMBOL_TRADE_TICK_VALUE)` for XAUUSD.

## Shield Trigger Test

| Condition | dailyPL | shieldPercent | startOfDayEquity | Expected |
|-----------|---------|---------------|------------------|----------|
| No shield | false (InpUseShield=false) | 4.0% | $50,000 | false |
| Under threshold | -$1,500 | 4.0% | $50,000 | false |
| At threshold | -$2,000 | 4.0% | $50,000 | true |
| Over threshold | -$2,500 | 4.0% | $50,000 | true |
| Over max shield | -$5,000 | 6.0% (Aggressive) | $50,000 | true |
