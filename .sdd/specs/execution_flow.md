# Execution Flow — Estándar de Reintentos de Órdenes

## 1. OrderSend Flow

```
1. Validate signal != NONE
2. Validate slPoints > 0 (RISK-003)
3. Check spread <= maxSpread (ERR-002)
4. Calculate entryPrice, slPrice, tpPrice
5. NormalizeDouble all prices
6. Log trade attempt (ERR-003)
7. CTrade.Buy/Sell
8. Check ResultRetcode (ERR-001)
9. If SUCCESS: log ticket, return true
10. If FAILURE: log retcode + description, return false
```

## 2. RetCode Handling

| RetCode | Action |
|---------|--------|
| TRADE_RETCODE_DONE | Success — log ticket |
| TRADE_RETCODE_REQUOTE | Recalculate price + retry (max 3, with backoff) |
| TRADE_RETCODE_PRICE_OFF | Wait 1 tick, retry |
| TRADE_RETCODE_INVALID_STOPS | Recalculate SL/TP distances |
| Any other | Log + abort — no retry |

## 3. Position Close Flow

```
1. Iterate PositionsTotal() backwards
2. Filter by magic + symbol
3. CTrade.PositionClose(ticket)
4. Check ResultRetcode
5. Log PnL if successful
6. Log retcode if failed
```

## 4. Exit Management Flow

```
OnTick:
1. Check if opposite signal detected
2. If InpCloseOnOpposite + hasLong + signal=SELL -> CloseAllPositions
3. If InpCloseOnOpposite + hasShort + signal=BUY -> CloseAllPositions
```

## 5. Latency Budget

```
OnTick total < 50ms
  - UpdateDailyShield: < 5ms
  - CheckEntrySignal (CopyBuffer × N): < 10ms
  - OrderSend: < 30ms
  - ManageExits: < 3ms
  - DrawHUD: < 2ms
```
