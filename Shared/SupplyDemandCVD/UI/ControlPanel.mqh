//+------------------------------------------------------------------+
//| TradeControlCenter.mqh                                            |
//| Interactive chart console — strategy toggles, manual actions,     |
//| risk sync, metrics, and safe confirmations.                       |
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

// --- Runtime state (mirrors inputs but can be changed from panel) ---
bool   g_panelAutoTrading = true;
bool   g_useSMC           = true;
bool   g_useShark         = true;
bool   g_useVP            = true;
bool   g_useSR            = true;
double g_riskPercent      = 0.15;
int    g_riskProfile      = 1;

// --- Safety confirmation state ---
string   g_pendingAction = "";
datetime g_pendingUntil  = 0;

// --- Layout ---
int g_panelX = 320;
int g_panelY = 12;
int g_panelW = 265;
int g_panelH = 275;

// --- Object names ---
string CP_PREFIX       = "ALH_CP_";
string BTN_AUTO        = "ALH_CP_BTN_AUTO";
string BTN_SMC         = "ALH_CP_BTN_SMC";
string BTN_SHARK       = "ALH_CP_BTN_SHARK";
string BTN_VP          = "ALH_CP_BTN_VP";
string BTN_SR          = "ALH_CP_BTN_SR";
string BTN_BUY         = "ALH_CP_BTN_BUY";
string BTN_SELL        = "ALH_CP_BTN_SELL";
string BTN_CLOSE_ALL   = "ALH_CP_BTN_CLOSE_ALL";
string BTN_RISK_UP     = "ALH_CP_BTN_RISK_UP";
string BTN_RISK_DOWN   = "ALH_CP_BTN_RISK_DOWN";
string BTN_PROFILE     = "ALH_CP_BTN_PROFILE";

//+------------------------------------------------------------------+
//| UI helpers                                                        |
//+------------------------------------------------------------------+
void CreatePanelLabel(string name, string text, int x, int y, color clr, int size=8, string font="Segoe UI")
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

void CreatePanelButton(string name, string text, int x, int y, int w, int h, color bg, color fg=clrWhite)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'180,210,210');
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

void SetPanelButton(string name, string text, bool active)
{
   color bg = active ? C'28,125,72' : C'95,45,45';
   CreatePanelButton(name, text, (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE),
                     (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE),
                     (int)ObjectGetInteger(0, name, OBJPROP_XSIZE),
                     (int)ObjectGetInteger(0, name, OBJPROP_YSIZE), bg);
}

void ClearPendingAction()
{
   g_pendingAction = "";
   g_pendingUntil = 0;
}

bool ArmOrConfirm(string action)
{
   datetime now = TimeLocal();
   if(g_pendingAction == action && now <= g_pendingUntil) {
      ClearPendingAction();
      return true;
   }

   g_pendingAction = action;
   g_pendingUntil = now + 12;
   Print("[TradeControlCenter] Confirm required: click ", action, " again within 12 seconds.");
   return false;
}

string RiskProfileName(int profile)
{
   switch(profile) {
      case 0: return "CONS";
      case 1: return "BAL";
      case 2: return "AGG";
      default: return "MAN";
   }
}

// Formula: effective risk = runtime risk percent multiplied by selected profile multiplier, capped at 1.0%.
// Example: g_riskPercent=0.20 and profile=2 (1.5x) => min(0.30, 1.0) = 0.30%.
void SyncRuntimeRiskState()
{
   double multiplier = 1.0;
   double rr = InpRR;
   double shield = InpShieldPercent;

   switch(g_riskProfile) {
      case 0: multiplier = 0.5; shield = 3.0; rr = 1.5; break;
      case 1: multiplier = 1.0; shield = 4.0; rr = 1.33; break;
      case 2: multiplier = 1.5; shield = 6.0; rr = 1.2; break;
      default: multiplier = 1.0; shield = InpShieldPercent; rr = InpRR; break;
   }

   g_state.effRiskPercent = MathMin(1.0, MathMax(0.01, g_riskPercent * multiplier));
   g_state.effShieldPercent = shield;
   g_state.effRR = rr;
}

//+------------------------------------------------------------------+
//| Trade actions                                                     |
//+------------------------------------------------------------------+
bool OpenManualPanelTrade(ENUM_ORDER_TYPE type)
{
   // Manual orders remain available when AUTO is OFF.
   // AUTO only blocks strategy-driven entries, not explicit trader actions.
   if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return false;
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) >= 1) {
      Print("[TradeControlCenter] Manual trade blocked: active position exists.");
      return false;
   }

   double slDist = GetMinStopDistance();
   double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
   ENUM_SIGNAL_TYPE sig = (type == ORDER_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
   string comment = (type == ORDER_TYPE_BUY) ? "PANEL_BUY" : "PANEL_SELL";

   bool ok = OpenTrade(sig, lot, slDist, InpRR, InpMagicNumber, comment, 30.0);
   if(ok) {
      Print("[TradeControlCenter] Manual ", EnumToString(type), " opened. Lot=", lot);
      lastTradeTime = TimeCurrent();
   }
   return ok;
}

void CloseAllPanelPositions()
{
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      if(g_trade.PositionClose(ticket)) {
         closed++;
      } else {
         Print("[TradeControlCenter] Close failed ticket=", ticket,
               " retcode=", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
      }
   }
   Print("[TradeControlCenter] Close all completed. Closed positions=", closed);
}

//+------------------------------------------------------------------+
//| Init / refresh / destroy                                          |
//+------------------------------------------------------------------+
void InitControlPanel()
{
   g_panelAutoTrading = true;
   g_useSMC = InpUseOTE;
   g_useShark = InpUseMomentumBreakout;
   g_useVP = InpUseVolumeProfile;
   g_useSR = InpUseSupportResistance;
   g_riskPercent = InpRiskPercent;
   g_riskProfile = InpRiskProfile;
   SyncRuntimeRiskState();

   string bg = CP_PREFIX + "BG";
   if(ObjectFind(0, bg) < 0) {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, g_panelX);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, g_panelY);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, g_panelW);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, g_panelH);
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_COLOR, C'45,85,88');
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'16,34,38');
      ObjectSetInteger(0, bg, OBJPROP_BACK, false);
   }

   CreatePanelLabel(CP_PREFIX + "TITLE", "ALPHA TRADE CONTROL", g_panelX + 12, g_panelY + 8, clrAqua, 9, "Segoe UI Bold");
   CreatePanelLabel(CP_PREFIX + "SUB", _Symbol + "  |  " + EnumToString((ENUM_TIMEFRAMES)_Period), g_panelX + 12, g_panelY + 25, clrLightGray, 8, "Consolas");

   int x = g_panelX + 12;
   int y = g_panelY + 62;
   int bw = 76;
   int bh = 22;
   int gap = 6;

   CreatePanelButton(BTN_AUTO, "AUTO ON", x, y, bw, bh, C'28,125,72');
   CreatePanelButton(BTN_SMC, "SMC ON", x + bw + gap, y, bw, bh, C'28,125,72');
   CreatePanelButton(BTN_SHARK, "SHARK ON", x + 2*(bw + gap), y, bw, bh, C'28,125,72');

   y += bh + gap;
   CreatePanelButton(BTN_VP, "VP ON", x, y, bw, bh, C'28,125,72');
   CreatePanelButton(BTN_SR, "SR ON", x + bw + gap, y, bw, bh, C'28,125,72');
   CreatePanelButton(BTN_PROFILE, "PROFILE", x + 2*(bw + gap), y, bw, bh, C'95,75,30');

   y += bh + gap + 6;
   CreatePanelButton(BTN_BUY, "BUY MKT", x, y, bw, bh + 4, C'20,105,70');
   CreatePanelButton(BTN_SELL, "SELL MKT", x + bw + gap, y, bw, bh + 4, C'145,55,55');
   CreatePanelButton(BTN_CLOSE_ALL, "CLOSE ALL", x + 2*(bw + gap), y, bw, bh + 4, C'145,40,40');

   y += bh + gap + 10;
   CreatePanelButton(BTN_RISK_DOWN, "RISK -", x, y, bw, bh, C'45,58,120');
   CreatePanelButton(BTN_RISK_UP, "RISK +", x + bw + gap, y, bw, bh, C'45,58,120');

   RefreshControlPanel();
}

void RefreshControlPanel()
{
   SyncRuntimeRiskState();

   SetPanelButton(BTN_AUTO, g_panelAutoTrading ? "AUTO ON" : "AUTO OFF", g_panelAutoTrading);
   SetPanelButton(BTN_SMC, g_useSMC ? "SMC ON" : "SMC OFF", g_useSMC);
   SetPanelButton(BTN_SHARK, g_useShark ? "SHARK ON" : "SHARK OFF", g_useShark);
   SetPanelButton(BTN_VP, g_useVP ? "VP ON" : "VP OFF", g_useVP);
   SetPanelButton(BTN_SR, g_useSR ? "SR ON" : "SR OFF", g_useSR);

   CreatePanelButton(BTN_BUY,
                     (g_pendingAction == "BUY") ? "CONFIRM BUY" : "BUY MKT",
                     g_panelX + 12, g_panelY + 124, 76, 26,
                     (g_pendingAction == "BUY") ? clrGold : C'20,105,70',
                     (g_pendingAction == "BUY") ? clrBlack : clrWhite);
   CreatePanelButton(BTN_SELL,
                     (g_pendingAction == "SELL") ? "CONFIRM SELL" : "SELL MKT",
                     g_panelX + 94, g_panelY + 124, 76, 26,
                     (g_pendingAction == "SELL") ? clrGold : C'145,55,55',
                     (g_pendingAction == "SELL") ? clrBlack : clrWhite);
   CreatePanelButton(BTN_CLOSE_ALL,
                     (g_pendingAction == "CLOSE_ALL") ? "CONFIRM" : "CLOSE ALL",
                     g_panelX + 176, g_panelY + 124, 76, 26,
                     (g_pendingAction == "CLOSE_ALL") ? clrGold : C'145,40,40',
                     (g_pendingAction == "CLOSE_ALL") ? clrBlack : clrWhite);

   string actionText = (g_pendingAction == "") ? "READY" : "CONFIRM: " + g_pendingAction;
   color actionColor = (g_pendingAction == "") ? clrMediumSpringGreen : clrGold;

   double wr = (g_totalTrades > 0) ? (double)g_wins / g_totalTrades * 100.0 : 0;
   double pf = (g_sumLosses > 0) ? g_sumWins / g_sumLosses : 0;
   int activePositions = CountActivePositions(InpMagicNumber, _Symbol, pos);
   double spreadPts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;

   CreatePanelLabel(CP_PREFIX + "STATE", actionText, g_panelX + 12, g_panelY + 45, actionColor, 8, "Segoe UI Bold");
   string sizingMode = (InpFixedLot > 0) ? StringFormat("FIXED %.2f", InpFixedLot) : StringFormat("Risk %.3f%% eff", g_state.effRiskPercent);
   CreatePanelLabel(CP_PREFIX + "RISK", StringFormat("%s | Profile %s | Pos %d", sizingMode, RiskProfileName(g_riskProfile), activePositions), g_panelX + 12, g_panelY + 185, clrSandyBrown, 8, "Consolas");
   CreatePanelLabel(CP_PREFIX + "METRICS", StringFormat("Trades %d | WR %.0f%% | PF %.2f | PnL %.2f", g_totalTrades, wr, pf, g_totalPnL), g_panelX + 12, g_panelY + 205, clrLightGray, 8, "Consolas");
   CreatePanelLabel(CP_PREFIX + "MARKET", StringFormat("Spread %.1f pts | DD %.2f%% | Shield %.1f%%", spreadPts, g_maxDD, g_state.effShieldPercent), g_panelX + 12, g_panelY + 225, clrLightSteelBlue, 8, "Consolas");

   ObjectSetString(0, BTN_PROFILE, OBJPROP_TEXT, "PROFILE " + RiskProfileName(g_riskProfile));
}

void DestroyControlPanel()
{
   ObjectDelete(0, CP_PREFIX + "BG");
   ObjectDelete(0, CP_PREFIX + "TITLE");
   ObjectDelete(0, CP_PREFIX + "SUB");
   ObjectDelete(0, CP_PREFIX + "STATE");
   ObjectDelete(0, CP_PREFIX + "RISK");
   ObjectDelete(0, CP_PREFIX + "METRICS");
   ObjectDelete(0, CP_PREFIX + "MARKET");
   ObjectDelete(0, BTN_AUTO);
   ObjectDelete(0, BTN_SMC);
   ObjectDelete(0, BTN_SHARK);
   ObjectDelete(0, BTN_VP);
   ObjectDelete(0, BTN_SR);
   ObjectDelete(0, BTN_BUY);
   ObjectDelete(0, BTN_SELL);
   ObjectDelete(0, BTN_CLOSE_ALL);
   ObjectDelete(0, BTN_RISK_UP);
   ObjectDelete(0, BTN_RISK_DOWN);
   ObjectDelete(0, BTN_PROFILE);
}

//+------------------------------------------------------------------+
//| RecordTrade — call after every closed position                    |
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
//| HandleButtonClick — process button events                         |
//+------------------------------------------------------------------+
bool HandleButtonClick(string objName)
{
   if(objName == BTN_AUTO) { g_panelAutoTrading = !g_panelAutoTrading; ClearPendingAction(); return true; }
   if(objName == BTN_SMC) { g_useSMC = !g_useSMC; return true; }
   if(objName == BTN_SHARK) { g_useShark = !g_useShark; return true; }
   if(objName == BTN_VP) { g_useVP = !g_useVP; return true; }
   if(objName == BTN_SR) { g_useSR = !g_useSR; return true; }

   if(objName == BTN_BUY) {
      if(!ArmOrConfirm("BUY")) return true;
      OpenManualPanelTrade(ORDER_TYPE_BUY);
      return true;
   }

   if(objName == BTN_SELL) {
      if(!ArmOrConfirm("SELL")) return true;
      OpenManualPanelTrade(ORDER_TYPE_SELL);
      return true;
   }

   if(objName == BTN_CLOSE_ALL) {
      if(!ArmOrConfirm("CLOSE_ALL")) return true;
      CloseAllPanelPositions();
      return true;
   }

   if(objName == BTN_RISK_UP) {
      g_riskPercent = MathMin(1.0, g_riskPercent + 0.05);
      SyncRuntimeRiskState();
      return true;
   }

   if(objName == BTN_RISK_DOWN) {
      g_riskPercent = MathMax(0.05, g_riskPercent - 0.05);
      SyncRuntimeRiskState();
      return true;
   }

   if(objName == BTN_PROFILE) {
      g_riskProfile = (g_riskProfile + 1) % 4;
      SyncRuntimeRiskState();
      return true;
   }

   return false;
}
