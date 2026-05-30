//+------------------------------------------------------------------+
//|                                           UI/PrecisionUI.mqh       |
//|                          PrecisionSniper EA — Dashboard & Visuals  |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_UI_
#define _PSNIPER_UI_

//+------------------------------------------------------------------+
//| Dashboard helpers                                                  |
//+------------------------------------------------------------------+
void ClearDashboard()
{
   int total = ObjectsTotal(0);
   for(int i = total-1; i >= 0; i--)
      if(StringFind(ObjectName(0,i), DPF) == 0)
         ObjectDelete(0, ObjectName(0,i));
}

void MakeRect(string name, int x, int y, int w, int h, color bg, color border)
{
   if(ObjectFind(0,name) < 0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,      w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,      h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,    bg);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_COLOR,      border);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,name,OBJPROP_BACK,       false);
}

void MakeTxt(string name, int x, int y, string txt, color col, int sz, string font="Arial")
{
   if(ObjectFind(0,name) < 0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,     col);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,  sz);
   ObjectSetString (0,name,OBJPROP_FONT,      font);
   ObjectSetString (0,name,OBJPROP_TEXT,      txt);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,      false);
}

void Row(string id, int x, int y, int w, int h, int lw,
         string lbl, string val, color valC)
{
   color C_PANEL  = C'20,24,40';
   color C_BORDER = C'70,80,120';
   color C_GRAY   = C'160,170,200';
   MakeRect(id+"_BG", x, y, w, h, C_PANEL, C_BORDER);
   MakeTxt (id+"_L",  x+8,    y+4, lbl, C_GRAY, 7, "Arial");
   MakeTxt (id+"_V",  x+lw+8, y+4, val, valC,   8, "Arial Bold");
}

//+------------------------------------------------------------------+
//| UpdateDashboard — full on-chart info panel                         |
//+------------------------------------------------------------------+
void UpdateDashboard(double bScore, double sScore, int htfBias,
                     string volReg, string trend, string status,
                     double rsi, double adx, bool strongTrend)
{
   if(!ShowDashboard) return;

   int X=10, Y=14, W=290, H=20, sep=2;

   double actScore = (g_dir==1)?bScore:(g_dir==-1)?sScore:MathMax(bScore,sScore);
   string wr   = g_btTotal>0 ? DoubleToString(g_btWins*100.0/g_btTotal,1)+"%" : "--";
   string avgR = g_btTotal>0 ? DoubleToString(g_btTotR/g_btTotal,2)+"R" : "--";
   double pf   = g_btGL>0 ? g_btGW/g_btGL : (g_btGW>0?999.0:0.0);
   string pfS  = (pf>=999)?"inf":DoubleToString(pf,2);
   string tpSt = g_tp3h?"TP3":g_tp2h?"TP2":g_tp1h?"TP1":"";

   color C_GREEN  = C'0,230,110';
   color C_RED    = C'255,70,70';
   color C_YELLOW = C'255,220,0';
   color C_GRAY   = C'160,170,200';
   color C_WHITE  = C'240,245,255';
   color C_BLUE   = C'80,160,255';
   color C_GOLD   = C'255,200,50';
   color C_ORANGE = C'255,165,0';
   color C_BORDER = C'70,80,120';
   color C_PANEL  = C'20,24,40';
   color C_HEADER = C'28,34,58';

   string presetNames[] = {"Auto","Scalping","Aggressive","Default","Conservative","Swing","Crypto","Gold","Custom"};
   string gradeNames[]  = {"All","A+ & A","A+ Only"};

   // ── Title bar
   MakeRect(DPF+"T_BG", X, Y, W, 26, C'5,8,25', C_GOLD);
   MakeTxt (DPF+"T_TX", X+8,  Y+6, "PRECISION SNIPER", C_GOLD, 10, "Arial Bold");
   MakeTxt (DPF+"T_PR", X+185,Y+8, "["+presetNames[(int)Preset]+"]", C_GRAY, 8, "Arial");
   Y += 29;

   // ── Trend row
   color trendC = (trend=="Bullish")?C_GREEN:(trend=="Bearish")?C_RED:C_YELLOW;
   MakeRect(DPF+"TR_BG", X, Y, W, H, C_HEADER, trendC);
   MakeTxt (DPF+"TR_L",  X+8,   Y+4, "TREND",  C_GRAY,  7, "Arial");
   MakeTxt (DPF+"TR_V",  X+100, Y+4, trend,    trendC,  8, "Arial Bold");
   string tfStr = "";
   int per = Period();
   if(per==1)tfStr="M1";else if(per==2)tfStr="M2";else if(per==3)tfStr="M3";else if(per==4)tfStr="M4";
   else if(per==5)tfStr="M5";else if(per==6)tfStr="M6";else if(per==10)tfStr="M10";else if(per==12)tfStr="M12";
   else if(per==15)tfStr="M15";else if(per==20)tfStr="M20";else if(per==30)tfStr="M30";
   else if(per==16385)tfStr="H1";else if(per==16386)tfStr="H2";else if(per==16387)tfStr="H3";
   else if(per==16388)tfStr="H4";else if(per==16390)tfStr="H6";else if(per==16392)tfStr="H8";
   else if(per==16396)tfStr="H12";else if(per==16408)tfStr="D1";else if(per==32769)tfStr="W1";
   else if(per==49153)tfStr="MN";else tfStr=IntegerToString(per);
   string symShort = StringSubstr(Symbol(), 0, 6);
   MakeTxt(DPF+"TR_TF", X+190, Y+4, tfStr+" | "+symShort, C_GRAY, 7, "Arial");
   Y += H+sep;

   // ── Score row
   color scC = actScore>=7?C_GREEN:actScore>=5?C_YELLOW:C_RED;
   MakeRect(DPF+"SC_BG", X, Y, W, H, C_PANEL, scC);
   MakeTxt (DPF+"SC_L",  X+8,   Y+4, "SCORE",   C_GRAY, 7, "Arial");
   MakeTxt (DPF+"SC_V",  X+100, Y+4, DoubleToString(actScore,1)+"/10  ["+GetGrade(actScore)+"]", scC, 8, "Arial Bold");
   MakeTxt (DPF+"SC_BS", X+195, Y+4, "B:"+DoubleToString(bScore,1)+" S:"+DoubleToString(sScore,1), C_GRAY, 7, "Arial");
   Y += H+sep;

   // ── Signal bar
   color sigBg = g_dir==1?C'0,80,40':g_dir==-1?C'90,20,20':C'20,22,40';
   color sigBd = g_dir==1?C_GREEN:g_dir==-1?C_RED:C_BORDER;
   string sigTx = g_dir==1?"▲  LONG ACTIVE":g_dir==-1?"▼  SHORT ACTIVE":"—  WAITING FOR SIGNAL";
   MakeRect(DPF+"SG_BG", X, Y, W, H+4, sigBg, sigBd);
   MakeTxt (DPF+"SG_TX", X+8, Y+5, sigTx, sigBd, 9, "Arial Bold");
   if(tpSt!="")
      MakeTxt(DPF+"SG_TP", X+200, Y+7, tpSt+" Hit", C_GREEN, 7, "Arial Bold");
   else
      MakeTxt(DPF+"SG_TP", X+200, Y+7, "", C_GRAY, 7, "Arial");
   Y += H+8;

   // ── Separator
   MakeRect(DPF+"SP1", X, Y, W, 1, C_BORDER, C_BORDER);
   Y += 3;

   // ── Column headers
   int LW=105, VW=W-LW-4;
   MakeRect(DPF+"CH_BG", X, Y, W, H-2, C_HEADER, C_BORDER);
   MakeTxt (DPF+"CH_L",  X+8,      Y+3, "INDICATOR",    C_YELLOW, 7, "Arial Bold");
   MakeTxt (DPF+"CH_V",  X+LW+8,   Y+3, "VALUE",        C_YELLOW, 7, "Arial Bold");
   Y += H;

   // ── Data rows
   string htfStr = htfBias==1?"▲ Bullish":htfBias==-1?"▼ Bearish":"● Neutral";
   color  htfC   = htfBias==1?C_GREEN:htfBias==-1?C_RED:C_YELLOW;
   color  rsiC   = rsi>70?C_RED:rsi<30?C_GREEN:rsi>50?C_GREEN:C_RED;
   color  adxC   = strongTrend?C_GREEN:C_ORANGE;
   color  volC   = volReg=="High"?C_RED:volReg=="Low"?C_GRAY:C_GREEN;

   Row(DPF+"D0", X,Y,W,H,LW, "HTF Bias",   htfStr, htfC); Y+=H+sep;
   Row(DPF+"D1", X,Y,W,H,LW, "RSI",        DoubleToString(rsi,1)+(rsi>70?" OB":rsi<30?" OS":""), rsiC); Y+=H+sep;
   Row(DPF+"D2", X,Y,W,H,LW, "ADX",        DoubleToString(adx,1)+(strongTrend?" Strong":" Weak"), adxC); Y+=H+sep;
   Row(DPF+"D3", X,Y,W,H,LW, "Volatility", volReg, volC); Y+=H+sep;
   Row(DPF+"D4", X,Y,W,H,LW, "Grade Filter", gradeNames[(int)GradeFilter], C_WHITE); Y+=H+sep;

   // ── Separator
   MakeRect(DPF+"SP2", X, Y, W, 1, C_BORDER, C_BORDER);
   Y += 3;

   // ── Backtest header
   string btHeader = "BACKTEST  [All Data]";
   MakeRect(DPF+"BT_BG", X, Y, W, H-2, C_HEADER, C_BLUE);
   MakeTxt (DPF+"BT_TX", X+8, Y+3, btHeader, C_YELLOW, 7, "Arial Bold");
   Y += H;

   string tradesS = IntegerToString(g_btTotal)+"  ("+IntegerToString(g_btWins)+"W / "+IntegerToString(g_btLoss)+"L / "+IntegerToString(g_btBE)+"BE)";
   color  wrC     = g_btTotal>0?(g_btWins*100.0/g_btTotal>=55?C_GREEN:g_btWins*100.0/g_btTotal>=45?C_YELLOW:C_RED):C_GRAY;
   color  totRC   = g_btTotR>0?C_GREEN:g_btTotR<0?C_RED:C_GRAY;
   color  pfC     = pf>=1.5?C_GREEN:pf>=1.0?C_YELLOW:C_RED;

   string tp1S = IntegerToString(g_btTP1)+" hit";
   string tp2S = IntegerToString(g_btTP2)+" hit";
   string tp3S = IntegerToString(g_btTP3)+" hit";
   string slS  = IntegerToString(g_btSL)+" full SL  |  "+IntegerToString(g_btBE)+" BE";
   color  tp1C = g_btTP1>0?C_GREEN:C_GRAY;
   color  tp2C = g_btTP2>0?C_GREEN:C_GRAY;
   color  tp3C = g_btTP3>0?C_GREEN:C_GRAY;
   color  slC  = g_btSL>0?C_RED:C_GRAY;

   Row(DPF+"B0", X,Y,W,H,LW, "Trades",         tradesS,  C_WHITE);    Y+=H+sep;
   Row(DPF+"B1", X,Y,W,H,LW, "Win Rate",        wr,       wrC);       Y+=H+sep;
   Row(DPF+"B2", X,Y,W,H,LW, "Profit Factor",   pfS,      pfC);       Y+=H+sep;
   Row(DPF+"B3", X,Y,W,H,LW, "Avg R",           avgR,     C_WHITE);   Y+=H+sep;
   Row(DPF+"B4", X,Y,W,H,LW, "Total R",         DoubleToString(g_btTotR,2)+"R", totRC); Y+=H+sep;
   Row(DPF+"B5", X,Y,W,H,LW, "TP1 Reached",     tp1S,     tp1C);      Y+=H+sep;
   Row(DPF+"B6", X,Y,W,H,LW, "TP2 Reached",     tp2S,     tp2C);      Y+=H+sep;
   Row(DPF+"B7", X,Y,W,H,LW, "TP3 Reached",     tp3S,     tp3C);      Y+=H+sep;
   Row(DPF+"B8", X,Y,W,H,LW, "SL / BE",         slS,      slC);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| DrawEMAs — paint fast/slow/trend EMA lines on chart                |
//+------------------------------------------------------------------+
void DrawEMAs()
{
   if(!ShowEMA) return;

   int visBars = 200;
   datetime timeArr[];
   ArraySetAsSeries(timeArr, true);
   if(CopyTime(_Symbol, _Period, 0, visBars, timeArr) <= 0) return;

   double ef[], es[], et[];
   ArraySetAsSeries(ef, true); ArraySetAsSeries(es, true); ArraySetAsSeries(et, true);
   if(CopyBuffer(hEmaFast, 0, 0, visBars, ef) <= 0) return;
   if(CopyBuffer(hEmaSlow, 0, 0, visBars, es) <= 0) return;
   if(CopyBuffer(hEmaTrend, 0, 0, visBars, et) <= 0) return;

   int cnt = MathMin(visBars, ArraySize(ef));
   cnt = MathMin(cnt, ArraySize(timeArr));

   for(int i = 0; i < cnt-1; i++)
   {
      string id_ef = "PSV_EF_" + IntegerToString(i);
      string id_es = "PSV_ES_" + IntegerToString(i);
      string id_et = "PSV_ET_" + IntegerToString(i);

      if(ObjectFind(0, id_ef) < 0)
      {
         ObjectCreate(0, id_ef, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, id_ef, OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, id_ef, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, id_ef, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, id_ef, OBJPROP_SELECTABLE, false);
      }
      if(ObjectFind(0, id_es) < 0)
      {
         ObjectCreate(0, id_es, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, id_es, OBJPROP_COLOR, clrOrangeRed);
         ObjectSetInteger(0, id_es, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, id_es, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, id_es, OBJPROP_SELECTABLE, false);
      }
      if(ObjectFind(0, id_et) < 0)
      {
         ObjectCreate(0, id_et, OBJ_TREND, 0, 0, 0, 0, 0);
         ObjectSetInteger(0, id_et, OBJPROP_COLOR, C'105,105,105');
         ObjectSetInteger(0, id_et, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, id_et, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, id_et, OBJPROP_SELECTABLE, false);
      }

      ObjectSetInteger(0, id_ef, OBJPROP_TIME, 0, timeArr[i]);
      ObjectSetDouble(0, id_ef, OBJPROP_PRICE, 0, ef[i]);
      ObjectSetInteger(0, id_ef, OBJPROP_TIME, 1, timeArr[i+1]);
      ObjectSetDouble(0, id_ef, OBJPROP_PRICE, 1, ef[i+1]);

      ObjectSetInteger(0, id_es, OBJPROP_TIME, 0, timeArr[i]);
      ObjectSetDouble(0, id_es, OBJPROP_PRICE, 0, es[i]);
      ObjectSetInteger(0, id_es, OBJPROP_TIME, 1, timeArr[i+1]);
      ObjectSetDouble(0, id_es, OBJPROP_PRICE, 1, es[i+1]);

      ObjectSetInteger(0, id_et, OBJPROP_TIME, 0, timeArr[i]);
      ObjectSetDouble(0, id_et, OBJPROP_PRICE, 0, et[i]);
      ObjectSetInteger(0, id_et, OBJPROP_TIME, 1, timeArr[i+1]);
      ObjectSetDouble(0, id_et, OBJPROP_PRICE, 1, et[i+1]);
   }

   // Hide excess segments beyond visible range
   for(int i = cnt-1; i < cnt+50; i++)
   {
      string id_ef = "PSV_EF_" + IntegerToString(i);
      string id_es = "PSV_ES_" + IntegerToString(i);
      string id_et = "PSV_ET_" + IntegerToString(i);
      if(ObjectFind(0, id_ef) >= 0) ObjectDelete(0, id_ef);
      if(ObjectFind(0, id_es) >= 0) ObjectDelete(0, id_es);
      if(ObjectFind(0, id_et) >= 0) ObjectDelete(0, id_et);
   }
}

//+------------------------------------------------------------------+
//| DrawSignalArrow — mark buy/sell signals on chart                   |
//+------------------------------------------------------------------+
void DrawSignalArrow(datetime barTime, double price, int direction)
{
   if(!ShowSignals) return;

   string name = "PSV_AR_" + IntegerToString(barTime);
   if(ObjectFind(0, name) >= 0) return;

   ObjectCreate(0, name, OBJ_ARROW, 0, barTime, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, direction == 1 ? 233 : 234);
   ObjectSetInteger(0, name, OBJPROP_COLOR, direction == 1 ? clrLime : clrRed);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| UpdateTrailLine — refresh trail stop line on every tick             |
//+------------------------------------------------------------------+
void UpdateTrailLine()
{
   if(!UseTrail || !ShowTrail || g_dir == 0 || g_slh) return;

   if(ObjectFind(0, "PSL_TR") >= 0)
   {
      ObjectSetDouble(0, "PSL_TR", OBJPROP_PRICE, 0, g_trail);
      ObjectSetDouble(0, "PSL_TR", OBJPROP_PRICE, 1, g_trail);
   }
}

//+------------------------------------------------------------------+
//| ClearVisuals — remove EMA lines (keep arrows)                       |
//+------------------------------------------------------------------+
void ClearVisuals()
{
   int total = ObjectsTotal(0);
   for(int i = total-1; i >= 0; i--)
   {
      string nm = ObjectName(0, i);
      if(StringFind(nm, "PSV_") == 0 && StringFind(nm, "PSV_AR_") != 0)
         ObjectDelete(0, nm);
   }
}

//+------------------------------------------------------------------+
//| DrawTPSLLines — paint entry, SL, TP1/2/3 and trail lines           |
//+------------------------------------------------------------------+
void DrawTPSLLines()
{
   if(!ShowTPSL) return;
   ObjectsDeleteAll(0, "PSL_");

   datetime tEnd = TimeCurrent() + (datetime)(PeriodSeconds(PERIOD_CURRENT) * 5000);
   datetime signalTime = TimeCurrent();

   struct LevelDef { string name; double price; color clr; int wid; ENUM_LINE_STYLE sty; string lbl; };
   LevelDef lvl[5];
   lvl[0].name="PSL_EN"; lvl[0].price=g_entry; lvl[0].clr=clrDodgerBlue; lvl[0].wid=2; lvl[0].sty=STYLE_SOLID; lvl[0].lbl="ENTRY "+DoubleToString(g_entry,_Digits);
   lvl[1].name="PSL_SL"; lvl[1].price=g_sl;    lvl[1].clr=clrRed;        lvl[1].wid=2; lvl[1].sty=STYLE_SOLID; lvl[1].lbl="SL "   +DoubleToString(g_sl,_Digits);
   lvl[2].name="PSL_T1"; lvl[2].price=g_tp1;   lvl[2].clr=clrLimeGreen;  lvl[2].wid=1; lvl[2].sty=STYLE_DASH;  lvl[2].lbl="TP1 "  +DoubleToString(g_tp1,_Digits);
   lvl[3].name="PSL_T2"; lvl[3].price=g_tp2;   lvl[3].clr=clrLimeGreen;  lvl[3].wid=1; lvl[3].sty=STYLE_DASH;  lvl[3].lbl="TP2 "  +DoubleToString(g_tp2,_Digits);
   lvl[4].name="PSL_T3"; lvl[4].price=g_tp3;   lvl[4].clr=clrLimeGreen;  lvl[4].wid=2; lvl[4].sty=STYLE_DASH;  lvl[4].lbl="TP3 "  +DoubleToString(g_tp3,_Digits);

   for(int i=0; i<5; i++)
   {
      ObjectCreate(0, lvl[i].name, OBJ_TREND, 0, signalTime, lvl[i].price, tEnd, lvl[i].price);
      ObjectSetInteger(0, lvl[i].name, OBJPROP_COLOR, lvl[i].clr);
      ObjectSetInteger(0, lvl[i].name, OBJPROP_WIDTH, lvl[i].wid);
      ObjectSetInteger(0, lvl[i].name, OBJPROP_STYLE, lvl[i].sty);
      ObjectSetInteger(0, lvl[i].name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, lvl[i].name, OBJPROP_SELECTABLE, false);

      string lb = lvl[i].name+"_lb";
      ObjectCreate(0, lb, OBJ_TEXT, 0, TimeCurrent()+PeriodSeconds(PERIOD_CURRENT)*2, lvl[i].price);
      ObjectSetString(0, lb, OBJPROP_TEXT, lvl[i].lbl);
      ObjectSetInteger(0, lb, OBJPROP_COLOR, lvl[i].clr);
      ObjectSetInteger(0, lb, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, lb, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, lb, OBJPROP_SELECTABLE, false);
   }

   if(UseTrail && ShowTrail)
   {
      ObjectCreate(0, "PSL_TR", OBJ_TREND, 0, signalTime, g_trail, tEnd, g_trail);
      ObjectSetInteger(0, "PSL_TR", OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(0, "PSL_TR", OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, "PSL_TR", OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, "PSL_TR", OBJPROP_SELECTABLE, false);
   }

   // Update existing trail line price
   if(UseTrail && ShowTrail && ObjectFind(0, "PSL_TR") >= 0 && g_dir != 0 && !g_slh)
   {
      ObjectSetDouble(0, "PSL_TR", OBJPROP_PRICE, 0, g_trail);
      ObjectSetDouble(0, "PSL_TR", OBJPROP_PRICE, 1, g_trail);
   }
   ChartRedraw(0);
}

#endif // _PSNIPER_UI_
