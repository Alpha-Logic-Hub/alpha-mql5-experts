//+------------------------------------------------------------------+
//| Exit Management — partial close, break-even, trailing stop        |
//+------------------------------------------------------------------+

void ManagePositionExits()
{
   if(!InpUsePartialClose && !InpUseBreakEven) return;
   CPositionInfo posExit;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(posExit.SelectByIndex(i) && posExit.Magic() == InpMagicNumber && posExit.Symbol() == _Symbol)
      {
         double entryPrice = posExit.PriceOpen();
         double currentPrice = posExit.PriceCurrent();
         double sl = posExit.StopLoss();
         double tp = posExit.TakeProfit();
         double volume = posExit.Volume();
         ulong ticket = posExit.Ticket();
         if(sl == 0) continue;
         double riskDist = MathAbs(entryPrice - sl);
         if(riskDist == 0) continue;
         double currentProfitDist = (posExit.PositionType() == POSITION_TYPE_BUY) ? currentPrice - entryPrice : entryPrice - currentPrice;
         double currentRR = currentProfitDist / riskDist;
         if(currentRR >= InpPartialTriggerRR)
         {
            bool alreadyProtected = (posExit.PositionType() == POSITION_TYPE_BUY) ? (sl >= entryPrice - (2 * _Point)) : (sl <= entryPrice + (2 * _Point));
            if(!alreadyProtected)
            {
               if(InpUsePartialClose)
               {
                  double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
                  double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                  double closeVol = MathMax(MathRound((volume * InpPartialRatio) / step) * step, minLot);
                  if(closeVol < volume) g_g_trade.PositionClosePartial(ticket, closeVol, 10);
               }
               if(InpUseBreakEven)
               {
                  double offset = InpBeOffsetPoints * _Point;
                  double newSL = (posExit.PositionType() == POSITION_TYPE_BUY) ? entryPrice + offset : entryPrice - offset;
                  g_g_trade.PositionModify(ticket, newSL, tp);
               }
            }
         }
      }
   }
}

void UpdateTrailingStop()
{
   if(!InpUseTrailingStop) return;

   double atrBuf[1];
   double atrPoints = 0;
   if(CopyBuffer(h_atr, 0, 0, 1, atrBuf) > 0 && atrBuf[0] > 0)
   {
      atrPoints = (atrBuf[0] * InpTrailATRMult) / _Point;
   }

   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = (double)stopLevel + 10.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      CPositionInfo p;
      if(!p.SelectByIndex(i) || p.Magic()!=InpMagicNumber || p.Symbol()!=_Symbol) continue;

      double curPrice = (p.PositionType()==POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sl = p.StopLoss();
      double tp = p.TakeProfit();
      double profitUSD = p.Profit();

      double profitRatio = profitUSD / MathMax(InpTrailingTriggerUSD, 0.01);
      double trailMult = InpTrailATRMult;
      if(profitRatio >= 8.0) trailMult = InpTrailATRMult * 0.3;
      else if(profitRatio >= 4.0) trailMult = InpTrailATRMult * 0.5;
      else if(profitRatio >= 2.0) trailMult = InpTrailATRMult * 0.7;

      double dynAtrPts = (atrBuf[0] * trailMult) / _Point;
      double finalTrailPoints = MathMax(dynAtrPts, MathMax(trailingDistPoints, minDistance));
      double trail = finalTrailPoints * _Point;

      bool canTrail = (profitUSD >= InpTrailingTriggerUSD);

      if(p.PositionType()==POSITION_TYPE_BUY)
      {
         if(canTrail)
         {
            double newSL = NormalizeDouble(curPrice - trail, _Digits);
            double minStep = 3.0 * _Point;
            if(sl == 0 || (newSL > sl && (newSL - sl >= minStep)))
            {
               g_trade.PositionModify(p.Ticket(), newSL, tp);
            }
         }
      }
      else
      {
         if(canTrail)
         {
            double newSL = NormalizeDouble(curPrice + trail, _Digits);
            double minStep = 3.0 * _Point;
            if(sl == 0 || (newSL < sl && (sl - newSL >= minStep)))
            {
               g_trade.PositionModify(p.Ticket(), newSL, tp);
            }
         }
      }
   }
}
