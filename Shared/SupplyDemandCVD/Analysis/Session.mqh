//+------------------------------------------------------------------+
//| Session.mqh                                                      |
//| Market session detection (Asia/London/NY)                        |
//+------------------------------------------------------------------+

enum ENUM_MARKET_SESSION {
   SESSION_OFF,
   SESSION_ASIA,
   SESSION_LONDON,
   SESSION_NY
};

ENUM_MARKET_SESSION GetMarketSession()
{
   MqlDateTime dt;
   TimeGMT(dt);
   int hour = dt.hour;
   if(hour >= 13 && hour < 22) return SESSION_NY;
   if(hour >= 7 && hour < 14)  return SESSION_LONDON;
   if(hour >= 0 && hour < 8)   return SESSION_ASIA;
   return SESSION_OFF;
}
//+------------------------------------------------------------------+
