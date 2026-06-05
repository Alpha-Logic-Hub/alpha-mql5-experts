//+------------------------------------------------------------------+
//|                                Signals/SessionFilter.mqh           |
//|             RangeScalper — Trading Session Filter                  |
//+------------------------------------------------------------------+
#ifndef _SESSION_FILTER_
#define _SESSION_FILTER_

bool IsTradingSession()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   // Active window: 7-22h server time (covers London+NY for crypto)
   return (dt.hour >= 7 && dt.hour < 22);
}

#endif
