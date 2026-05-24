# References — mql5-risk-guardrail

## Related Files

### Risk Modules
| Path | Description |
|------|-------------|
| `MQL5\Include\SupplyDemandCVD\Risk\RiskGuardrail.mqh` | **Active** — 8 risk functions, RiskState struct, Print() logging |
| `MQL5\Include\SupplyDemandCVD\Risk\RiskManager.mqh` | **Deprecated** — original module, archived to `_deprecated/` |
| `MQL5\Include\SupplyDemandCVD\Analysis\Indicators.mqh` | CalculateRSI() moved here from RiskManager |
| `MQL5\Include\SupplyDemandCVD\Analysis\Session.mqh` | GetMarketSession() + ENUM_MARKET_SESSION moved here |

### Main EA
| Path | Description |
|------|-------------|
| `SupplyDemandCVD_EA_Math_Elite.mq5` | Main orchestrator — includes RiskGuardrail, declares `g_state` |

### Caller Files (consumers of risk functions)
| Path | Functions Used |
|------|---------------|
| `MQL5\Include\SupplyDemandCVD\Execution\TradeExecutor.mqh` | `IsShieldTriggered`, `CountActivePositions`, `GetMinStopDistance`, `CalculateLotSize` |
| `MQL5\Include\SupplyDemandCVD\UI\HUD.mqh` | `g_state.*`, `IsShieldTriggered`, `CountActivePositions`, `GetMarketSession`, `CalculateRSI` |
| `MQL5\Include\SupplyDemandCVD\Analysis\VolumeProfile.mqh` | `CountActivePositions`, `GetMinStopDistance`, `CalculateLotSize` |
| `MQL5\Include\SupplyDemandCVD\Execution\EntryScanner.mqh` | `CountActivePositions`, `GetMinStopDistance`, `CalculateLotSize` |

## Risk Profile Matrix

| Profile | effRiskPercent | effRR | effShieldPercent | Use Case |
|---------|---------------|-------|------------------|----------|
| 0 (Conservative) | `InpRiskPercent × 0.5` | 1.5 | 3.0% | High volatility, news, beginner |
| 1 (Balanced) | `InpRiskPercent × 1.0` | 1.33 | 4.0% | **Default** — normal conditions |
| 2 (Aggressive) | `InpRiskPercent × 1.5` | 1.2 | 6.0% | Low volatility, strong trend |
| 3+ (Custom) | `InpRiskPercent × 1.0` | `InpRR` | `InpShieldPercent` | User-defined |

Default `InpRiskPercent = 0.15` → profile 1 = **0.15% risk per trade** (well under 1.0% RISK-001 limit).

## Standard MQL5 Includes Used

| Include | Classes/Functions | Purpose |
|---------|------------------|---------|
| `<Trade\Trade.mqh>` | `CTrade` | Order management (SetExpertMagicNumber, PositionOpen, OrderSend) |
| `<Trade\PositionInfo.mqh>` | `CPositionInfo` | Position iteration (SelectByIndex, Magic, Symbol, Profit) |
| `<Trade\SymbolInfo.mqh>` | `SymbolInfoDouble`, `SymbolInfoInteger` | Lot step/min/max, trade stops level, tick value |

## Indicator Handles Required

| Handle | Created With | Used By |
|--------|-------------|---------|
| `h_atr` | `iATR(_Symbol, _Period, dynATRLen)` | `GetMinStopDistance()` — ATR-based SL buffer |

## MQL5 Built-in Constants Used

| Constant | Usage |
|----------|-------|
| `_Symbol` | Current chart symbol filter |
| `_Period` | Current timeframe for ATR handle |
| `_Point` | Point value for stop distance conversion |
| `SYMBOL_VOLUME_STEP` | Lot rounding precision |
| `SYMBOL_VOLUME_MIN` | Minimum lot allowed |
| `SYMBOL_VOLUME_MAX` | Maximum lot allowed |
| `SYMBOL_TRADE_STOPS_LEVEL` | Broker minimum stop distance |
| `SYMBOL_TRADE_TICK_VALUE` | Monetary value per tick (lot calc fallback) |
| `ACCOUNT_EQUITY` | Current account equity for risk/sizing |

## SoulzBTC Profile Reference

Profile file: `~/.config/opencode/sdd-trading-profile.json`

### Rules Enforced in This Module

| Rule | File | Implementation |
|------|------|----------------|
| RISK-001 | RiskGuardrail.mqh:56-58 | `if(s.effRiskPercent > 1.0) s.effRiskPercent = 1.0;` |
| RISK-001 | SupplyDemandCVD_EA_Math_Elite.mq5:206-209 | `if(InpRiskPercent > 1.0) return INIT_PARAMETERS_INCORRECT;` |
| RISK-002 | RiskGuardrail.mqh:156-190 | Uses `SymbolInfoDouble(SYMBOL_VOLUME_STEP/MIN/MAX)` — no literals |
| RISK-003 | RiskGuardrail.mqh:140-145 | `GetMinStopDistance()` — mandatory SL distance |
| RISK-003 | RiskGuardrail.mqh:125-132 | `IsShieldTriggered()` — daily loss limit |
| RISK-004 | RiskGuardrail.mqh:195-201 | `CountActivePositions()` — position guard, no lot multiplier |
| ERR-003 | RiskGuardrail.mqh:98,114,131,157-158 | `Print()` for shield, reset, lot calc, warnings |

## Migrated Functions — Old → New Mapping

| Old Name (RiskManager.mqh) | New Name (RiskGuardrail.mqh) | Signature Change | Files Updated |
|---------------------------|------------------------------|-----------------|---------------|
| `ApplyRiskProfile()` | `ApplyRiskProfile(RiskState &s)` | +RiskState param | .mq5 |
| `GetEAPnL()` | `CalculateDailyPnL(int magic, string sym, CPositionInfo &pos)` | +3 params | Internal only |
| `ResetDailyShield()` | `ResetDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos)` | +RiskState + 3 params | .mq5 |
| `UpdateDailyShield()` | `UpdateDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos)` | +RiskState + 3 params | .mq5 |
| `IsShieldTriggered()` | `IsShieldTriggered(bool useShield, double sodEquity, double dailyPL, double shieldPct)` | +4 params | TradeExecutor, HUD |
| `GetMinStopDist()` | `GetMinStopDistance()` | Rename only | TradeExecutor, VolumeProfile, EntryScanner |
| `CalculateLot(double sl)` | `CalculateLotSize(double slPoints, double maxLot, double fixedLot, double riskPercent, string symbol)` | +4 params | TradeExecutor, VolumeProfile, EntryScanner |
| `CountActivePositions()` | `CountActivePositions(int magic, string sym, CPositionInfo &pos)` | +3 params | TradeExecutor, HUD, VolumeProfile, EntryScanner |
| `CalculateRSI(int period)` | *(moved to Analysis/Indicators.mqh)* | No change | HUD (via include chain) |
| `GetMarketSession()` | *(moved to Analysis/Session.mqh)* | No change | HUD (via include chain) |
