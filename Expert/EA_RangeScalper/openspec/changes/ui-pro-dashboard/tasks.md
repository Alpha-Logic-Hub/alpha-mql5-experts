# Tasks: ui-pro-dashboard

## Phase 1: UI Module

- [x] 1.1 Create `UI/ProDashboard.mqh` — CProDashboard class with CCanvas (737 lines)
  - Colors: PD_* prefix, ARGB terminal-green palette (15 color macros)
  - Dimensions: 340x520 at (10,10)
  - 4 tabs: TRADES, ESTRATEGIAS, STATS, CONFIG
  - Interactive: tab switching, close-all, visibility toggle, stats reset
  - Widgets: DrawProgressBar, DrawHeader, DrawTabs, DrawBottomButtons
  - API: InitCanvas(), UpdateDashboard(), ClearDashboard(), HandleClick(mx, my)
  - Pattern: Class-based (m_canvas, m_created, m_tab, m_visible members)

## Phase 2: EA Integration

- [x] 2.1 Update `RangeScalper_EA.mq5` (178 lines, from 230)
  - Added `#include "UI\ProDashboard.mqh"` (line 46)
  - Added `CProDashboard g_dashboard;` global (line 56)
  - Removed `RLabel()` helper (~13 lines)
  - Removed `DrawPanel()` function (~65 lines)
  - Added `g_dashboard.InitCanvas()` in OnInit (line 80)
  - Added `g_dashboard.ClearDashboard()` in OnDeinit (line 93)
  - Replaced `DrawPanel()` call with `g_dashboard.UpdateDashboard()` in OnTick (line 107)
  - Added `OnChartEvent` handler (lines 162-177) for CHARTEVENT_OBJECT_CLICK

## Phase 3: Verification

- [x] 3.1 MetaEditor64 compilation: 0 errors, 0 warnings
  - Output: RangeScalper_EA.ex5 (66,590 bytes)
  - Elapsed: 3,247 ms
  - CPU: X64 Regular

## Summary

| Metric | Value |
|--------|-------|
| ProDashboard.mqh | 737 lines |
| RangeScalper_EA.mq5 | 178 lines (was 230) |
| Net change | ~+665 lines (737 new - 80 removed + 28 added) |
| Compilation | 0 errors, 0 warnings |
