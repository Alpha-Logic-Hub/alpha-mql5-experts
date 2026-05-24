//+------------------------------------------------------------------+
//| HUD.mqh                                                          |
//| On-chart display — OBJ_LABEL for equity, risk, signals, shields  |
//+------------------------------------------------------------------+
#include "../Core/Definitions.mqh"

// --- Label prefix for HUD objects (used in OnDeinit cleanup) ---
#define HUD_PREFIX "MA_RSI_HUD_"

//+------------------------------------------------------------------+
//| InitHUD — create all OBJ_LABEL objects once                      |
//+------------------------------------------------------------------+
void InitHUD(string symbol, int magic, double riskPercent, double shieldPercent)
{
   int    xBase = 15;
   int    yPos  = 30;
   int    lineH = 14;
   color  c     = clrWhite;
   string font  = "Consolas";
   int    size  = 9;

   string pre = HUD_PREFIX;

   // --- Header ---
   ObjectCreate(0, pre + "header", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, pre + "header", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, pre + "header", OBJPROP_XDISTANCE, xBase);
   ObjectSetInteger(0, pre + "header", OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0,  pre + "header", OBJPROP_TEXT, "=== MA RSI Trend EA ===");
   ObjectSetInteger(0, pre + "header", OBJPROP_COLOR, clrGold);
   ObjectSetString(0,  pre + "header", OBJPROP_FONT, font);
   ObjectSetInteger(0, pre + "header", OBJPROP_FONTSIZE, size + 1);

   // --- Labels — create once, update on each tick ---
   string labels[12] = {
      "account", "pnl", "shield", "risk",
      "rsi", "maFast", "maSlow", "signal",
      "status", "spacer1", "spacer2", "config"
   };

   for(int i = 0; i < 12; i++) {
      ObjectCreate(0, pre + labels[i], OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, pre + labels[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, pre + labels[i], OBJPROP_XDISTANCE, xBase);
      ObjectSetInteger(0, pre + labels[i], OBJPROP_YDISTANCE, yPos + (i + 1) * lineH);
      ObjectSetInteger(0, pre + labels[i], OBJPROP_COLOR, c);
      ObjectSetString(0,  pre + labels[i], OBJPROP_FONT, font);
      ObjectSetInteger(0, pre + labels[i], OBJPROP_FONTSIZE, size);
   }
}

//+------------------------------------------------------------------+
//| DrawHUD — update label texts on each tick                        |
//+------------------------------------------------------------------+
void DrawHUD(RiskState         &s,
             double            rsi,
             double            maFast,
             double            maSlow,
             ENUM_SIGNAL_TYPE  lastSignal,
             bool              shieldBlocked)
{
   string pre = HUD_PREFIX;

   // --- Account ---
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   ObjectSetString(0, pre + "account", OBJPROP_TEXT,
      "Eq: $" + DoubleToString(equity, 2) +
      " | Bal: $" + DoubleToString(balance, 2));

   // --- Daily P&L ---
   string plSign = (s.dailyPL >= 0) ? "+" : "";
   double plPct  = MathAbs(s.dailyPL) * 100.0 / MathMax(s.startOfDayEquity, 0.01);
   color  plColor = (s.dailyPL >= 0) ? clrMediumSpringGreen : clrTomato;
   ObjectSetString(0, pre + "pnl", OBJPROP_TEXT,
      "P&L: " + plSign + "$" + DoubleToString(s.dailyPL, 2) +
      " (" + DoubleToString(plPct, 2) + "%)");
   ObjectSetInteger(0, pre + "pnl", OBJPROP_COLOR, plColor);

   // --- Shield status ---
   color shieldColor = shieldBlocked ? clrTomato : clrMediumSpringGreen;
   string shieldText  = shieldBlocked
      ? "SHIELD ACTIVE — No new trades"
      : "Shield: " + DoubleToString(s.effShieldPercent, 2) + "% (OK)";
   ObjectSetString(0, pre + "shield", OBJPROP_TEXT, shieldText);
   ObjectSetInteger(0, pre + "shield", OBJPROP_COLOR, shieldColor);

   // --- Risk profile ---
   string riskText = "Risk: " + DoubleToString(s.effRiskPercent, 3) + "%";
   ObjectSetString(0, pre + "risk", OBJPROP_TEXT, riskText);

   // --- RSI ---
   color rsiColor = clrWhite;
   if(rsi >= 70)      rsiColor = clrTomato;
   else if(rsi <= 30) rsiColor = clrMediumSpringGreen;
   ObjectSetString(0, pre + "rsi", OBJPROP_TEXT,
      "RSI(14): " + DoubleToString(rsi, 2));
   ObjectSetInteger(0, pre + "rsi", OBJPROP_COLOR, rsiColor);

   // --- MAs ---
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   ObjectSetString(0, pre + "maFast", OBJPROP_TEXT,
      "EMA(9): "  + DoubleToString(maFast, digits));
   ObjectSetString(0, pre + "maSlow", OBJPROP_TEXT,
      "SMA(21): " + DoubleToString(maSlow, digits));

   // --- Signal ---
   string sigText;
   color  sigColor;
   switch(lastSignal) {
      case SIGNAL_BUY:
         sigText = "Signal: BUY";
         sigColor = clrMediumSpringGreen;
         break;
      case SIGNAL_SELL:
         sigText = "Signal: SELL";
         sigColor = clrTomato;
         break;
      default:
         sigText  = "Signal: NONE";
         sigColor = clrDarkGray;
   }
   ObjectSetString(0, pre + "signal", OBJPROP_TEXT, sigText);
   ObjectSetInteger(0, pre + "signal", OBJPROP_COLOR, sigColor);

   // --- Status ---
   string openPos = IntegerToString(CountActivePositions(InpMagicNumber, _Symbol, g_pos));
   ObjectSetString(0, pre + "status", OBJPROP_TEXT,
      "Open: " + openPos + " | Spread: " +
      DoubleToString((SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                       SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point, 1) + " pts");
}

//+------------------------------------------------------------------+
//| ClearHUD — delete all HUD objects (call from OnDeinit)           |
//+------------------------------------------------------------------+
void ClearHUD()
{
   ObjectsDeleteAll(0, HUD_PREFIX);
}
