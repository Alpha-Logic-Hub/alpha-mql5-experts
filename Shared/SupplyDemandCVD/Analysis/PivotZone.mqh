//+------------------------------------------------------------------+
//| Pivot & Zone Detection — SMC structure + zone lifecycle           |
//+------------------------------------------------------------------+

bool IsHistoricalZoneMitigated(double top, double bottom, bool isDemand, int startShift)
{
   for(int j = startShift - 1; j >= 0; j--) {
      double l_j = iLow(_Symbol, _Period, j);
      double h_j = iHigh(_Symbol, _Period, j);
      if(isDemand && l_j < bottom) return true;
      if(!isDemand && h_j > top) return true;
   }
   return false;
}

bool IsPivotHigh(int bar, int length)
{
   if(bar < length || bar + length >= iBars(_Symbol, _Period)) return false;
   double h = iHigh(_Symbol, _Period, bar);
   for(int i = 1; i <= length; i++) {
      if(iHigh(_Symbol, _Period, bar + i) > h) return false;
      if(iHigh(_Symbol, _Period, bar - i) >= h) return false;
   }
   return true;
}

bool IsPivotLow(int bar, int length)
{
   if(bar < length || bar + length >= iBars(_Symbol, _Period)) return false;
   double l = iLow(_Symbol, _Period, bar);
   for(int i = 1; i <= length; i++) {
      if(iLow(_Symbol, _Period, bar + i) < l) return false;
      if(iLow(_Symbol, _Period, bar - i) <= l) return false;
   }
   return true;
}

void AddZoneHistorical(double top, double bottom, bool isDemand, int shift)
{
   Zone newZone;
   newZone.top = top;
   newZone.bottom = bottom;
   newZone.startTime = iTime(_Symbol, _Period, shift);
   newZone.active = true;
   newZone.traded = true;
   newZone.objName = "SND_" + (isDemand ? "Dem_" : "Sup_") + IntegerToString((int)newZone.startTime);

   if(isDemand) {
      ArrayResize(demandZones, ArraySize(demandZones)+1);
      demandZones[ArraySize(demandZones)-1] = newZone;
      DrawBox(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, InpDemandColor, "Demand");
      DrawFibLevels(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, true);
   } else {
      ArrayResize(supplyZones, ArraySize(supplyZones)+1);
      supplyZones[ArraySize(supplyZones)-1] = newZone;
      DrawBox(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, InpSupplyColor, "Supply");
      DrawFibLevels(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, false);
   }
}

void ScanHistory(int count)
{
   Print("Escaneando historia para detectar zonas estructurales...");
   int totalBars = iBars(_Symbol, _Period);
   if(totalBars <= InpPivotLength + 5) return;
   int limit = MathMin(count, totalBars - InpPivotLength - 5);

   lastPivotHigh = 0;
   lastPivotLow = 0;

   for(int i = limit; i >= 1 + InpPivotLength; i--) {
      if(IsPivotHigh(i, InpPivotLength)) {
         lastPivotHigh = iHigh(_Symbol, _Period, i);
      }
      if(IsPivotLow(i, InpPivotLength)) {
         lastPivotLow = iLow(_Symbol, _Period, i);
      }

      if(lastPivotHigh == 0 || lastPivotLow == 0) continue;

      double closeI = iClose(_Symbol, _Period, i - InpPivotLength);
      double closePrev = iClose(_Symbol, _Period, i - InpPivotLength + 1);

      if(closePrev <= lastPivotHigh && closeI > lastPivotHigh) {
         int lowestBar = i - InpPivotLength;
         double lowestLow = iLow(_Symbol, _Period, lowestBar);
         for(int j = i - InpPivotLength; j <= i; j++) {
            double l = iLow(_Symbol, _Period, j);
            if(l < lowestLow) {
               lowestLow = l;
               lowestBar = j;
            }
         }
         double obTop = iHigh(_Symbol, _Period, lowestBar);
         double obBottom = iLow(_Symbol, _Period, lowestBar);

         if(!IsZoneOverlapping(obBottom, obTop, true)) {
            if(!IsHistoricalZoneMitigated(obTop, obBottom, true, i - InpPivotLength)) {
               AddZoneHistorical(obTop, obBottom, true, lowestBar);
            }
         }
      }

      if(closePrev >= lastPivotLow && closeI < lastPivotLow) {
         int highestBar = i - InpPivotLength;
         double highestHigh = iHigh(_Symbol, _Period, highestBar);
         for(int j = i - InpPivotLength; j <= i; j++) {
            double h = iHigh(_Symbol, _Period, j);
            if(h > highestHigh) {
               highestHigh = h;
               highestBar = j;
            }
         }
         double obTop = iHigh(_Symbol, _Period, highestBar);
         double obBottom = iLow(_Symbol, _Period, highestBar);

         if(!IsZoneOverlapping(obBottom, obTop, false)) {
            if(!IsHistoricalZoneMitigated(obTop, obBottom, false, i - InpPivotLength)) {
               AddZoneHistorical(obTop, obBottom, false, highestBar);
            }
         }
      }
   }
}

void AddZone(double top, double bottom, bool isDemand, datetime zoneTime)
{
   Zone newZone;
   newZone.top = top;
   newZone.bottom = bottom;
   newZone.startTime = zoneTime;
   newZone.active = true;
   newZone.traded = false;
   newZone.objName = "SND_" + (isDemand ? "Dem_" : "Sup_") + IntegerToString((int)newZone.startTime);

   if(isDemand) {
      ArrayResize(demandZones, ArraySize(demandZones)+1);
      demandZones[ArraySize(demandZones)-1] = newZone;
      DrawBox(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, InpDemandColor, "Demand");
      DrawFibLevels(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, true);
      DrawSignal(iLow(_Symbol, _Period, 1), "△", InpDemandColor);
   } else {
      ArrayResize(supplyZones, ArraySize(supplyZones)+1);
      supplyZones[ArraySize(supplyZones)-1] = newZone;
      DrawBox(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, InpSupplyColor, "Supply");
      DrawFibLevels(newZone.objName, newZone.startTime, newZone.top, newZone.bottom, false);
      DrawSignal(iHigh(_Symbol, _Period, 1), "▽", InpSupplyColor);
   }
}

bool IsZoneOverlapping(double low, double high, bool isDemand)
{
   double margin = (high - low) * 0.1;
   if(isDemand) {
      for(int i=0; i<ArraySize(demandZones); i++)
         if(demandZones[i].active && (low - margin) <= demandZones[i].top && (high + margin) >= demandZones[i].bottom) return true;
   } else {
      for(int i=0; i<ArraySize(supplyZones); i++)
         if(supplyZones[i].active && (low - margin) <= supplyZones[i].top && (high + margin) >= supplyZones[i].bottom) return true;
   }
   return false;
}

void CompactZones()
{
   Zone tempD[];
   for(int i=0; i<ArraySize(demandZones); i++) {
      if(demandZones[i].active) {
         ArrayResize(tempD, ArraySize(tempD)+1);
         tempD[ArraySize(tempD)-1] = demandZones[i];
      }
   }
   while(ArraySize(tempD) > InpMaxActiveZones) {
      ObjectDelete(0, tempD[0].objName);
      ObjectDelete(0, tempD[0].objName + "_LBL");
      ObjectDelete(0, tempD[0].objName + "_F30");
      ObjectDelete(0, tempD[0].objName + "_F50");
      ObjectDelete(0, tempD[0].objName + "_F70");
      for(int i=0; i<ArraySize(tempD)-1; i++) tempD[i] = tempD[i+1];
      ArrayResize(tempD, ArraySize(tempD)-1);
   }
   ArraySwap(demandZones, tempD);

   Zone tempS[];
   for(int i=0; i<ArraySize(supplyZones); i++) {
      if(supplyZones[i].active) {
         ArrayResize(tempS, ArraySize(tempS)+1);
         tempS[ArraySize(tempS)-1] = supplyZones[i];
      }
   }
   while(ArraySize(tempS) > InpMaxActiveZones) {
      ObjectDelete(0, tempS[0].objName);
      ObjectDelete(0, tempS[0].objName + "_LBL");
      ObjectDelete(0, tempS[0].objName + "_F30");
      ObjectDelete(0, tempS[0].objName + "_F50");
      ObjectDelete(0, tempS[0].objName + "_F70");
      for(int i=0; i<ArraySize(tempS)-1; i++) tempS[i] = tempS[i+1];
      ArrayResize(tempS, ArraySize(tempS)-1);
   }
   ArraySwap(supplyZones, tempS);
}

void CheckMitigation()
{
   double close = iClose(_Symbol, _Period, 0);
   datetime now = TimeCurrent();

   for(int i=0; i<ArraySize(demandZones); i++) {
      if(!demandZones[i].active) continue;

      ObjectSetInteger(0, demandZones[i].objName, OBJPROP_TIME, 1, now);

      if(InpShowFibLines) {
         ObjectSetInteger(0, demandZones[i].objName + "_F30", OBJPROP_TIME, 1, now);
         ObjectSetInteger(0, demandZones[i].objName + "_F50", OBJPROP_TIME, 1, now);
         ObjectSetInteger(0, demandZones[i].objName + "_F70", OBJPROP_TIME, 1, now);
      }

      int bars = iBarShift(_Symbol, _Period, demandZones[i].startTime);
      double currentCVD = CalculateCVD(bars + 1);
      string labelName = demandZones[i].objName + "_LBL";
      ObjectSetString(0, labelName, OBJPROP_TEXT, StringFormat(" Demand | CVD: %.0f  ", currentCVD));
      ObjectSetInteger(0, labelName, OBJPROP_TIME, now);

      if(close < demandZones[i].bottom) {
         demandZones[i].active = false;
         ObjectDelete(0, demandZones[i].objName);
         ObjectDelete(0, labelName);
         ObjectDelete(0, demandZones[i].objName + "_F30");
         ObjectDelete(0, demandZones[i].objName + "_F50");
         ObjectDelete(0, demandZones[i].objName + "_F70");
      }
   }

   for(int i=0; i<ArraySize(supplyZones); i++) {
      if(!supplyZones[i].active) continue;

      ObjectSetInteger(0, supplyZones[i].objName, OBJPROP_TIME, 1, now);

      if(InpShowFibLines) {
         ObjectSetInteger(0, supplyZones[i].objName + "_F30", OBJPROP_TIME, 1, now);
         ObjectSetInteger(0, supplyZones[i].objName + "_F50", OBJPROP_TIME, 1, now);
         ObjectSetInteger(0, supplyZones[i].objName + "_F70", OBJPROP_TIME, 1, now);
      }

      int bars = iBarShift(_Symbol, _Period, supplyZones[i].startTime);
      double currentCVD = CalculateCVD(bars + 1);
      string labelName = supplyZones[i].objName + "_LBL";
      ObjectSetString(0, labelName, OBJPROP_TEXT, StringFormat(" Supply | CVD: %.0f  ", currentCVD));
      ObjectSetInteger(0, labelName, OBJPROP_TIME, now);

      if(close > supplyZones[i].top) {
         supplyZones[i].active = false;
         ObjectDelete(0, supplyZones[i].objName);
         ObjectDelete(0, labelName);
         ObjectDelete(0, supplyZones[i].objName + "_F30");
         ObjectDelete(0, supplyZones[i].objName + "_F50");
         ObjectDelete(0, supplyZones[i].objName + "_F70");
      }
   }

   CompactZones();
}

void DetectZones()
{
   int shift = InpPivotLength;
   if(IsPivotHigh(shift, InpPivotLength)) {
      lastPivotHigh = iHigh(_Symbol, _Period, shift);
   }
   if(IsPivotLow(shift, InpPivotLength)) {
      lastPivotLow = iLow(_Symbol, _Period, shift);
   }

   if(lastPivotHigh == 0 || lastPivotLow == 0) return;

   double pastHigh = iHigh(_Symbol, _Period, iHighest(_Symbol, _Period, MODE_HIGH, InpConsLength, 1));
   double pastLow = iLow(_Symbol, _Period, iLowest(_Symbol, _Period, MODE_LOW, InpConsLength, 1));
   double zoneRange = pastHigh - pastLow;

   double atrBuf[1];
   if(CopyBuffer(h_atr, 0, 1, 1, atrBuf) < 1) return;

   bool isConsolidating = !InpUseConsolidation || (zoneRange <= (atrBuf[0] * InpAtrMult));

   int cooldownBarsLeft = 9999;
   if(lastTradeTime > 0) {
      cooldownBarsLeft = iBarShift(_Symbol, _Period, lastTradeTime);
   }
   bool canEnter = !InpUseCooldown || (lastTradeTime == 0) || (cooldownBarsLeft >= InpCooldownBars);

   double close0 = iClose(_Symbol, _Period, 1);
   double close1 = iClose(_Symbol, _Period, 2);

   if(close1 <= lastPivotHigh && close0 > lastPivotHigh && isConsolidating && canEnter)
   {
      bool mathValid = true;
      if(InpUseMathTrend || InpUseMathAngle) {
         double slope = 0;
         double r2 = 0;
         CalculateLinearRegressionCustom(5, 1, slope, r2);
         double angle = CalculateSlopeAngle(slope, atrBuf[0]);

         if(InpUseMathTrend && r2 < 0.35) mathValid = false;
         if(slope <= 0) mathValid = false;
         if(InpUseMathAngle && angle < InpMinAngleDeg) mathValid = false;
      }

      if(mathValid)
      {
         int searchStart = 1;
         int searchEnd = iBarShift(_Symbol, _Period, iTime(_Symbol, _Period, shift));
         if(searchEnd < searchStart) searchEnd = searchStart + 5;

         int lowestBar = searchStart;
         double lowestLow = iLow(_Symbol, _Period, searchStart);
         for(int i = searchStart; i <= searchEnd; i++) {
            double l = iLow(_Symbol, _Period, i);
            if(l < lowestLow) {
               lowestLow = l;
               lowestBar = i;
            }
         }

         double obTop = iHigh(_Symbol, _Period, lowestBar);
         double obBottom = iLow(_Symbol, _Period, lowestBar);

         if(!IsZoneOverlapping(obBottom, obTop, true)) {
            AddZone(obTop, obBottom, true, iTime(_Symbol, _Period, lowestBar));
            lastPivotHigh = 0;
         }
      }
   }

   if(close1 >= lastPivotLow && close0 < lastPivotLow && isConsolidating && canEnter)
   {
      bool mathValid = true;
      if(InpUseMathTrend || InpUseMathAngle) {
         double slope = 0;
         double r2 = 0;
         CalculateLinearRegressionCustom(5, 1, slope, r2);
         double angle = CalculateSlopeAngle(slope, atrBuf[0]);

         if(InpUseMathTrend && r2 < 0.35) mathValid = false;
         if(slope >= 0) mathValid = false;
         if(InpUseMathAngle && MathAbs(angle) < InpMinAngleDeg) mathValid = false;
      }

      if(mathValid)
      {
         int searchStart = 1;
         int searchEnd = iBarShift(_Symbol, _Period, iTime(_Symbol, _Period, shift));
         if(searchEnd < searchStart) searchEnd = searchStart + 5;

         int highestBar = searchStart;
         double highestHigh = iHigh(_Symbol, _Period, searchStart);
         for(int i = searchStart; i <= searchEnd; i++) {
            double h = iHigh(_Symbol, _Period, i);
            if(h > highestHigh) {
               highestHigh = h;
               highestBar = i;
            }
         }

         double obTop = iHigh(_Symbol, _Period, highestBar);
         double obBottom = iLow(_Symbol, _Period, highestBar);

         if(!IsZoneOverlapping(obBottom, obTop, false)) {
            AddZone(obTop, obBottom, false, iTime(_Symbol, _Period, highestBar));
            lastPivotLow = 0;
         }
      }
   }
}
