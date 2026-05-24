//+------------------------------------------------------------------+
//| HTF Filter — higher timeframe trend validation (M15)             |
//+------------------------------------------------------------------+

int      h_htf_ema = INVALID_HANDLE;
bool     htf_bull = true;
bool     htf_initialized = false;

//+------------------------------------------------------------------+
//| Inicializar handles del HTF                                      |
//+------------------------------------------------------------------+
void HTF_Init()
{
   int tf = PERIOD_M15;
   if(_Period == PERIOD_M15) tf = PERIOD_H1;

   h_htf_ema = iMA(_Symbol, tf, dynTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(h_htf_ema == INVALID_HANDLE) {
      Print("HTF Filter: No se pudo crear handle EMA en ", EnumToString((ENUM_TIMEFRAMES)tf));
      htf_initialized = false;
      return;
   }
   htf_initialized = true;
}

//+------------------------------------------------------------------+
//| Liberar handles                                                  |
//+------------------------------------------------------------------+
void HTF_Deinit()
{
   if(h_htf_ema != INVALID_HANDLE) {
      IndicatorRelease(h_htf_ema);
      h_htf_ema = INVALID_HANDLE;
   }
   htf_initialized = false;
}

//+------------------------------------------------------------------+
//| Evaluar tendencia del HTF — actualiza htf_bull                    |
//+------------------------------------------------------------------+
void HTF_Evaluate()
{
   if(!htf_initialized) return;

   int tf = PERIOD_M15;
   if(_Period == PERIOD_M15) tf = PERIOD_H1;

   double emaBuf[];
   ArraySetAsSeries(emaBuf, true);
   if(CopyBuffer(h_htf_ema, 0, 0, InpMathPeriod, emaBuf) < InpMathPeriod) {
      htf_bull = true;
      return;
   }

   double slope = 0, r2 = 0;
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   int n = InpMathPeriod;

   for(int i = 0; i < n; i++) {
      double x = n - i;
      double y = emaBuf[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
   }

   double numSlope = (n * sumXY) - (sumX * sumY);
   double denSlope = (n * sumX2) - (sumX * sumX);
   if(denSlope != 0) slope = numSlope / denSlope;

   double atrBuf[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atrBuf) <= 0) { htf_bull = true; return; }
   double angle = CalculateSlopeAngle(slope, atrBuf[0]);

   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentEMA = emaBuf[0];

   if(angle >= InpMinAngleDeg && currentPrice > currentEMA) {
      htf_bull = true;
   } else if(MathAbs(angle) >= InpMinAngleDeg && currentPrice < currentEMA) {
      htf_bull = false;
   }
}

//+------------------------------------------------------------------+
//| Verificar si la dirección es válida según HTF                     |
//+------------------------------------------------------------------+
bool HTF_IsDirectionValid(ENUM_ORDER_TYPE type)
{
   if(!htf_initialized) return true;
   return (type == ORDER_TYPE_BUY && htf_bull) ||
          (type == ORDER_TYPE_SELL && !htf_bull);
}
