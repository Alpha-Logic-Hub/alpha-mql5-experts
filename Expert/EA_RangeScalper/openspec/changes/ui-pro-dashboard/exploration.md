# Exploration: ui-pro-dashboard

## Current State

The RangeScalper EA (`RangeScalper_EA.mq5`, 230 lines) has a basic panel drawn with `OBJ_LABEL`/`OBJ_RECTANGLE_LABEL` objects via a `DrawPanel()` function (~80 lines, lines 59-136). The panel shows:

- **Header**: "RANGE SCALPER" + timestamp
- **Range info**: `g_rangeLow` — `g_rangeHigh`
- **Spread/cool down**: points + cooldown bars remaining
- **Direction + P&L**: LONG/SHORT/FLAT with unrealized P&L in dollars
- **Stats**: total trades, wins, win rate %, gross profit, gross loss, net, daily count/max
- **Overextension**: SOBRECOMPRA / SOBREVENTA / sin senal status

**Problems with current approach**:
1. UI code mixed with trading logic in main EA file (not modular)
2. OBJ_LABEL flicker: deletes and recreates every 2 seconds via `ObjectsDeleteAll` + `ObjectCreate`
3. No multi-strategy visibility: 4 strategies (Range, Nyao, BB, Wick) but panel only shows aggregate
4. No interactive controls (no CHARTEVENT_CLICK handling)
5. Consolas font, no glassmorphism, no visual hierarchy
6. No progress bars, no strategy scores, no per-strategy status

## Affected Areas

- `Expert/EA_RangeScalper/RangeScalper_EA.mq5` — UI code (lines 59-136) to be REMOVED/replaced with ProDashboard include; OnChartEvent to be ADDED; OnDeinit to call dashboard cleanup
- `Expert/EA_RangeScalper/UI/ProDashboard.mqh` — NEW: all dashboard rendering, CCanvas, button handling
- `Expert/EA_RangeScalper/Core/Definitions.mqh` — MAY expose additional globals for dashboard read access (already has `g_*` globals accessible)
- `Expert/EA_RangeScalper/Signals/NyaoScorer.mqh` — dashboard reads `g_nyaoScore`, `g_nyaoLong`/`g_nyaoShort` (already exposed as globals)
- `Expert/EA_RangeScalper/Signals/BBScalper.mqh` — dashboard reads `g_bbOverUpper`, `g_bbUnderLower` (already exposed)
- `Expert/EA_RangeScalper/Signals/WickScalper.mqh` — dashboard reads `g_wickLong`/`g_wickShort` (already exposed)
- `openspec/specs/ui/spec.md` — NEW delta spec for dashboard requirements

## Data Inventory (What Needs Display)

### Per-Strategy State (4 strategies: Range, Nyao, Bollinger, Wick)

| Strategy | Signal Globals | Score/Rating | Indicator Handles | Status Flag |
|----------|---------------|-------------|-------------------|-------------|
| Range | `g_sigLong/Short`, `g_sigPrice/SL/TP`, `g_overHigh/Low`, `g_barsSinceBreak` | N/A (binary) | `hATR` | Break+reversal state |
| Nyao | `g_nyaoLong/Short`, `g_nyaoPrice/SL/TP`, `g_nyaoScore` | 0-10 multi-factor | `hEmaFast`, `hEmaSlow`, `hRSI` | Score threshold |
| B.Bands | `g_bbLong/Short`, `g_bbPrice/SL/TP`, `g_bbOverUpper/UnderLower`, `g_bbBarsSince` | N/A (binary) | `hBB_Upper/Mid/Lower` | Band touch+reversal |
| Wick | `g_wickLong/Short`, `g_wickPrice/SL/TP` | N/A (binary) | `hATR` | Wick% > 50% + range break |

### Trade State
- `g_tradeOpen`, `g_dir`, `g_entry`, `g_sl`, `g_tp`, `g_lotSize` — active trade
- `g_rangeHigh`, `g_rangeLow`, `g_rangeMid` — current range
- Current BID/ASK, spread, ATR value — live market

### Stats State
- `g_statTotal`, `g_statWins`, `g_statLosses` — counts
- `g_statProfit`, `g_statLoss` — gross P&L
- `g_dailyTrades`, `MaxDailyTrades` — daily limit
- `g_cooldown`, `CooldownBars` — cooldown tracker

### Config/Inputs
- `RangeLookback`, `ATRPeriod`, `TPDollars`, `SLMult`, `MaxBarsWait`
- `InpLotSize`, `InpMagicNumber`, `MaxSpread`, `MaxDailyTrades`, `CooldownBars`

## CCanvas API Verification (from `<Canvas/Canvas.mqh>`)

All signatures confirmed by reading the actual MT5 header (`MQL5/Include/Canvas/Canvas.mqh`):

| Method | Signature | Use in Dashboard |
|--------|-----------|-----------------|
| `CreateBitmapLabel` | `(long chart_id, int subwin, string name, int x, int y, int w, int h, ENUM_COLOR_FORMAT)` → `bool` | Initialize dashboard canvas |
| `Erase` | `(uint clr)` → `void` | Clear canvas before redraw |
| `Update` | `(bool redraw=true)` → `void` | Commit pixels to screen |
| `FillRectangle` | `(int x1, int y1, int x2, int y2, uint clr)` → `void` | Panel backgrounds, button fills, progress bar fill |
| `Rectangle` | `(int x1, int y1, int x2, int y2, uint clr)` → `void` | Borders, button outlines, progress bar outline |
| `TextOut` | `(int x, int y, string text, uint clr, uint alignment=0)` → `void` | All text rendering |
| `FontSet` | `(string name, int size, uint flags=0, uint angle=0)` → `bool` | Font switching (Segoe UI, sizes, bold) |
| `LineHorizontal` | `(int x1, int x2, int y, uint clr)` → `void` | Separator lines, panel dividers |
| `TextWidth` | `(string text)` → `int` | Center-aligning text |
| `FontSizeGet` | `()` → `int` | Read current font state |
| `Destroy` | `()` → `void` | Teardown (called in OnDeinit) |

**Color format**: `COLOR_FORMAT_ARGB_NORMALIZE` — required for semi-transparent glassmorphism effects.

**Built-in helper**: `ColorToARGB(color clr, uchar alpha)` — MQL5 built-in, converts `color` + alpha (0-255) to `uint` ARGB.

**Click detection**: `ObjectSetInteger(0, canvasName, OBJPROP_SELECTABLE, true)` makes CCanvas clickable. Button coordinates are canvas-relative (offset by panel X,Y from chart coordinates).

## BayesianUI Patterns to Reuse (from PrecisionSniper)

The file `Expert/EA_PrecisionSniper/UI/BayesianUI.mqh` (408 lines) provides proven patterns:

1. **Init pattern**: `CreateBitmapLabel` → `Erase(transparent)` → `Update()` → set selectable → set `g_canvasCreated = true`
2. **Redraw pattern**: `Erase(transparent)` → `FillRectangle(bg)` → `Rectangle(border)` → header → tabs → content → buttons → `Update()`
3. **Tab state**: Global `g_bayTab` integer (0-3), driven by click zones
4. **Button zones**: `#define` macros for X1,Y1,X2,Y2 — checked in `OnChartEvent` handler with `mx,my` relative to panel origin
5. **Font switching**: `FontSet("Segoe UI", size, flags)` — called before each `TextOut` (not persisting across calls) — **NOTE: this is expensive — batch text by font to reduce FontSet calls**
6. **Progress bars**: `FillRectangle(x, y, x+barW, y+18, color)` + `Rectangle(x, y, x+maxW, y+18, dim)` for outline
7. **Glassmorphism**: Uses translucent fills (`ColorToARGB(clr, alpha)` with alpha < 255) over dark background
8. **Color palette**: `BAY_BG`, `BAY_BORDER`, `BAY_ACCENT`, `BAY_GREEN`, `BAY_RED`, `BAY_AMBER`, `BAY_WHITE`, `BAY_GRAY`, `BAY_DIM`, `BAY_DARK`, `BAY_HEADERBG`, `BAY_GLOW` — all terminal-hacker green-on-black
9. **State sync**: `SyncBayState()` function copies indicator data and market values into dashboard globals before draw — separates data collection from rendering

## Approaches

### 1. Class-Based Dashboard (Recommended)

Wrap the CCanvas instance and all dashboard state in a `CProDashboard` class in `UI/ProDashboard.mqh`.

```cpp
class CProDashboard {
private:
   CCanvas m_canvas;
   bool    m_created;
   int     m_tab;        // 0=TRADES, 1=ESTRATEGIAS, 2=STATS, 3=CONFIG
   int     m_width, m_height;
   int     m_x, m_y;
   // State cache (updated before draw)
   double  m_scoreRange, m_scoreNyao, m_scoreBB, m_scoreWick;
   // Button zones as member structs

   void DrawHeader();
   void DrawTabs();
   void DrawTabTrades(int &y);
   void DrawTabEstrategias(int &y);
   void DrawTabStats(int &y);
   void DrawTabConfig(int &y);
   void DrawButtons(int &y);
   void DrawProgressBar(int x, int y, int w, double pct, uint fillClr, uint outlineClr);
public:
   CProDashboard();
   ~CProDashboard();
   bool Init(int x, int y, int w, int h);
   void SyncState();         // Pull data from globals
   void Draw();              // Full redraw
   void HandleClick(int mx, int my); // Button dispatch
   void SetVisible(bool v);
   void Destroy();
};
```

- **Pros**: Encapsulation, clean namespace, reusable, no globals (except the single `g_dashboard` instance), matches OOP patterns used elsewhere
- **Cons**: MQL5 classes have some limitations (no virtual methods across .mqh boundaries), slightly more verbose
- **Effort**: Medium

### 2. Procedural with Namespaced Globals (BayesianUI Pattern)

Follow BayesianUI.mqh exactly: all dashboard functions and state as module-level globals with `g_dash*` prefix. No class.

```cpp
// Global state
int    g_dashTab = 0;
CCanvas g_dashCanvas;
bool   g_dashCreated = false;
double g_dashScoreRange, g_dashScoreNyao, g_dashScoreBB, g_dashScoreWick;

void InitDashboard();
void SyncDashboardState();
void DrawDashboard();
void HandleDashboardClick(int mx, int my);
void ClearDashboard();
```

- **Pros**: Proven pattern (BayesianUI.mqh works and compiles), simpler to understand, direct global access to all trading globals
- **Cons**: Namespace pollution, all state exposed as globals, harder to test in isolation
- **Effort**: Low

### Recommendation: Approach 1 (Class-Based)

Rationale:
- The 4-tab design is complex enough that encapsulation pays off
- Class-based avoids potential naming conflicts (RangeScalper already has 40+ globals)
- Single `#include` in the main EA, single `g_dashboard` global
- Aligns with the AGENTS.md rule: "Modular architecture — .mqh by responsibility"
- The class can be forward-declared in the EA, keeping the EA file clean

## File Structure

```
Expert/EA_RangeScalper/
├── RangeScalper_EA.mq5          ← Remove DrawPanel(), RLabel(); add #include "UI/ProDashboard.mqh", OnChartEvent, dashboard calls
├── UI/
│   └── ProDashboard.mqh         ← NEW: CProDashboard class + colors, dimensions, button zones
├── Core/
│   └── Definitions.mqh          ← Unchanged (all globals already accessible)
├── Signals/
│   ├── RangeSignals.mqh         ← Unchanged
│   ├── NyaoScorer.mqh           ← Unchanged
│   ├── BBScalper.mqh            ← Unchanged
│   └── WickScalper.mqh          ← Unchanged
└── Engine/
    └── ScalpEngine.mqh          ← Unchanged
```

## Dashboard Layout Design

```
┌──────────────────────────────────────┐ 360x580 px (same as BayesianUI)
│ RANGE SCALPER            HH:MM:SS    │ Header (0-50)
├──────┬──────┬──────┬──────┤
│TRADES│ESTRAT│STATS │CONFIG│          │ Tab bar (54-82)
├──────┴──────┴──────┴──────┤
│                            │
│  [Tab Content Area]        │          │ Content (96-520)
│                            │
├────────────────────────────┤
│[CERRAR TODO] [DETENER] [▼]│          │ Bottom buttons (522-580)
└────────────────────────────┘
```

### Tab Content Specifications

**TAB 0 — TRADES**: Active position info (LONG/SHORT + entry/SL/TP + unrealized P&L + pips), or "VIGILANDO..." when flat. Direction bias (ALCISTA/BAJISTA/NEUTRAL). Session time. Spread status.

**TAB 1 — ESTRATEGIAS**: 4 strategy cards, each showing:
- Strategy name + active signal (BUY/SELL/—)  
- Progress bar for score (0-100 normalized)
- For Nyao: raw score display
- For Range/BB/Wick: binary state (SOBRECOMPRA/SOBREVENTA/NEUTRAL)
- Current range info (high/low)

**TAB 2 — STATS**: Win/loss ratio, total trades, gross profit, gross loss, net P&L, win rate %, daily trades used/max, average trade R, best/worst R, profit factor.

**TAB 3 — CONFIG**: Read-only display of all input parameters (RangeLookback, ATRPeriod, TPDollars, SLMult, MaxBarsWait, Lots, Magic, MaxSpread, MaxDailyTrades, CooldownBars). Indicator status (ATR OK/FAIL, EMA OK/FAIL, RSI OK/FAIL, BB OK/FAIL).

## Button Zone Map

| Button | Zone (canvas-relative) | Action |
|--------|----------------------|--------|
| Tab 0 (TRADES) | (10,54)-(96,82) | Switch to TRADES tab |
| Tab 1 (ESTRAT) | (104,54)-(190,82) | Switch to ESTRATEGIAS tab |
| Tab 2 (STATS) | (198,54)-(284,82) | Switch to STATS tab |
| Tab 3 (CONFIG) | (292,54)-(354,82) | Switch to CONFIG tab |
| Close All | (10,522)-(105,552) | Emergency close all positions |
| Stop/Show | (115,522)-(210,552) | Toggle dashboard visibility |
| Reset Stats | (220,522)-(354,552) | Reset trade statistics |

## Color Palette (Terminal Hacker Green-on-Black)

```cpp
#define DASH_BG       ColorToARGB(C'4,10,6', 238)
#define DASH_BORDER   ColorToARGB(C'0,140,50', 180)
#define DASH_ACCENT   ColorToARGB(C'0,255,65', 255)
#define DASH_GREEN    ColorToARGB(C'0,230,80', 255)
#define DASH_RED      ColorToARGB(C'255,55,55', 255)
#define DASH_AMBER    ColorToARGB(C'255,200,40', 255)
#define DASH_WHITE    ColorToARGB(C'200,255,200', 255)
#define DASH_GRAY     ColorToARGB(C'100,160,110', 200)
#define DASH_DIM      ColorToARGB(C'60,110,70', 180)
#define DASH_DARK     ColorToARGB(C'2,6,3', 245)
#define DASH_HEADERBG ColorToARGB(C'0,80,30', 50)
```

## Functions Needed

### In ProDashboard.mqh (CProDashboard class):

| Function | Purpose |
|----------|---------|
| `CProDashboard()` | Constructor, init members to defaults |
| `~CProDashboard()` | Destructor, calls Destroy() |
| `bool Init(int x, int y, int w, int h)` | Create bitmap label, erase, set selectable |
| `void SyncState()` | Copy trading globals → member state cache |
| `void Draw()` | Full redraw: erase → bg → header → tabs → content → buttons → update |
| `void DrawHeader()` | Title "RANGE SCALPER" + timestamp + accent lines |
| `void DrawTabs()` | 4 tab buttons with active highlight |
| `void DrawTabTrades(int &y)` | Active position or waiting status |
| `void DrawTabEstrategias(int &y)` | 4 strategy cards with scores/progress bars |
| `void DrawTabStats(int &y)` | Trade statistics display |
| `void DrawTabConfig(int &y)` | Input parameters read-only display |
| `void DrawBottomButtons()` | Close All, Toggle, Reset buttons |
| `void DrawProgressBar(int x, int y, int w, int h, double pct, uint fillClr, uint outlineClr)` | Reusable progress bar widget |
| `void HandleClick(int mx, int my)` | Button zone dispatch |
| `void SetVisible(bool v)` | Show/hide canvas object |
| `void Destroy()` | ObjectDelete + ResourceFree |

### In RangeScalper_EA.mq5:

| Function | Change |
|----------|--------|
| `OnInit()` | Add `g_dashboard.Init(BX, BY, BW, BH)` after indicator init |
| `OnTick()` | Replace `DrawPanel()` call with `g_dashboard.SyncState(); g_dashboard.Draw();` |
| `OnDeinit()` | Add `g_dashboard.Destroy()` after `ObjectsDeleteAll(0, "rsp_")` |
| `OnChartEvent()` | NEW: forward canvas clicks to `g_dashboard.HandleClick(mx, my)` |
| `DrawPanel()` | REMOVE entirely |
| `RLabel()` | REMOVE entirely |

## Risks

1. **OnTick Budget**: BayesianUI redraws at ~15-25ms per frame (with FontSet calls). RangeScalper needs <50ms budget. **Mitigation**: Batch text rendering by font to minimize FontSet() calls; throttle redraw to once per second instead of every 2s.
2. **ARGB vs XRGB**: Current panel uses XRGB internally. ProDashboard must use `COLOR_FORMAT_ARGB_NORMALIZE` for glassmorphism, which changes pixel format. **Mitigation**: Verified API supports both; color macros use `ColorToARGB()` with explicit alpha.
3. **Global Name Collisions**: If dashboard globals overlap with existing 40+ globals, hard-to-debug issues arise. **Mitigation**: Class-based approach eliminates this; only one global `g_dashboard` added. All dashboard state is member variables.
4. **Compilation Dependency**: `#include <Canvas/Canvas.mqh>` adds ~5KB of code. **Mitigation**: MQL5's `#include` behavior caches; no measurable impact on compile time.
5. **ChartEvent Interference**: If other EAs/indicators on the same chart also use CHARTEVENT_CLICK, there could be conflicts. **Mitigation**: Canvas-specific handler uses `CHARTEVENT_OBJECT_CLICK` with `sparam == "dash_canvas"` as primary filter; CHARTEVENT_CLICK is fallback. Canvas-relative coordinates isolate button zones.

## Ready for Proposal

**Yes**. The API is verified, the data inventory is complete, the BayesianUI patterns are confirmed working on this exact MT5 instance, and the file structure is clear. Next phase: `sdd-propose` to define scope, approach, and rollback plan.
