//+------------------------------------------------------------------+
//| GlobalRiskManager.mqh                                            |
//| Alpha Logic Hub — Circuit Breaker Perimetral                     |
//| Monitorea equity de cuenta a nivel global (todos los EAs)        |
//+------------------------------------------------------------------+

// --- Estado del Circuit Breaker ---
bool   g_globalHalt = false;
double g_globalDailyStartEquity = 0;

//+------------------------------------------------------------------+
//| InitGlobalRisk — registrar equity inicial del día                |
//+------------------------------------------------------------------+
void InitGlobalRisk()
{
   g_globalDailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_globalHalt = false;
   Print("[GlobalRisk] Circuit Breaker initialized — StartEquity=", g_globalDailyStartEquity);
}

//+------------------------------------------------------------------+
//| UpdateGlobalRisk — verificar DD global en cada tick              |
//+------------------------------------------------------------------+
void UpdateGlobalRisk(double maxGlobalDDPercent = 5.0)
{
   if(g_globalHalt) return;

   // Auto-reset al inicio de un nuevo día de trading
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour == 0 && dt.min == 0 && dt.sec < 5) {
      InitGlobalRisk();
   }

   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double maxLossAllowed = g_globalDailyStartEquity * (maxGlobalDDPercent / 100.0);
   double currentDrawdown = g_globalDailyStartEquity - currentEquity;

   // Verificar violación de la regla de oro de riesgo global
   if(currentDrawdown >= maxLossAllowed) {
      g_globalHalt = true;
      Alert("[GLOBAL RISK] CIRCUIT BREAKER TRIGGERED! Max daily drawdown reached. Halting all operations.");
      Print("[GlobalRisk] CRITICAL: StartEquity=", g_globalDailyStartEquity,
            " | CurrentEquity=", currentEquity,
            " | DD=", currentDrawdown);

      // Llamar a función de pánico: Cierre masivo de posiciones de la cuenta entera
      CloseAllPositionsSystemWide();
   }
}

//+------------------------------------------------------------------+
//| CloseAllPositionsSystemWide — Cierre masivo de emergencia        |
//+------------------------------------------------------------------+
void CloseAllPositionsSystemWide()
{
   #include <Trade\Trade.mqh>
   CTrade emergencyTrade;

   Print("[GlobalRisk] Initiating Emergency System-Wide Position Liquidations...");

   // Recorrer todas las posiciones abiertas en la cuenta, sin importar el MagicNumber
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0) {
         if(emergencyTrade.PositionClose(ticket)) {
            Print("[GlobalRisk] Emergency Close SUCCESS — Ticket: ", ticket);
         } else {
            Print("[GlobalRisk] Emergency Close FAILED — Ticket: ", ticket,
                  " | Error: ", GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| IsGlobalHalted — consultar estado del breaker                   |
//+------------------------------------------------------------------+
bool IsGlobalHalted()
{
   return g_globalHalt;
}

//+------------------------------------------------------------------+
//| ResetGlobalRisk — forzar reset manual (post-session o recovery)  |
//+------------------------------------------------------------------+
void ResetGlobalRisk()
{
   g_globalHalt = false;
   g_globalDailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   Print("[GlobalRisk] Circuit Breaker RESET — New StartEquity=", g_globalDailyStartEquity);
}
