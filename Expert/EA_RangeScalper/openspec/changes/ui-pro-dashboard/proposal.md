# Proposal: Pro Dashboard UI

## Intent

Replace the current flickering OBJ_LABEL panel (~80 lines in RangeScalper_EA.mq5) with a glassmorphism CCanvas dashboard. The existing panel re-creates all objects every 2s, shows only aggregate data, and has no interactive controls. The new dashboard provides: per-strategy visibility (4 tabs), click-to-act buttons, progress bars for scores, and no-object-flicker rendering.

## Scope

### In Scope
- New `UI/ProDashboard.mqh` (~400 lines): `CProDashboard` class wrapping CCanvas
- 4-tab layout: TRADES | ESTRATEGIAS | STATS | CONFIG with terminal-green palette
- Interactive buttons: tab switching, emergency close-all, toggle visibility, reset stats
- Replace `DrawPanel()` + `RLabel()` in `RangeScalper_EA.mq5` with `g_dashboard.SyncState()` + `g_dashboard.Draw()`
- Add `OnChartEvent` handler to main EA for canvas click routing

### Out of Scope
- Strategy logic changes (all 4 strategies untouched)
- Risk/execution changes (ScalpEngine.mqh untouched)
- Mobile/tablet optimization
- TradingView-style chart overlays

## Capabilities

### New Capabilities
- `ui-dashboard`: Canvas-based HUD panel with tabs, progress bars, and interactive buttons for RangeScalper EA

### Modified Capabilities
- None (pure UI refactor; no spec-level behavior changes to existing capabilities)

## Approach

Class-based (`CProDashboard`) wrapping CCanvas, following BayesianUI.mqh patterns from PrecisionSniper. Glassmorphism via `COLOR_FORMAT_ARGB_NORMALIZE` + `ColorToARGB()` with partial alpha. `SyncState()` copies trading globals before draw; `Draw()` renders via erase→bg→header→tabs→content→buttons→update pipeline. Redraw throttled to 1 Hz (vs current 0.5 Hz object flicker). FontSet() calls batched by font to minimize overhead.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `Expert/EA_RangeScalper/RangeScalper_EA.mq5` | Modified | Remove `DrawPanel()` + `RLabel()` (~80 lines); add `#include`, `OnChartEvent`, dashboard init/deinit/draw calls (~10 lines) |
| `Expert/EA_RangeScalper/UI/ProDashboard.mqh` | New | `CProDashboard` class: init, sync, draw, tabs, buttons, destroy (~400 lines) |
| `Expert/EA_RangeScalper/Core/Definitions.mqh` | Unchanged | All 40+ globals already accessible |
| `Expert/EA_RangeScalper/Signals/*.mqh` | Unchanged | 4 strategy files read-only from dashboard |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| OnTick budget > 50ms | Low | Batch FontSet calls; throttle redraw to 1 Hz; benchmarked BayesianUI at ~20ms |
| ARGB format mismatch | Low | Verified via Canvas.mqh; `ColorToARGB()` handles conversion explicitly |
| ChartEvent conflicts with other EAs | Low | Filter by `sparam == "dash_canvas"` via `CHARTEVENT_OBJECT_CLICK`; canvas-relative coords |
| Compilation fails on missing includes | Low | `#include <Canvas/Canvas.mqh>` is MT5 standard library; tested on this instance |

## Rollback Plan

1. Remove `#include "UI/ProDashboard.mqh"` and dashboard calls from `.mq5`
2. Restore `DrawPanel()` and `RLabel()` from git history
3. Delete `UI/ProDashboard.mqh`
4. Recompile — zero functional impact (UI-only change)

## Dependencies

- MT5 Standard Library: `<Canvas/Canvas.mqh>` (pre-installed)
- Existing 40+ `g_*` globals from `Core/Definitions.mqh` + signal modules

## Success Criteria

- [ ] MetaEditor64 compilation: 0 errors, 0 warnings
- [ ] All 4 tabs render correct live data (TRADES, ESTRATEGIAS, STATS, CONFIG)
- [ ] Button clicks: tab switch, close-all, toggle visibility, reset stats all functional
- [ ] No OBJ_LABEL flicker (single canvas object, erased/redrawn in-memory)
- [ ] OnTick budget < 30ms (canvas redraw only; no object create/delete overhead)
- [ ] All 4 strategies continue operating identically (signal evaluation unchanged)
