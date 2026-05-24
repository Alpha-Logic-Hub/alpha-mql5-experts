---
name: mql5-risk-guardrail
description: |
  Risk Guardrail for MQL5 EAs — dynamic lot sizing, risk profiles, daily
  shield, position guards. Enforces SoulzBTC RISK-001..004 and ERR-001..003.
  
  RESTRICTION: Prohibido alterar el Stop Loss obligatorio. Todo OrderSend
  DEBE incluir SL != 0 calculado via GetMinStopDistance().

  Triggers: "risk", "lote", "lot", "shield", "SoulzBTC", "RISK-001",
  "guardrail", "gestion de riesgo", "CalculateLotSize", "g_state"
---

## SoulzBTC Risk Guardrails

| Rule | Enforcement |
|------|------------|
| RISK-001 | `effRiskPercent` capped at 1.0 in `ApplyRiskProfile` |
| RISK-002 | `SymbolInfoDouble(SYMBOL_VOLUME_STEP/MIN/MAX)` — no literals |
| RISK-003 | `GetMinStopDistance()` triple MathMax + `IsShieldTriggered()` `<=` |
| RISK-004 | Zero multiplier logic in lot sizing |

## Usage

```mql5
// In Expert EA directory:
#include "Risk\RiskGuardrail.mqh"

RiskState g_state;

int OnInit() {
   if(InpRiskPercent > 1.0) return INIT_PARAMETERS_INCORRECT;
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   return INIT_SUCCEEDED;
}

void OnTick() {
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   if(IsShieldTriggered(InpUseShield, g_state.startOfDayEquity,
                        g_state.dailyPL, g_state.effShieldPercent))
      return;
   double sl = GetMinStopDistance();
   double lot = CalculateLotSize(sl, InpMaxLot, InpFixedLot,
                                 g_state.effRiskPercent, _Symbol);
}
```

## CTrade Fragmentos Blindados

```mql5
// ERR-001: Ticket audit obligatorio
if(trade.Buy(lot, _Symbol, entry, sl, tp, comment)) {
   ulong ticket = trade.ResultOrder();
   Print("[Trade] EXECUTED — Ticket=", ticket);
} else {
   uint retCode = trade.ResultRetcode();
   Print("[Trade] FAILED — RetCode=", retCode);
}

// RISK-003: SL nunca cero
if(slPoints <= 0) {
   Print("[Trade] BLOCKED — slPoints must be > 0");
   return false;
}
```
