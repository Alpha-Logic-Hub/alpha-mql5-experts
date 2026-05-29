---
name: market-regime-check
description: |
  Classify the current market regime (trending, ranging, volatile) for MQL5
  strategies. Produces an ALLOWED / CAUTION / NO-TRADE state with max exposure
  and rationale to gate trade entry decisions.

  Triggers: "market regime", "market conditions", "trending/ranging",
  "regimen de mercado", "condiciones", "volatilidad"
---

## Market States

| State | Condition | Max Exposure |
|-------|-----------|-------------|
| ALLOWED | ATR 0.7-1.3x avg, London/NY active, spread < 30 pts, HTF trending | 100% |
| CAUTION | ATR > 1.5x avg OR spread > 50 pts, max exposure 50% | 50% |
| NO-TRADE | CPI/FOMC/NFP within 30 min | 0% |

## Workflow

1. **Fetch ATR(14)** on the current timeframe. Compute ratio vs 20-period average ATR.
2. **Compare ADX(14)**: ADX > 25 → trending; ADX < 20 → ranging; 20-25 → transitioning.
3. **Check session**: London (08:00-16:00 UTC), New York (13:00-21:00 UTC), Asia (00:00-08:00 UTC). Non-active → CAUTION.
4. **Classify regime**: cross-reference ATR ratio, ADX, session, spread, and HTF (H1) trend direction.
5. **Output** structured regime label with metrics.

## Generic Examples

- **`<symbol>` `<timeframe>` normal trend**: ATR ratio within normal band, ADX > 25, active session, spread within policy → **ALLOWED**.
- **`<symbol>` `<timeframe>` stressed conditions**: ATR ratio > 1.5x or spread above policy, non-active session → **CAUTION** with reduced exposure.
- **`<symbol>` `<timeframe>` event risk**: High-impact event within the configured block window → **NO-TRADE** regardless of ATR/ADX values.

## Output Contract

```yaml
state:            # ALLOWED / CAUTION / NO-TRADE
atr_ratio:        # current ATR / 20-period avg ATR
adx:              # ADX(14) value
session:          # London / New York / Asia / Inactive
spread_pts:       # current spread in points
max_exposure_pct: # 100 / 50 / 0
rationale:        # brief justification
```
