//+------------------------------------------------------------------+
//| HUD — on-chart diagnostic panel                                   |
//+------------------------------------------------------------------+

void DrawHUD()
{
   if(!InpShowHUD) return;

   string bgName = "SND_HUD_BG";
   string lblTitle = "SND_HUD_Title";
   string lblTime  = "SND_HUD_Time";
   string lblDist  = "SND_HUD_Dist";

   string tfStr = "";
   switch((ENUM_TIMEFRAMES)_Period) {
      case PERIOD_M1:  tfStr = "M1"; break;
      case PERIOD_M2:  tfStr = "M2"; break;
      case PERIOD_M3:  tfStr = "M3"; break;
      case PERIOD_M4:  tfStr = "M4"; break;
      case PERIOD_M5:  tfStr = "M5"; break;
      case PERIOD_M6:  tfStr = "M6"; break;
      case PERIOD_M10: tfStr = "M10"; break;
      case PERIOD_M12: tfStr = "M12"; break;
      case PERIOD_M15: tfStr = "M15"; break;
      case PERIOD_M20: tfStr = "M20"; break;
      case PERIOD_M30: tfStr = "M30"; break;
      case PERIOD_H1:  tfStr = "H1"; break;
      case PERIOD_H2:  tfStr = "H2"; break;
      case PERIOD_H3:  tfStr = "H3"; break;
      case PERIOD_H4:  tfStr = "H4"; break;
      case PERIOD_H6:  tfStr = "H6"; break;
      case PERIOD_H8:  tfStr = "H8"; break;
      case PERIOD_H12: tfStr = "H12"; break;
      case PERIOD_D1:  tfStr = "D1"; break;
      case PERIOD_W1:  tfStr = "W1"; break;
      case PERIOD_MN1: tfStr = "MN1"; break;
      default:         tfStr = "Custom"; break;
   }

   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   datetime nextBarTime = currentBarTime + PeriodSeconds(_Period);
   datetime timeCurrent = TimeCurrent();
   int secondsLeft = (int)(nextBarTime - timeCurrent);
   if(secondsLeft < 0) secondsLeft = 0;
   int minLeft = secondsLeft / 60;
   int secLeft = secondsLeft % 60;
   string timeStr = StringFormat("Tiempo Vela: %02d:%02d [TF: %s]", minLeft, secLeft, tfStr);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double closestDist = 9999999.0;
   string closestType = "Ninguna";
   double targetOTE = 0;

   for(int i=0; i<ArraySize(demandZones); i++) {
      if(demandZones[i].active && !demandZones[i].traded) {
         double zoneRange = demandZones[i].top - demandZones[i].bottom;
         double oteVal = demandZones[i].bottom + zoneRange * InpFib50;
         double dist = MathAbs(ask - oteVal);
         if(dist < closestDist) {
            closestDist = dist;
            closestType = "Demanda (Compra)";
            targetOTE = oteVal;
         }
      }
   }
   for(int i=0; i<ArraySize(supplyZones); i++) {
      if(supplyZones[i].active && !supplyZones[i].traded) {
         double zoneRange = supplyZones[i].top - supplyZones[i].bottom;
         double oteVal = supplyZones[i].top - zoneRange * InpFib50;
         double dist = MathAbs(bid - oteVal);
         if(dist < closestDist) {
            closestDist = dist;
            closestType = "Oferta (Venta)";
            targetOTE = oteVal;
         }
      }
   }

   string distStr = "Proximo OTE: N/A";
   double pipsDist = 0;
   if(closestDist < 999999.0) {
      pipsDist = closestDist / _Point;
      if(_Digits == 3 || _Digits == 5) pipsDist /= 10.0;
      distStr = StringFormat("Dist. OTE: %.1f Pips (%s)", pipsDist, closestType);
   }

   string estTimeStr = "Est. Entrada: N/A (Esperando Zona)";
   if(closestDist < 999999.0) {
      double atrBuf[1];
      if(CopyBuffer(h_atr, 0, 0, 1, atrBuf) > 0 && atrBuf[0] > 0) {
         double barsToTarget = closestDist / atrBuf[0];
         double secondsToTarget = barsToTarget * PeriodSeconds(_Period);
         int totalMinutes = (int)(secondsToTarget / 60.0);

         if(totalMinutes < 1) {
            estTimeStr = "Est. Entrada: < 1 min (Inminente!)";
         } else if(totalMinutes < 60) {
            estTimeStr = StringFormat("Est. Entrada: ~ %d mins", totalMinutes);
         } else {
            double hours = totalMinutes / 60.0;
            estTimeStr = StringFormat("Est. Entrada: ~ %.1f horas", hours);
         }
      }
   }

   double ema[1];
   bool trendBull = true;
   bool hasEma = (CopyBuffer(h_ema, 0, 1, 1, ema) > 0);
   if(hasEma) {
      trendBull = (ask > ema[0]);
   }

   double cvd = CalculateCVD(50);
   string cvdStr = StringFormat("Flujo CVD: %s (%c: %.0f)", (cvd >= 0 ? "COMPRADOR [OK]" : "BAJISTA [FILTRADO]"), (cvd >= 0 ? '+' : '-'), cvd);

   int score = 0;
   if(closestDist < 999999.0) {
      if(pipsDist <= 0.5) score = 100;
      else if(pipsDist <= 2.0) score = 95;
      else if(pipsDist <= 5.0) score = 90;
      else if(pipsDist <= 10.0) score = 75;
      else if(pipsDist <= 20.0) score = 55;
      else if(pipsDist <= 35.0) score = 35;
      else if(pipsDist <= 50.0) score = 15;
      else score = 5;
   }
   string probStr = StringFormat("Preparacion: %d%% %s", score, (score >= 90 ? "[DISPARO INMINENTE]" : score >= 70 ? "[APROXIMACION]" : "[ESPERANDO ZONA]"));

   double slope = 0;
   double r2 = 0;
   CalculateLinearRegression(InpMathPeriod, slope, r2);
   double atrVal[1];
   CopyBuffer(h_atr, 0, 0, 1, atrVal);
   double angle = CalculateSlopeAngle(slope, atrVal[0]);

   string mathTrendStr = StringFormat("Fuerza R (Lineal): %.3f %s", r2, (r2 >= InpMathMinR2 ? "[ESTABLE]" : "[RUIDO]"));
   string mathAngleStr = StringFormat("Angulo Vector: %.1f (m: %.5f)", angle, slope);

   string lblMathTrend = "SND_HUD_MathTrend";
   string lblMathAngle = "SND_HUD_MathAngle";

   color hudBgColor = C'30,50,50';

   if(ObjectFind(0, bgName) < 0) {
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 300);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 310);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrDarkSlateGray);
   }
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, hudBgColor);

   if(ObjectFind(0, lblTitle) < 0) {
      ObjectCreate(0, lblTitle, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblTitle, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblTitle, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblTitle, OBJPROP_YDISTANCE, 18);
      ObjectSetInteger(0, lblTitle, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, lblTitle, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, lblTitle, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblTitle, OBJPROP_TEXT, "FLUJO CVD ELITE - DIAGNOSTICO");

   string lblSec1 = "SND_HUD_Sec1";
   if(ObjectFind(0, lblSec1) < 0) {
      ObjectCreate(0, lblSec1, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblSec1, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblSec1, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblSec1, OBJPROP_YDISTANCE, 40);
      ObjectSetInteger(0, lblSec1, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, lblSec1, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblSec1, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblSec1, OBJPROP_TEXT, "=== DATOS CUANTICOS ===");

   if(ObjectFind(0, lblTime) < 0) {
      ObjectCreate(0, lblTime, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblTime, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblTime, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblTime, OBJPROP_YDISTANCE, 60);
      ObjectSetInteger(0, lblTime, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, lblTime, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblTime, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblTime, OBJPROP_TEXT, timeStr);

   string combinedDataStr = StringFormat("R: %.2f | Angulo: %.1f | CVD: %+.0f", r2, angle, cvd);
   if(ObjectFind(0, lblDist) < 0) {
      ObjectCreate(0, lblDist, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblDist, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblDist, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblDist, OBJPROP_YDISTANCE, 80);
      ObjectSetInteger(0, lblDist, OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, lblDist, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblDist, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblDist, OBJPROP_TEXT, combinedDataStr);

   string combinedTimeStr = StringFormat("Tiempo: %02d:%02d [%s]", minLeft, secLeft, tfStr);
   ObjectSetString(0, lblTime, OBJPROP_TEXT, combinedTimeStr);

   string lblSec2 = "SND_HUD_Sec2";
   if(ObjectFind(0, lblSec2) < 0) {
      ObjectCreate(0, lblSec2, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblSec2, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblSec2, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblSec2, OBJPROP_YDISTANCE, 110);
      ObjectSetInteger(0, lblSec2, OBJPROP_COLOR, clrSandyBrown);
      ObjectSetInteger(0, lblSec2, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblSec2, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblSec2, OBJPROP_TEXT, "=== GESTION DE RIESGO ===");

   string lblShark = "SND_HUD_Shark";
   double cRange = iHigh(_Symbol, _Period, 0) - iLow(_Symbol, _Period, 0);
   double aRange = GetAverageCandleRange(14);
   double rangeRatio = (aRange > 0) ? (cRange / aRange) : 0;

   string sharkStr = "";
   color sharkColor = clrLightGray;
   if(InpUseMomentumBreakout)
   {
      if(rangeRatio >= InpTiburonMinRangeRatio)
      {
         sharkStr = StringFormat("Caza-Tiburones: TIBURON EN VIVO! (x%.1f)", rangeRatio);
         sharkColor = clrTomato;
      }
      else
      {
         sharkStr = StringFormat("Caza-Tiburones: Activo (Rango: %.1fx)", rangeRatio);
         sharkColor = clrMediumSpringGreen;
      }
   }
   else
   {
      sharkStr = "Caza-Tiburones: Inactivo";
      sharkColor = clrDarkGray;
   }

   ObjectDelete(0, lblShark);

   string lblShield = "SND_HUD_Shield";
   string plSign = (g_state.dailyPL >= 0) ? "+" : "";
   string shieldStr = StringFormat("PyG Hoy: %s$%.2f | %.1f/%.1f%%",
                                    plSign, g_state.dailyPL,
                                    MathAbs(g_state.dailyPL) * 100.0 / MathMax(g_state.startOfDayEquity, 0.01),
                                    g_state.effShieldPercent);
   color shieldColor = IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent) ? clrTomato : clrMediumSpringGreen;

   if(ObjectFind(0, lblShield) < 0) {
      ObjectCreate(0, lblShield, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblShield, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblShield, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblShield, OBJPROP_YDISTANCE, 130);
      ObjectSetInteger(0, lblShield, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblShield, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblShield, OBJPROP_TEXT, shieldStr);
   ObjectSetInteger(0, lblShield, OBJPROP_COLOR, shieldColor);

   string lblSession = "SND_HUD_Session";
   ENUM_MARKET_SESSION session = GetMarketSession();
   MqlDateTime dtGMT;
   TimeGMT(dtGMT);
   string gmtStr = StringFormat("%02d:%02d GMT", dtGMT.hour, dtGMT.min);
   string sessionStr = "";
   switch(session) {
      case SESSION_ASIA:   sessionStr = StringFormat("%s | Asia", gmtStr); break;
      case SESSION_LONDON: sessionStr = StringFormat("%s | Londres", gmtStr); break;
      case SESSION_NY:     sessionStr = StringFormat("%s | NY", gmtStr); break;
      default:             sessionStr = StringFormat("%s | Off-Hours", gmtStr); break;
   }
   double rsiVal = CalculateRSI(InpRSIPeriod);

   string profileName = "";
   switch(InpRiskProfile) {
      case 0: profileName = "Conservador"; break;
      case 1: profileName = "Balanceado"; break;
      case 2: profileName = "Agresivo"; break;
      default: profileName = "Manual"; break;
   }
   string combinedProfileStr = StringFormat("Perfil: %s | RSI: %.1f | %s", profileName, rsiVal, sessionStr);
   if(ObjectFind(0, lblSession) < 0) {
      ObjectCreate(0, lblSession, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblSession, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblSession, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblSession, OBJPROP_YDISTANCE, 150);
      ObjectSetInteger(0, lblSession, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblSession, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblSession, OBJPROP_TEXT, combinedProfileStr);
   ObjectSetInteger(0, lblSession, OBJPROP_COLOR, clrSandyBrown);

   double ax = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bx = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minD = 999999;
   bool fz = false;
   bool zoneTraded = false;
   for(int i=0; i<ArraySize(demandZones); i++) {
      if(demandZones[i].active) {
         double ote = demandZones[i].bottom + (demandZones[i].top - demandZones[i].bottom) * InpFib50;
         double d = MathAbs(ax - ote);
         if(d < minD) { minD = d; fz = true; zoneTraded = demandZones[i].traded; }
      }
   }
   for(int i=0; i<ArraySize(supplyZones); i++) {
      if(supplyZones[i].active) {
         double ote = supplyZones[i].top - (supplyZones[i].top - supplyZones[i].bottom) * InpFib50;
         double d = MathAbs(bx - ote);
         if(d < minD) { minD = d; fz = true; zoneTraded = supplyZones[i].traded; }
      }
   }

   int nPos = CountActivePositions(InpMagicNumber, _Symbol, g_pos);
   bool shieldBlocked = IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent);
   bool cooldownOn = false;
   int cdBars = 9999;
   if(InpUseCooldown && lastTradeTime > 0) {
      cdBars = iBarShift(_Symbol, _Period, lastTradeTime);
      if(cdBars < InpCooldownBars) cooldownOn = true;
   }
   string lblSenales1 = "SND_HUD_Signals1";
   string stShark = "Activo";
   string stSMC = "Activo";

   if(nPos >= 1) {
      stSMC = "1 Pos"; stShark = "1 Pos";
   } else {
      if(shieldBlocked)
      { stSMC = "Escudo"; stShark = "Escudo"; }
      else if(cooldownOn) {
         string cdStr = StringFormat("CD %d", cdBars);
         stSMC = cdStr; stShark = cdStr;
      } else {
         if(!fz) stSMC = "sin zona";
      }
   }
   if(!InpUseMomentumBreakout) stShark = "Inactivo";

   string smcStr = fz ? StringFormat("SMC: %dpts %s", (int)(minD/_Point), stSMC) : "SMC: sin zona";

   double ld = GetBarVolumeDelta(0);
   double av = GetAverageAbsoluteVolumeDelta(14);
   double vr = (av > 0) ? (MathAbs(ld) / av) : 0;
   double cr2 = iHigh(_Symbol, _Period, 0) - iLow(_Symbol, _Period, 0);
   double ar2 = GetAverageCandleRange(14);
   double rr2 = (ar2 > 0) ? (cr2 / ar2) : 0;
   string sharkSigStr = StringFormat("Tiburon: rng=%.1f/%.1fx %s", rr2, InpTiburonMinRangeRatio, stShark);
   string sinal1Str = StringFormat("%s | %s", smcStr, sharkSigStr);

   ObjectDelete(0, lblSenales1);
   ObjectDelete(0, "SND_HUD_Signals2");
   ObjectDelete(0, "SND_HUD_Signals3");

   string lblSec3 = "SND_HUD_Sec3";
   if(ObjectFind(0, lblSec3) < 0) {
      ObjectCreate(0, lblSec3, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lblSec3, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lblSec3, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, lblSec3, OBJPROP_YDISTANCE, 180);
      ObjectSetInteger(0, lblSec3, OBJPROP_COLOR, clrMediumSpringGreen);
      ObjectSetInteger(0, lblSec3, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lblSec3, OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, lblSec3, OBJPROP_TEXT, "=== ESTRATEGIAS ===");

   if(ObjectFind(0, "SND_HUD_SMC") < 0) {
      ObjectCreate(0, "SND_HUD_SMC", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "SND_HUD_SMC", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "SND_HUD_SMC", OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, "SND_HUD_SMC", OBJPROP_YDISTANCE, 200);
      ObjectSetInteger(0, "SND_HUD_SMC", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, "SND_HUD_SMC", OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, "SND_HUD_SMC", OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, "SND_HUD_SMC", OBJPROP_TEXT, smcStr);

   if(ObjectFind(0, "SND_HUD_SharkRow") < 0) {
      ObjectCreate(0, "SND_HUD_SharkRow", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "SND_HUD_SharkRow", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "SND_HUD_SharkRow", OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, "SND_HUD_SharkRow", OBJPROP_YDISTANCE, 220);
      ObjectSetInteger(0, "SND_HUD_SharkRow", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, "SND_HUD_SharkRow", OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, "SND_HUD_SharkRow", OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, "SND_HUD_SharkRow", OBJPROP_TEXT, sharkSigStr);

   double askVP = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bidVP = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string vpStatusStr = "";
   color vpColor = clrLightGray;
   if(InpUseVolumeProfile && vah > 0) {
      bool aboveVAH = (askVP > vah);
      bool belowVAL = (bidVP < val);
      if(aboveVAH) {
         vpStatusStr = StringFormat("VP: Compresion ALTA (Ask > VAH: %.5f)", vah);
         vpColor = clrOrange;
      } else if(belowVAL) {
         vpStatusStr = StringFormat("VP: Compresion BAJA (Bid < VAL: %.5f)", val);
         vpColor = clrDodgerBlue;
      } else {
         vpStatusStr = StringFormat("VP: Dentro del Value Area (VAH: %.5f | VAL: %.5f)", vah, val);
         vpColor = clrMediumSpringGreen;
      }
   } else {
      vpStatusStr = "VP: Inactivo";
      vpColor = clrDarkGray;
   }

   if(ObjectFind(0, "SND_HUD_VP") < 0) {
      ObjectCreate(0, "SND_HUD_VP", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_YDISTANCE, 240);
      ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, "SND_HUD_VP", OBJPROP_FONT, "Segoe UI Bold");
   }
   ObjectSetString(0, "SND_HUD_VP", OBJPROP_TEXT, vpStatusStr);
   ObjectSetInteger(0, "SND_HUD_VP", OBJPROP_COLOR, vpColor);
}
