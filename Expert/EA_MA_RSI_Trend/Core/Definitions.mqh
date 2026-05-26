//+------------------------------------------------------------------+
//| Definitions.mqh — EA_MA_RSI_Trend                                |
//| Includes shared types + EA-specific helpers                      |
//+------------------------------------------------------------------+
#include "..\..\..\Shared\Core\Definitions.mqh"

//+------------------------------------------------------------------+
//| IsNewBar — returns true only on the first tick of a new bar      |
//| Prevents signal flickering on bar[0] during "every tick" mode    |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, _Period, 0);

   if(currentBarTime != lastBarTime) {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}
