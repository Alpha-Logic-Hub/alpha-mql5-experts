# References — mql5-risk-guardrail

## Migration Map (old RiskManager → RiskGuardrail)

| Old | New |
|-----|-----|
| `GetEAPnL()` | `CalculateDailyPnL(int magic, string sym, CPositionInfo &pos)` |
| `GetMinStopDist()` | `GetMinStopDistance()` |
| `CalculateLot(double sl)` | `CalculateLotSize(double slPoints, double maxLot, double fixedLot, double riskPercent, string symbol)` |
| `IsShieldTriggered()` | `IsShieldTriggered(bool useShield, double sodEquity, double dailyPL, double shieldPct)` |
| `CountActivePositions()` | `CountActivePositions(int magic, string sym, CPositionInfo &pos)` |

## RiskState Struct

```mql5
struct RiskState {
   double   effRiskPercent;
   double   effRR;
   double   effShieldPercent;
   datetime lastShieldResetDay;
   double   startOfDayEquity;
   double   dailyPL;
};
```

## Standard Includes Required

```mql5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
```
