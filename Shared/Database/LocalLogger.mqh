//+------------------------------------------------------------------+
//| LocalLogger.mqh                                                   |
//| Alpha Logic Hub — Trader Memory Core (Logs YAML)                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| LogSessionStart — registrar inicio de sesión                     |
//+------------------------------------------------------------------+
void LogSessionStart(string eaName, int magicNumber, double startEquity, double riskPercent)
{
   Print("[LocalLogger] ========================================");
   Print("[LocalLogger] SESSION START — ", eaName);
   Print("[LocalLogger] Magic=", magicNumber,
         " | Equity=", startEquity,
         " | Risk=", riskPercent, "%");
   Print("[LocalLogger] Timestamp=", TimeToString(TimeCurrent()));
   Print("[LocalLogger] ========================================");
}

//+------------------------------------------------------------------+
//| LogTrade — registrar cada operación                              |
//+------------------------------------------------------------------+
void LogTrade(ulong ticket, string direction, double entry, double sl, double tp,
              double lot, double pnl, string result)
{
   Print("[LocalLogger] TRADE | Ticket=", ticket,
         " | ", direction,
         " | Entry=", entry,
         " | SL=", sl,
         " | TP=", tp,
         " | Lot=", lot,
         " | PnL=", pnl,
         " | ", result);
}

//+------------------------------------------------------------------+
//| LogSessionEnd — registrar cierre de sesión                       |
//+------------------------------------------------------------------+
void LogSessionEnd(string eaName, int totalTrades, int wins, int losses,
                   double totalPnL, bool shieldTriggered, double maxDD)
{
   double winRate = (totalTrades > 0) ? (double)wins / totalTrades * 100.0 : 0;

   Print("[LocalLogger] ========================================");
   Print("[LocalLogger] SESSION END — ", eaName);
   Print("[LocalLogger] Trades=", totalTrades,
         " | Wins=", wins,
         " | Losses=", losses,
         " | WinRate=", winRate, "%");
   Print("[LocalLogger] Total PnL=", totalPnL,
         " | Shield Triggered=", shieldTriggered,
         " | Max DD=", maxDD, "%");
   Print("[LocalLogger] Timestamp=", TimeToString(TimeCurrent()));
   Print("[LocalLogger] ========================================");
}
