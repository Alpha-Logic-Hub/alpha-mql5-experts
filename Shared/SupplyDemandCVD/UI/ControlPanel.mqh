//+------------------------------------------------------------------+
//| ControlPanel.mqh                                                  |
//| Interactive OBJ_BUTTON panel — toggle strategies, risk, metrics  |
//+------------------------------------------------------------------+

// --- Metrics tracker ---
int    g_totalTrades  = 0;
int    g_wins         = 0;
int    g_losses       = 0;
double g_totalPnL     = 0;
double g_maxDD        = 0;
double g_peakEquity   = 0;
double g_avgWin       = 0;
double g_avgLoss      = 0;
double g_sumWins      = 0;
double g_sumLosses    = 0;

// --- Runtime toggles (mirrors of inputs, modifiable at runtime) ---
bool   g_useSMC       = true;
bool   g_useShark     = true;
bool   g_useVP        = true;
bool   g_useSR        = true;
double g_riskPercent  = 0.15;
int    g_riskProfile  = 1;

// --- Button names ---
string g_btns[8] = {
   "ALH_BTN_SMC", "ALH_BTN_SHARK", "ALH_BTN_VP", "ALH_BTN_SR",
   "ALH_BTN_CLOSE", "ALH_BTN_RISKUP", "ALH_BTN_RISKDN", "ALH_BTN_PROFILE"
};

//+------------------------------------------------------------------+
//| CreateButton — helper to create a styled button                  |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int w, int h, color clr)
{
   if(ObjectFind(0, name) >= 0) return; // already exists

   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhite);
   ObjectSetString(0,  name, OBJPROP_TEXT, text);
   ObjectSetString(0,  name, OBJPROP_FONT, "Segoe UI Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| UpdateButtonText — refresh button appearance                     |
//+------------------------------------------------------------------+
void UpdateButtonText(string name, string text, bool active)
{
   if(ObjectFind(0, name) < 0) return;
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, active ? C'30,120,60' : C'80,40,40');
}

//+------------------------------------------------------------------+
//| InitControlPanel — create all buttons and metrics labels         |
//+------------------------------------------------------------------+
void InitControlPanel()
{
   // Sync runtime vars from inputs
   g_useSMC    = InpUseOTE;
   g_useShark  = InpUseMomentumBreakout;
   g_useVP     = InpUseVolumeProfile;
   g_useSR     = InpUseSupportResistance;
   g_riskPercent = InpRiskPercent;
   g_riskProfile = InpRiskProfile;

   int x = 295;  // right of HUD panel
   int y = 12;
   int bw = 80;
   int bh = 22;
   int gap = 3;

   // Row 1 — Strategy toggles
   CreateButton(g_btns[0], "SMC ON",  x, y, bw, bh, C'30,120,60');
   CreateButton(g_btns[1], "TIBURON ON",  x + bw + gap, y, bw+15, bh, C'30,120,60');
   CreateButton(g_btns[2], "VP ON",  x, y + bh + gap, bw, bh, C'30,120,60');
   CreateButton(g_btns[3], "SR OFF", x + bw + gap, y + bh + gap, bw+15, bh, C'80,40,40');

   // Row 2 — Actions
   y = y + 2*(bh + gap) + 5;
   CreateButton(g_btns[4], "CERRAR TODO", x, y, bw+25, bh+10, C'140,40,40');
   CreateButton(g_btns[5], "RISK +", x, y + bh + 12, 42, bh, C'50,50,120');
   CreateButton(g_btns[6], "RISK -", x + 44, y + bh + 12, 42, bh, C'50,50,120');
   CreateButton(g_btns[7], "PERFIL",  x + 90, y + bh + 12, 60, bh, C'80,60,20');
}

//+------------------------------------------------------------------+
//| RefreshControlPanel — update toggle states and metrics           |
//+------------------------------------------------------------------+
void RefreshControlPanel()
{
   UpdateButtonText(g_btns[0], g_useSMC ? "SMC ON" : "SMC OFF", g_useSMC);
   UpdateButtonText(g_btns[1], g_useShark ? "TIBURON ON" : "TIBURON OFF", g_useShark);
   UpdateButtonText(g_btns[2], g_useVP ? "VP ON" : "VP OFF", g_useVP);
   UpdateButtonText(g_btns[3], g_useSR ? "SR ON" : "SR OFF", g_useSR);

   // Update profile button
   string profName = "";
   switch(g_riskProfile) { case 0: profName = "CONS"; break; case 1: profName = "BAL"; break; case 2: profName = "AGRO"; break; default: profName = "MAN"; }
   ObjectSetString(0, g_btns[7], OBJPROP_TEXT, "PERFIL: " + profName);

   // Update metrics labels
   string met0 = "ALH_MET_0"; string met1 = "ALH_MET_1"; string met2 = "ALH_MET_2";
   double wr = (g_totalTrades > 0) ? (double)g_wins / g_totalTrades * 100.0 : 0;
   double pf = (g_sumLosses > 0) ? g_sumWins / g_sumLosses : 0;

   if(ObjectFind(0, met0) < 0) {
      int y2 = 148; int x2 = 295;
      ObjectCreate(0, met0, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, met0, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, met0, OBJPROP_XDISTANCE, x2); ObjectSetInteger(0, met0, OBJPROP_YDISTANCE, y2); ObjectSetInteger(0, met0, OBJPROP_FONTSIZE, 8); ObjectSetString(0, met0, OBJPROP_FONT, "Consolas");
      ObjectCreate(0, met1, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, met1, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, met1, OBJPROP_XDISTANCE, x2); ObjectSetInteger(0, met1, OBJPROP_YDISTANCE, y2 + 14); ObjectSetInteger(0, met1, OBJPROP_FONTSIZE, 8); ObjectSetString(0, met1, OBJPROP_FONT, "Consolas");
      ObjectCreate(0, met2, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, met2, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, met2, OBJPROP_XDISTANCE, x2); ObjectSetInteger(0, met2, OBJPROP_YDISTANCE, y2 + 28); ObjectSetInteger(0, met2, OBJPROP_FONTSIZE, 8); ObjectSetString(0, met2, OBJPROP_FONT, "Consolas");
   }

   color mc = (wr >= 50) ? clrMediumSpringGreen : clrTomato;
   ObjectSetString(0, met0, OBJPROP_TEXT, StringFormat("Trades: %d | Win: %.0f%% | PF: %.2f", g_totalTrades, wr, pf));
   ObjectSetInteger(0, met0, OBJPROP_COLOR, mc);
   ObjectSetString(0, met1, OBJPROP_TEXT, StringFormat("MaxDD: %.2f%% | AvgW: $%.0f | AvgL: $%.0f", g_maxDD, g_avgWin, g_avgLoss));
   ObjectSetInteger(0, met1, OBJPROP_COLOR, clrLightGray);
   ObjectSetString(0, met2, OBJPROP_TEXT, StringFormat("Risk: %.3f%% | P&L: $%.2f", g_riskPercent, g_totalPnL));
   ObjectSetInteger(0, met2, OBJPROP_COLOR, clrSandyBrown);
}

//+------------------------------------------------------------------+
//| RecordTrade — call after every closed position                   |
//+------------------------------------------------------------------+
void RecordTrade(double pnl)
{
   g_totalTrades++;
   g_totalPnL += pnl;

   if(pnl > 0) { g_wins++; g_sumWins += pnl; }
   else        { g_losses++; g_sumLosses += MathAbs(pnl); }

   g_avgWin  = (g_wins > 0)    ? g_sumWins / g_wins : 0;
   g_avgLoss = (g_losses > 0)  ? g_sumLosses / g_losses : 0;

   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_peakEquity) g_peakEquity = eq;
   if(g_peakEquity > 0) {
      double dd = (g_peakEquity - eq) / g_peakEquity * 100.0;
      if(dd > g_maxDD) g_maxDD = dd;
   }
}

//+------------------------------------------------------------------+
//| HandleButtonClick — process button events                       |
//+------------------------------------------------------------------+
bool HandleButtonClick(string objName)
{
   if(objName == g_btns[0]) { g_useSMC   = !g_useSMC;   return true; }
   if(objName == g_btns[1]) { g_useShark = !g_useShark; return true; }
   if(objName == g_btns[2]) { g_useVP    = !g_useVP;    return true; }
   if(objName == g_btns[3]) { g_useSR    = !g_useSR;    return true; }

   if(objName == g_btns[4]) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong t = PositionGetTicket(i);
         if(t > 0 && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            trade.PositionClose(t);
      }
      return true;
   }

   if(objName == g_btns[5]) { g_riskPercent = MathMin(1.0, g_riskPercent + 0.05); return true; }
   if(objName == g_btns[6]) { g_riskPercent = MathMax(0.05, g_riskPercent - 0.05); return true; }
   if(objName == g_btns[7]) { g_riskProfile = (g_riskProfile + 1) % 4; ApplyRiskProfile(g_state); return true; }

   return false;
}
