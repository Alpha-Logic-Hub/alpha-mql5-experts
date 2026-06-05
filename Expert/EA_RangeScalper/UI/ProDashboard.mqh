//+------------------------------------------------------------------+
//|                                            UI/ProDashboard.mqh     |
//|        RangeScalper — Pro Dashboard (CCanvas, Glassmorphism)       |
//+------------------------------------------------------------------+
#ifndef _PRO_DASHBOARD_
#define _PRO_DASHBOARD_

#include <Canvas/Canvas.mqh>
#include <Trade/Trade.mqh>

// ── Dimensions ──────────────────────────────────────────────────────
#define PD_W  340
#define PD_H  520
#define PD_X  10
#define PD_Y  10
#define PD_NAME "dash_canvas"

// ── Colors (ARGB) — Terminal Green-on-Black ────────────────────────
#define PD_BG        ColorToARGB(C'4,10,6', 238)
#define PD_BORDER    ColorToARGB(C'0,140,50', 180)
#define PD_ACCENT    ColorToARGB(C'0,255,65', 255)
#define PD_GREEN     ColorToARGB(C'0,230,80', 255)
#define PD_RED       ColorToARGB(C'255,55,55', 255)
#define PD_AMBER     ColorToARGB(C'255,200,40', 255)
#define PD_WHITE     ColorToARGB(C'200,255,200', 255)
#define PD_GRAY      ColorToARGB(C'100,160,110', 200)
#define PD_DIM       ColorToARGB(C'60,110,70', 180)
#define PD_DARK      ColorToARGB(C'2,6,3', 245)
#define PD_HEADERBG  ColorToARGB(C'0,80,30', 50)
#define PD_TABBG     ColorToARGB(C'0,25,10', 140)
#define PD_TABACT    ColorToARGB(C'0,100,40', 180)
#define PD_CARDBG    ColorToARGB(C'5,20,10', 200)
#define PD_BTNRED    ColorToARGB(C'80,15,15', 220)
#define PD_BTNAMB    ColorToARGB(C'60,40,8', 220)
#define PD_BTNGRN    ColorToARGB(C'10,50,15', 220)

//+------------------------------------------------------------------+
//| CProDashboard class                                               |
//+------------------------------------------------------------------+
class CProDashboard
{
private:
   CCanvas  m_canvas;
   bool     m_created;
   int      m_tab;       // 0=TRADES, 1=ESTRATEGIAS, 2=STATS, 3=CONFIG
   bool     m_visible;

   // ── Drawing helpers ───────────────────────────────────────────
   void DrawHeader();
   void DrawTabs();
   void DrawTabTrades(int &y);
   void DrawTabEstrategias(int &y);
   void DrawTabStats(int &y);
   void DrawTabConfig(int &y);
   void DrawBottomButtons();
   void DrawProgressBar(int x, int y, int w, int h, double pct,
                        uint fillClr, uint outlineClr);

public:
   CProDashboard();
   ~CProDashboard();
   bool InitCanvas();
   void UpdateDashboard();
   void ClearDashboard();
   bool HandleClick(int mx, int my);
   void SetVisible(bool v)   { m_visible = v; }
   bool IsVisible() const    { return m_visible; }
   int  GetTab() const       { return m_tab; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CProDashboard::CProDashboard()
{
   m_created = false;
   m_tab     = 0;
   m_visible = true;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CProDashboard::~CProDashboard()
{
   ClearDashboard();
}

//+------------------------------------------------------------------+
//| InitCanvas — create CCanvas bitmap label                          |
//+------------------------------------------------------------------+
bool CProDashboard::InitCanvas()
{
   if(m_created)
      return true;

   if(!m_canvas.CreateBitmapLabel(0, 0, PD_NAME, PD_X, PD_Y, PD_W, PD_H,
                                   COLOR_FORMAT_ARGB_NORMALIZE))
   {
      Print("[Dashboard] ERROR: Failed to create canvas");
      return false;
   }

   m_canvas.Erase(ColorToARGB(clrBlack, 0));
   m_canvas.Update();

   ObjectSetInteger(0, PD_NAME, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, PD_NAME, OBJPROP_SELECTED, true);
   ObjectSetString(0, PD_NAME, OBJPROP_TOOLTIP, "ProDashboard — RangeScalper");

   m_created = true;
   Print("[Dashboard] Canvas created (", PD_W, "x", PD_H, ")");
   return true;
}

//+------------------------------------------------------------------+
//| ClearDashboard — destroy canvas object                            |
//+------------------------------------------------------------------+
void CProDashboard::ClearDashboard()
{
   if(!m_created)
      return;

   ObjectDelete(0, PD_NAME);
   m_created = false;
}

//+------------------------------------------------------------------+
//| HandleClick — process canvas clicks, returns true if handled      |
//|                                                                   |
//| Coordinates (mx, my) are chart-absolute. We subtract PD_X/PD_Y    |
//| to get canvas-relative coordinates for hit testing.               |
//+------------------------------------------------------------------+
bool CProDashboard::HandleClick(int mx, int my)
{
   if(!m_created || !m_visible)
      return false;

   // Convert to canvas-relative coordinates
   int cx = mx - PD_X;
   int cy = my - PD_Y;
   Print("[Dashboard] Click at canvas (", cx, ",", cy, ")");

   // ── Tab buttons (row at y=54..82) ─────────────────────────────
   if(cy >= 54 && cy <= 82)
   {
      if(cx >= 10 && cx <= 90)        { m_tab = 0; return true; }
      else if(cx >= 98 && cx <= 178)  { m_tab = 1; return true; }
      else if(cx >= 186 && cx <= 266) { m_tab = 2; return true; }
      else if(cx >= 274 && cx <= 330) { m_tab = 3; return true; }
   }

   // ── Bottom buttons (row at PD_H-54..PD_H-28) ──────────────────
   int btnY = PD_H - 54;
   if(cy >= btnY && cy <= btnY + 26)
   {
      // Close All button (10..105)
      if(cx >= 10 && cx <= 105)
      {
         CTrade trade;
         int closed = 0;
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0)
               continue;
            if(!PositionSelectByTicket(ticket))
               continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol)
               continue;
            if(trade.PositionClose(ticket))
               closed++;
         }
         if(closed > 0)
         {
            Print("[Dashboard] Emergency close-all: ", closed, " position(s) closed");
            // Reset trade state globals
            g_tradeOpen = false;
            g_dir       = 0;
            g_ticket    = 0;
         }
         else
         {
            Print("[Dashboard] Close-all: no positions to close");
         }
         return true;
      }
      // Toggle visibility button (115..210)
      else if(cx >= 115 && cx <= 210)
      {
         m_visible = !m_visible;
         if(!m_visible)
            ClearDashboard();
         Print("[Dashboard] Visibility: ", m_visible ? "ON" : "OFF");
         return true;
      }
      // Reset stats button (220..330)
      else if(cx >= 220 && cx <= 330)
      {
         g_statTotal   = 0;
         g_statWins    = 0;
         g_statLosses  = 0;
         g_statProfit  = 0;
         g_statLoss    = 0;
         g_dailyTrades = 0;
         Print("[Dashboard] Stats reset to zero");
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| UpdateDashboard — full redraw (reads globals, throttled by EA)    |
//|                                                                   |
//| Pipeline: erase → bg → header → tabs → content → buttons → update |
//+------------------------------------------------------------------+
void CProDashboard::UpdateDashboard()
{
   // ── Visibility gate ───────────────────────────────────────────
   if(!m_visible)
   {
      if(m_created)
         ClearDashboard();
      return;
   }

   // ── Auto-init ─────────────────────────────────────────────────
   if(!m_created && !InitCanvas())
      return;

   // ── Erase + background ────────────────────────────────────────
   m_canvas.Erase(ColorToARGB(clrBlack, 0));
   m_canvas.FillRectangle(0, 0, PD_W, PD_H, PD_BG);
   m_canvas.Rectangle(0, 0, PD_W - 1, PD_H - 1, PD_BORDER);
   m_canvas.Rectangle(1, 1, PD_W - 2, PD_H - 2, PD_BORDER);

   // ── Render layers ─────────────────────────────────────────────
   DrawHeader();
   DrawTabs();

   int y = 96;
   switch(m_tab)
   {
      case 0:  DrawTabTrades(y);      break;
      case 1:  DrawTabEstrategias(y);  break;
      case 2:  DrawTabStats(y);        break;
      case 3:  DrawTabConfig(y);       break;
   }

   DrawBottomButtons();

   // ── Commit to screen ──────────────────────────────────────────
   m_canvas.Update();
}

//+------------------------------------------------------------------+
//| DrawHeader — title bar with timestamp                            |
//+------------------------------------------------------------------+
void CProDashboard::DrawHeader()
{
   m_canvas.FillRectangle(0, 0, PD_W, 50, PD_HEADERBG);

   m_canvas.FontSet("Segoe UI", 17, FW_BOLD);
   m_canvas.TextOut(14, 12, "RANGE SCALPER", PD_ACCENT);

   m_canvas.FontSet("Segoe UI", 11);
   string ts = TimeToString(TimeCurrent(), TIME_MINUTES | TIME_SECONDS);
   m_canvas.TextOut(PD_W - 85, 16, ts, PD_DIM);

   m_canvas.LineHorizontal(0, PD_W - 1, 50, PD_BORDER);
}

//+------------------------------------------------------------------+
//| DrawTabs — 4 tab buttons with active highlight                    |
//+------------------------------------------------------------------+
void CProDashboard::DrawTabs()
{
   string tabs[4]  = {"TRADES", "ESTRATEGIAS", "STATS", "CONFIG"};
   int    tabX[4]  = {10, 98, 186, 274};
   int    tabW[4]  = {80, 80, 80, 56};
   int    ty       = 54;
   int    th       = 28;

   for(int t = 0; t < 4; t++)
   {
      bool   active = (t == m_tab);
      uint   bg     = active ? PD_TABACT : PD_TABBG;
      uint   tc     = active ? PD_ACCENT : PD_DIM;
      uint   flags  = active ? FW_BOLD : FW_NORMAL;

      m_canvas.FillRectangle(tabX[t], ty, tabX[t] + tabW[t], ty + th, bg);
      m_canvas.Rectangle(tabX[t], ty, tabX[t] + tabW[t], ty + th, PD_BORDER);
      m_canvas.FontSet("Segoe UI", 12, flags);
      m_canvas.TextOut(tabX[t] + 6, ty + 6, tabs[t], tc);
   }

   m_canvas.LineHorizontal(0, PD_W - 1, ty + th, PD_BORDER);
}

//+------------------------------------------------------------------+
//| DrawTabTrades — active position state, P&L, range info            |
//+------------------------------------------------------------------+
void CProDashboard::DrawTabTrades(int &y)
{
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) / _Point;

   // ── Section header ────────────────────────────────────────────
   m_canvas.FontSet("Segoe UI", 16, FW_BOLD);
   m_canvas.TextOut(16, y, "POSICION", PD_ACCENT);
   y += 30;

   if(g_tradeOpen)
   {
      // Active position
      string dirTxt = (g_dir == 1) ? "LONG" : "SHORT";
      uint   dirClr = (g_dir == 1) ? PD_GREEN : PD_RED;

      m_canvas.FontSet("Segoe UI", 18, FW_BOLD);
      m_canvas.TextOut(16, y, dirTxt, dirClr);
      y += 30;

      // Entry / SL / TP
      m_canvas.FontSet("Segoe UI", 13);
      m_canvas.TextOut(16, y,
         StringFormat("Entry: %.5f  |  SL: %.5f  |  TP: %.5f",
                      g_entry, g_sl, g_tp), PD_GRAY);
      y += 22;

      // Unrealized P&L
      // Formula: PnL = (currentPrice - entry) * direction * lotSize * 100
      // For LONG: (bid - entry); For SHORT: (entry - ask)
      double pnl = 0;
      if(g_dir == 1)
         pnl = (bid - g_entry) * g_lotSize * 100.0;
      else
         pnl = (g_entry - ask) * g_lotSize * 100.0;

      uint pnlClr = (pnl >= 0) ? PD_GREEN : PD_RED;
      m_canvas.FontSet("Segoe UI", 15, FW_BOLD);
      m_canvas.TextOut(16, y, StringFormat("P&L: $%.2f", pnl), pnlClr);
      y += 26;

      // Lot size
      m_canvas.FontSet("Segoe UI", 12);
      m_canvas.TextOut(16, y, StringFormat("Lot: %.2f  |  Ticket: %d", g_lotSize, g_ticket), PD_DIM);
      y += 22;
   }
   else
   {
      // Flat — no position
      m_canvas.FontSet("Segoe UI", 17, FW_BOLD);
      m_canvas.TextOut(16, y, "VIGILANDO...", PD_GRAY);
      y += 32;

      // Direction bias
      string bias = "NEUTRAL";
      uint   biasC = PD_AMBER;
      if(g_overHigh)      { bias = "BAJISTA (espera SELL)"; biasC = PD_RED; }
      else if(g_overLow)  { bias = "ALCISTA (espera BUY)";  biasC = PD_GREEN; }

      m_canvas.FontSet("Segoe UI", 14);
      m_canvas.TextOut(16, y, "Sesgo: " + bias, biasC);
      y += 28;
   }

   // ── Market info (shared) ──────────────────────────────────────
   m_canvas.LineHorizontal(16, PD_W - 16, y, PD_DIM);
   y += 6;

   m_canvas.FontSet("Segoe UI", 13);
   m_canvas.TextOut(16, y,
      StringFormat("Rango: %.2f  —  %.2f", g_rangeLow, g_rangeHigh), PD_GRAY);
   y += 20;

   uint   spreadClr = (spread > g_maxSpread) ? PD_RED : PD_DIM;
   m_canvas.TextOut(16, y,
      StringFormat("Spread: %.1f pts  |  Max: %.0f", spread, g_maxSpread), spreadClr);
   y += 20;

   m_canvas.TextOut(16, y,
      StringFormat("Cooldown: %d / %d  |  Diario: %d / %d",
                   g_cooldown, CooldownBars, g_dailyTrades, MaxDailyTrades), PD_DIM);
}

//+------------------------------------------------------------------+
//| DrawTabEstrategias — 4 strategy cards with scores, signals        |
//+------------------------------------------------------------------+
void CProDashboard::DrawTabEstrategias(int &y)
{
   m_canvas.FontSet("Segoe UI", 16, FW_BOLD);
   m_canvas.TextOut(16, y, "ESTRATEGIAS", PD_ACCENT);
   y += 30;

   // ── Strategy data arrays ──────────────────────────────────────
   string names[6] = {"RANGE","NYAO","BOLLINGER","WICK","SAR","STOCH"};
   string statuses[6] = {"","","","","",""};
   uint   statusC[6]  = {PD_DIM,PD_DIM,PD_DIM,PD_DIM,PD_DIM,PD_DIM};
   double scores[6] = {0,0,0,0,0,0};

   // ── Range strategy ────────────────────────────────────────────
   if(g_overHigh)
   {
      statuses[0] = "SOBRECOMPRA";
      statusC[0]  = PD_RED;
      scores[0]   = 85.0;
   }
   else if(g_overLow)
   {
      statuses[0] = "SOBREVENTA";
      statusC[0]  = PD_GREEN;
      scores[0]   = 85.0;
   }
   else
   {
      statuses[0] = "NEUTRAL";
      statusC[0]  = PD_DIM;
      scores[0]   = (g_rangeHigh > 0) ? 20.0 : 0;
   }

   // ── Nyao strategy ─────────────────────────────────────────────
   scores[1] = g_nyaoScore * 10.0;  // 0-10 → 0-100
   if(g_nyaoLong)
   {
      statuses[1] = "LONG  ^";
      statusC[1]  = PD_GREEN;
   }
   else if(g_nyaoShort)
   {
      statuses[1] = "SHORT v";
      statusC[1]  = PD_RED;
   }
   else
   {
      statuses[1] = "—";
      statusC[1]  = PD_DIM;
      if(scores[1] < 5) scores[1] = 5;
   }

   // ── Bollinger strategy ────────────────────────────────────────
   if(g_bbOverUpper)
   {
      statuses[2] = "TOQUE ^";
      statusC[2]  = PD_RED;
      scores[2]   = 80.0;
   }
   else if(g_bbUnderLower)
   {
      statuses[2] = "TOQUE v";
      statusC[2]  = PD_GREEN;
      scores[2]   = 80.0;
   }
   else
   {
      statuses[2] = "—";
      statusC[2]  = PD_DIM;
      scores[2]   = 20.0;
   }

   // ── Wick strategy ─────────────────────────────────────────────
   if(g_wickLong)
   {
      statuses[3] = "LONG  ^";
      statusC[3]  = PD_GREEN;
      scores[3]   = 90.0;
   }
   else if(g_wickShort)
   {
      statuses[3] = "SHORT v";
      statusC[3]  = PD_RED;
      scores[3]   = 90.0;
   }
   else
   {
      statuses[3] = "—";
      statusC[3]  = PD_DIM;
      scores[3]   = 30.0;
   }

   // ── SAR strategy ────────────────────────────────────────────────
   if(g_sarLong)        { statuses[4]="LONG";  statusC[4]=PD_GREEN; scores[4]=80; }
   else if(g_sarShort)  { statuses[4]="SHORT"; statusC[4]=PD_RED;   scores[4]=80; }
   else                 { statuses[4]="—";      statusC[4]=PD_DIM;   scores[4]=30; }

   // ── Stoch strategy ──────────────────────────────────────────────
   if(g_stochLong)      { statuses[5]="LONG";  statusC[5]=PD_GREEN; scores[5]=80; }
   else if(g_stochShort){ statuses[5]="SHORT"; statusC[5]=PD_RED;   scores[5]=80; }
   else                 { statuses[5]="—";      statusC[5]=PD_DIM;   scores[5]=30; }

   // ── Render cards ──────────────────────────────────────────────
   int cardH = 52;
   for(int s = 0; s < 6; s++)
   {
      int cx = 16;
      int cw = PD_W - 32;
      int cy = y;

      // Card background
      m_canvas.FillRectangle(cx, cy, cx + cw, cy + cardH - 2, PD_CARDBG);
      m_canvas.Rectangle(cx, cy, cx + cw, cy + cardH - 2, PD_BORDER);

      // Strategy name + status
      m_canvas.FontSet("Segoe UI", 13, FW_BOLD);
      m_canvas.TextOut(cx + 8, cy + 6, names[s], PD_WHITE);

      m_canvas.FontSet("Segoe UI", 13, FW_BOLD);
      m_canvas.TextOut(cx + 120, cy + 6, statuses[s], statusC[s]);

      // Nyao raw score display
      if(s == 1)
      {
         m_canvas.FontSet("Segoe UI", 11);
         m_canvas.TextOut(cx + 210, cy + 6,
            StringFormat("%.1f/10", g_nyaoScore),
            g_nyaoScore >= g_nyaoMinScoreBuy ? PD_GREEN : PD_DIM);
      }

      // Progress bar
      DrawProgressBar(cx + 8, cy + 28, cw - 16, 16,
         scores[s] / 100.0,
         scores[s] > 65 ? PD_GREEN : scores[s] > 35 ? PD_AMBER : PD_RED,
         PD_DIM);

      // Score text
      m_canvas.FontSet("Segoe UI", 11);
      m_canvas.TextOut(cx + 8, cy + 48,
         StringFormat("Score: %.0f%%", scores[s]), PD_DIM);

      y += cardH;
   }
}

//+------------------------------------------------------------------+
//| DrawTabStats — win rate, profit factor, totals, daily count       |
//+------------------------------------------------------------------+
void CProDashboard::DrawTabStats(int &y)
{
   m_canvas.FontSet("Segoe UI", 16, FW_BOLD);
   m_canvas.TextOut(16, y, "ESTADISTICAS", PD_ACCENT);
   y += 32;

   if(g_statTotal > 0)
   {
      double wr = (double)g_statWins / (double)g_statTotal * 100.0;
      double net = g_statProfit - g_statLoss;
      double pf  = (g_statLoss > 0) ? (g_statProfit / g_statLoss) :
                   (g_statProfit > 0) ? 99.0 : 0;

      // Win/Loss count
      m_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      m_canvas.TextOut(16, y,
         StringFormat("%d W  /  %d L  —  %d total",
                      g_statWins, g_statLosses, g_statTotal), PD_WHITE);
      y += 28;

      // Win rate
      m_canvas.FontSet("Segoe UI", 15);
      uint wrClr = wr > 50 ? PD_GREEN : wr > 40 ? PD_AMBER : PD_RED;
      m_canvas.TextOut(16, y,
         StringFormat("Win Rate: %.1f%%", wr), wrClr);
      y += 24;

      // Profit factor
      uint pfClr = pf > 1.3 ? PD_GREEN : pf > 1.0 ? PD_AMBER : PD_RED;
      m_canvas.TextOut(16, y,
         StringFormat("Profit Factor: %.2f", pf), pfClr);
      y += 24;

      // Separator
      m_canvas.LineHorizontal(16, PD_W - 16, y, PD_DIM);
      y += 6;

      // Gross P&L
      m_canvas.FontSet("Segoe UI", 13);
      m_canvas.TextOut(16, y,
         StringFormat("Gross Profit:  $%.2f", g_statProfit), PD_GREEN);
      y += 20;

      m_canvas.TextOut(16, y,
         StringFormat("Gross Loss:    $%.2f", g_statLoss), PD_RED);
      y += 20;

      m_canvas.FontSet("Segoe UI", 15, FW_BOLD);
      uint netClr = net >= 0 ? PD_GREEN : PD_RED;
      m_canvas.TextOut(16, y,
         StringFormat("NET:           $%.2f", net), netClr);
      y += 28;

      // Daily limit
      m_canvas.LineHorizontal(16, PD_W - 16, y, PD_DIM);
      y += 6;

      m_canvas.FontSet("Segoe UI", 13);
      uint dailyClr = (g_dailyTrades >= MaxDailyTrades) ? PD_RED : PD_DIM;
      m_canvas.TextOut(16, y,
         StringFormat("Diario: %d / %d", g_dailyTrades, MaxDailyTrades), dailyClr);
   }
   else
   {
      m_canvas.FontSet("Segoe UI", 17);
      m_canvas.TextOut(16, y, "Sin trades registrados", PD_DIM);
      y += 30;

      m_canvas.FontSet("Segoe UI", 14);
      m_canvas.TextOut(16, y, "Opera para ver estadisticas.", PD_DIM);
   }
}

//+------------------------------------------------------------------+
//| DrawTabConfig — read-only display of input parameters             |
//+------------------------------------------------------------------+
void CProDashboard::DrawTabConfig(int &y)
{
   m_canvas.FontSet("Segoe UI", 16, FW_BOLD);
   m_canvas.TextOut(16, y, "CONFIGURACION", PD_ACCENT);
   y += 32;

   // ── Strategy params ───────────────────────────────────────────
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(16, y, "Estrategia", PD_ACCENT);
   y += 22;

   m_canvas.FontSet("Segoe UI", 12);
   m_canvas.TextOut(16, y,
      StringFormat("Range Lookback: %d barras", g_rangeLookback), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("ATR Period:     %d", g_atrPeriod), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("TP:             $%.2f", g_tpDollars), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("SL Mult:        %.1fx", g_slMult), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("Max Bars Wait:  %d", MaxBarsWait), PD_GRAY);
   y += 24;

   // ── Risk params ───────────────────────────────────────────────
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(16, y, "Riesgo", PD_ACCENT);
   y += 22;

   m_canvas.FontSet("Segoe UI", 12);
   m_canvas.TextOut(16, y,
      StringFormat("Lot Size:       %.2f", g_lotSize), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("Magic Number:   %d", InpMagicNumber), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("Max Spread:     %.0f pts", g_maxSpread), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("Max Daily:      %d trades", MaxDailyTrades), PD_GRAY);
   y += 18;
   m_canvas.TextOut(16, y,
      StringFormat("Cooldown:       %d barras", CooldownBars), PD_GRAY);
   y += 24;

   // ── Indicator status ──────────────────────────────────────────
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(16, y, "Indicadores", PD_ACCENT);
   y += 22;

   m_canvas.FontSet("Segoe UI", 12);
   uint okC = PD_GREEN;
   uint failC = PD_RED;

   m_canvas.TextOut(16, y, "ATR:      " +
      ((hATR != INVALID_HANDLE) ? "OK" : "FAIL"),
      (hATR != INVALID_HANDLE) ? okC : failC);
   y += 18;

   m_canvas.TextOut(16, y, "EMA Fast: " +
      ((hEmaFast != INVALID_HANDLE) ? "OK" : "FAIL"),
      (hEmaFast != INVALID_HANDLE) ? okC : failC);
   y += 18;

   m_canvas.TextOut(16, y, "EMA Slow: " +
      ((hEmaSlow != INVALID_HANDLE) ? "OK" : "FAIL"),
      (hEmaSlow != INVALID_HANDLE) ? okC : failC);
   y += 18;

   m_canvas.TextOut(16, y, "RSI:      " +
      ((hRSI != INVALID_HANDLE) ? "OK" : "FAIL"),
      (hRSI != INVALID_HANDLE) ? okC : failC);
   y += 18;

   m_canvas.TextOut(16, y, "BB:       " +
      ((hBB_Upper != INVALID_HANDLE) ? "OK" : "FAIL"),
      (hBB_Upper != INVALID_HANDLE) ? okC : failC);
}

//+------------------------------------------------------------------+
//| DrawBottomButtons — emergency close, toggle, reset stats          |
//+------------------------------------------------------------------+
void CProDashboard::DrawBottomButtons()
{
   int btnY = PD_H - 54;
   int btnH = 26;

   m_canvas.LineHorizontal(0, PD_W - 1, btnY - 2, PD_BORDER);

   // Close All button
   m_canvas.FillRectangle(10, btnY, 105, btnY + btnH, PD_BTNRED);
   m_canvas.Rectangle(10, btnY, 105, btnY + btnH, PD_RED);
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(18, btnY + 5, "CERRAR TODO", PD_WHITE);

   // Toggle visibility button
   string visLabel = m_visible ? "OCULTAR" : "MOSTRAR";
   m_canvas.FillRectangle(115, btnY, 210, btnY + btnH, PD_BTNAMB);
   m_canvas.Rectangle(115, btnY, 210, btnY + btnH, PD_AMBER);
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(135, btnY + 5, visLabel, PD_WHITE);

   // Reset stats button
   m_canvas.FillRectangle(220, btnY, 330, btnY + btnH, PD_BTNGRN);
   m_canvas.Rectangle(220, btnY, 330, btnY + btnH, PD_ACCENT);
   m_canvas.FontSet("Segoe UI", 12, FW_BOLD);
   m_canvas.TextOut(228, btnY + 5, "REINICIAR", PD_WHITE);
}

//+------------------------------------------------------------------+
//| DrawProgressBar — reusable double-buffer progress widget          |
//|   x, y: top-left corner                                           |
//|   w, h: bar dimensions                                            |
//|   pct: 0.0 to 1.0 fill ratio                                      |
//+------------------------------------------------------------------+
void CProDashboard::DrawProgressBar(int x, int y, int w, int h,
                                     double pct, uint fillClr, uint outlineClr)
{
   if(pct < 0)   pct = 0;
   if(pct > 1.0) pct = 1.0;

   int fillW = (int)((double)w * pct);
   if(fillW < 2 && pct > 0) fillW = 2;

   m_canvas.FillRectangle(x, y, x + fillW, y + h, fillClr);
   m_canvas.Rectangle(x, y, x + w, y + h, outlineClr);
}

#endif // _PRO_DASHBOARD_
