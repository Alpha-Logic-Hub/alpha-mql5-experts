//+------------------------------------------------------------------+
//|                                              UI/TerminalUI.mqh     |
//|        PrecisionSniper — Terminal Hacker UI (Panel + Visuals)      |
//+------------------------------------------------------------------+
#ifndef _TERMINAL_UI_
#define _TERMINAL_UI_

#include "..\Core\Definitions.mqh"

// ── Colors ──────────────────────────────────────────────────────────
color CRT_GREEN    = C'0,255,65';
color CRT_DIM      = C'0,160,40';
color CRT_FAINT    = C'0,70,25';
color CRT_BG       = C'0,2,0';
color CRT_PANEL    = C'2,6,2';
color CRT_BORDER   = C'0,90,30';
color CRT_AMBER    = C'255,200,0';
color CRT_RED      = C'255,55,55';
color CRT_WHITE    = C'200,255,200';
color CRT_BLACK    = C'0,0,0';
color CRT_CYAN     = C'0,212,255';
color CRT_PINK     = C'255,45,117';

#define PX 10
#define PY 10
#define PW 310
#define RH 24
#define MATRIX_COUNT 18

string  g_mxSymbols[];
int     g_mxX[], g_mxY[], g_mxSpeed[];
color   g_mxColor[];
bool    g_matrixInit = false;

//+------------------------------------------------------------------+
//| TBox / TLbl — panel building blocks (fully opaque)                 |
//+------------------------------------------------------------------+
void TBox(string id, int x, int y, int w, int h, color bg, color bd)
{
   ObjectDelete(0,id);  // force recreate to prevent stale objects
   ObjectCreate(0,id,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,w);     ObjectSetInteger(0,id,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,id,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,id,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,id,OBJPROP_BACK,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
}

void TLbl(string id, int x, int y, string t, color c, int s, string f="Consolas")
{
   ObjectDelete(0,id);  // force recreate
   ObjectCreate(0,id,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,id,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,id,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,id,OBJPROP_COLOR,c);     ObjectSetInteger(0,id,OBJPROP_FONTSIZE,s);
   ObjectSetString(0,id,OBJPROP_FONT,f);
   ObjectSetInteger(0,id,OBJPROP_BACK,false);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,false);
   ObjectSetString(0,id,OBJPROP_TEXT,t);
}

string Blink() { return ((GetTickCount()/600)%2==0)?"█":" "; }

//+------------------------------------------------------------------+
//| DrawTerminal — panel de datos en vivo (fully opaque)               |
//+------------------------------------------------------------------+
void DrawTerminal()
{
   if(!ShowPanel) { ClearTerminal(); return; }

   // Clean ALL old panel objects to prevent overlapping text
   ObjectsDeleteAll(0, "trm_");

   double ef[],es[],et[],atr[];
   ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);ArraySetAsSeries(et,true);ArraySetAsSeries(atr,true);
   CopyBuffer(hEmaFast,0,0,1,ef);CopyBuffer(hEmaSlow,0,0,1,es);CopyBuffer(hEmaTrend,0,0,1,et);CopyBuffer(hATR,0,0,1,atr);

   double spread = (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   int bars = iBars(_Symbol,_Period);
   int activeCnt = GetActiveCount();
   int rows = 2+4+1+3+1+(activeCnt>0?activeCnt:2)+4;
   int panelH = rows*RH+12, Y=PY;

   TBox("trm_bg",PX-2,PY-2,PW+4,panelH+4,CRT_BLACK,CRT_BORDER);
   TBox("trm_pn",PX,PY,PW,panelH,C'4,6,12',C'0,25,10');

   string ts = TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   string blink = Blink();
   TLbl("trm_h1",PX+10,Y+2,"PRECISION SNIPER",CRT_WHITE,10);
   TLbl("trm_h2",PX+PW-100,Y+2,ts,CRT_FAINT,7);
   Y+=RH+2; TBox("trm_s0",PX+6,Y,PW-12,1,CRT_BORDER,CRT_BORDER); Y+=4;

   string fStr=StringFormat("EMA%d %.5f",pFast,ef[0]), sStr=StringFormat("EMA%d %.5f",pSlow,es[0]), tStr=StringFormat("EMA%d %.5f",pTrend,et[0]);
   TLbl("trm_e1",PX+10,Y+2,fStr,(ef[0]>es[0])?CRT_GREEN:CRT_RED,8); Y+=RH;
   TLbl("trm_e2",PX+10,Y+2,sStr,(es[0]>ef[0])?CRT_GREEN:CRT_RED,8); Y+=RH;
   TLbl("trm_e3",PX+10,Y+2,tStr,CRT_FAINT,8); Y+=RH;
   TLbl("trm_gp",PX+10,Y+2,StringFormat("brecha %.0fpts | spread %.1f | ATR %s",MathAbs(ef[0]-es[0])/_Point,spread,DoubleToString(atr[0],_Digits)),CRT_DIM,8);
   Y+=RH+2; TBox("trm_s1",PX+6,Y,PW-12,1,CRT_BORDER,CRT_BORDER); Y+=4;

   if(activeCnt>0)
   {
      for(int si=0;si<MAX_STRATEGIES;si++)
      {
         if(!g_strat[si].active) continue;
         StrategyPos p=g_strat[si];
         double cur=(p.direction==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double pips=(p.direction==1)?(cur-p.entry)/_Point:(p.entry-cur)/_Point;
         double rMult=(p.risk>0)?MathAbs(cur-p.entry)/p.risk:0;
         if(p.direction==-1) rMult=(p.risk>0)?MathAbs(p.entry-cur)/p.risk:0;
         string ln=StringFormat("[%s] %s | %+.0fpts %.1fR",g_stratNames[si],p.direction==1?"LONG":"SHORT",pips,rMult);
         TLbl("trm_p"+IntegerToString(si),PX+14,Y+2,ln,(p.direction==1)?CRT_CYAN:CRT_PINK,9);
         Y+=RH;
      }
   }
   else
   {
      int bias=GetFullBias();
      string bs=(bias==1)?"ALCISTA":(bias==-1)?"BAJISTA":"NEUTRAL";
      TLbl("trm_st",PX+14,Y+2,"SESGO: "+bs,(bias==1)?CRT_GREEN:(bias==-1)?CRT_RED:CRT_AMBER,9);
      Y+=RH;
      if(g_smcPendingDir!=0)
         TLbl("trm_sg",PX+14,Y+2,"ESPERANDO "+(g_smcPendingDir==1?"COMPRA":"VENTA")+" en zona...",CRT_AMBER,8);
      else
      {
         int fC=0,oC=0;
         for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled) fC++;
         for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated) oC++;
         if(fC+oC>0) TLbl("trm_sg",PX+14,Y+2,"VIGILANDO FVG:"+IntegerToString(fC)+" OB:"+IntegerToString(oC),CRT_DIM,8);
         else TLbl("trm_sg",PX+14,Y+2,"esperando estructura...",CRT_FAINT,8);
      }
   }
   Y+=RH+2; TBox("trm_s2",PX+6,Y,PW-12,1,CRT_BORDER,CRT_BORDER); Y+=4;

   string ses=GetCurrentSession(),news=GetNewsStatus();
   TLbl("trm_sx",PX+10,Y+2,ses+" | "+news+" | DB:"+(g_dailyBias==1?"▲":g_dailyBias==-1?"▼":"●")+" | H4:"+(GetMTFBias()==1?"▲":GetMTFBias()==-1?"▼":"●"),CRT_DIM,8);
   Y+=RH;

   if(g_statTotal>0)
   {
      double wr=(double)g_statWins/g_statTotal*100, pf=g_statLossR>0?g_statWinR/g_statLossR:(g_statWinR>0?99:0);
      TLbl("trm_st1",PX+10,Y+2,StringFormat("%d/%d | %.0f%% | PF %.2f | %.1fR",g_statWins,g_statTotal,wr,pf,g_statTotalR),CRT_DIM,8);
      Y+=RH;
   }
   TLbl("trm_sy",PX+10,Y+2,"sys:OK | "+IntegerToString(bars)+" barras",CRT_FAINT,8); Y+=RH;
   TLbl("trm_ft",PX+10,Y+2,"$ _",CRT_GREEN,9);
   TLbl("trm_cr",PX+10+18,Y+2,blink,CRT_GREEN,9);
   ChartRedraw(0);
}

void ClearTerminal() { ObjectsDeleteAll(0,"trm_"); }

//+------------------------------------------------------------------+
//| DrawEMAs — líneas EMA en chart                                     |
//+------------------------------------------------------------------+
void DrawEMAs()
{
   if(!ShowEMA) return;
   int visBars=300;
   datetime timeArr[]; ArraySetAsSeries(timeArr,true);
   if(CopyTime(_Symbol,_Period,0,visBars,timeArr)<=0) return;
   double ef[],es[],et[]; ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);ArraySetAsSeries(et,true);
   if(CopyBuffer(hEmaFast,0,0,visBars,ef)<=0)return;
   if(CopyBuffer(hEmaSlow,0,0,visBars,es)<=0)return;
   if(CopyBuffer(hEmaTrend,0,0,visBars,et)<=0)return;
   int cnt=MathMin(visBars,MathMin(ArraySize(ef),ArraySize(timeArr)));
   for(int i=0;i<cnt-1;i++)
   {
      string fe="PSV_EF_"+IntegerToString(i),se="PSV_ES_"+IntegerToString(i),te="PSV_ET_"+IntegerToString(i);
      if(ObjectFind(0,fe)<0){ObjectCreate(0,fe,OBJ_TREND,0,0,0,0,0);ObjectSetInteger(0,fe,OBJPROP_COLOR,CRT_GREEN);ObjectSetInteger(0,fe,OBJPROP_WIDTH,2);ObjectSetInteger(0,fe,OBJPROP_STYLE,STYLE_SOLID);ObjectSetInteger(0,fe,OBJPROP_SELECTABLE,false);}
      if(ObjectFind(0,se)<0){ObjectCreate(0,se,OBJ_TREND,0,0,0,0,0);ObjectSetInteger(0,se,OBJPROP_COLOR,CRT_DIM);ObjectSetInteger(0,se,OBJPROP_WIDTH,2);ObjectSetInteger(0,se,OBJPROP_STYLE,STYLE_SOLID);ObjectSetInteger(0,se,OBJPROP_SELECTABLE,false);}
      if(ObjectFind(0,te)<0){ObjectCreate(0,te,OBJ_TREND,0,0,0,0,0);ObjectSetInteger(0,te,OBJPROP_COLOR,CRT_FAINT);ObjectSetInteger(0,te,OBJPROP_WIDTH,1);ObjectSetInteger(0,te,OBJPROP_STYLE,STYLE_DASH);ObjectSetInteger(0,te,OBJPROP_SELECTABLE,false);}
      ObjectSetInteger(0,fe,OBJPROP_TIME,0,timeArr[i]);ObjectSetDouble(0,fe,OBJPROP_PRICE,0,ef[i]);ObjectSetInteger(0,fe,OBJPROP_TIME,1,timeArr[i+1]);ObjectSetDouble(0,fe,OBJPROP_PRICE,1,ef[i+1]);
      ObjectSetInteger(0,se,OBJPROP_TIME,0,timeArr[i]);ObjectSetDouble(0,se,OBJPROP_PRICE,0,es[i]);ObjectSetInteger(0,se,OBJPROP_TIME,1,timeArr[i+1]);ObjectSetDouble(0,se,OBJPROP_PRICE,1,es[i+1]);
      ObjectSetInteger(0,te,OBJPROP_TIME,0,timeArr[i]);ObjectSetDouble(0,te,OBJPROP_PRICE,0,et[i]);ObjectSetInteger(0,te,OBJPROP_TIME,1,timeArr[i+1]);ObjectSetDouble(0,te,OBJPROP_PRICE,1,et[i+1]);
   }
   for(int i=cnt-1;i<cnt+50;i++){if(ObjectFind(0,"PSV_EF_"+IntegerToString(i))>=0)ObjectDelete(0,"PSV_EF_"+IntegerToString(i));if(ObjectFind(0,"PSV_ES_"+IntegerToString(i))>=0)ObjectDelete(0,"PSV_ES_"+IntegerToString(i));if(ObjectFind(0,"PSV_ET_"+IntegerToString(i))>=0)ObjectDelete(0,"PSV_ET_"+IntegerToString(i));}
}

//+------------------------------------------------------------------+
//| DrawSignalArrow + ClearVisuals                                     |
//+------------------------------------------------------------------+
void DrawSignalArrow(int direction)
{
   if(!ShowSignals) return;
   datetime barTime=iTime(_Symbol,_Period,1);
   MqlRates prev[1]; if(CopyRates(_Symbol,_Period,1,1,prev)<=0) return;
   double atrBuf[1],cAtr=0; if(CopyBuffer(hATR,0,1,1,atrBuf)>0)cAtr=atrBuf[0];
   double price=(direction==1)?prev[0].low-cAtr*0.6:prev[0].high+cAtr*0.6;
   string nm="PSV_AR_"+IntegerToString(barTime),lb="PSV_LB_"+IntegerToString(barTime);
   if(ObjectFind(0,nm)<0){ObjectCreate(0,nm,OBJ_ARROW,0,barTime,price);ObjectSetInteger(0,nm,OBJPROP_ARROWCODE,direction==1?241:242);ObjectSetInteger(0,nm,OBJPROP_COLOR,direction==1?CRT_GREEN:CRT_RED);ObjectSetInteger(0,nm,OBJPROP_WIDTH,4);ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);}
   if(ObjectFind(0,lb)<0){ObjectCreate(0,lb,OBJ_TEXT,0,barTime,price-cAtr*0.3);ObjectSetString(0,lb,OBJPROP_TEXT,direction==1?"[BUY]":"[SELL]");ObjectSetInteger(0,lb,OBJPROP_COLOR,direction==1?CRT_GREEN:CRT_RED);ObjectSetInteger(0,lb,OBJPROP_FONTSIZE,9);ObjectSetString(0,lb,OBJPROP_FONT,"Consolas Bold");ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);}
}
void ClearVisuals(){ObjectsDeleteAll(0,"PSV_");}

//+------------------------------------------------------------------+
//| DrawTPSLLines — entry/SL/TP/trail                                  |
//+------------------------------------------------------------------+
void DrawTPSLLines()
{
   if(!ShowTPSL)return;ObjectsDeleteAll(0,"PSL_");
   int si=-1;for(int i=0;i<MAX_STRATEGIES;i++)if(g_strat[i].active){si=i;break;}
   if(si<0)return;
   StrategyPos p=g_strat[si];
   datetime tEnd=TimeCurrent()+(datetime)(PeriodSeconds(PERIOD_CURRENT)*5000),st=TimeCurrent();
   struct L{string n;double pr;color c;int w;ENUM_LINE_STYLE s;string t;};
   L lv[3];
   lv[0].n="PSL_EN";lv[0].pr=p.entry;lv[0].c=CRT_WHITE;lv[0].w=2;lv[0].s=STYLE_SOLID;lv[0].t="[ENTRY] "+DoubleToString(p.entry,_Digits);
   lv[1].n="PSL_SL";lv[1].pr=p.sl;lv[1].c=CRT_RED;lv[1].w=2;lv[1].s=STYLE_SOLID;lv[1].t="[SL] "+DoubleToString(p.sl,_Digits);
   lv[2].n="PSL_TP";lv[2].pr=p.tp1;lv[2].c=CRT_GREEN;lv[2].w=2;lv[2].s=STYLE_DASH;lv[2].t="[TP] "+DoubleToString(p.tp1,_Digits);
   for(int i=0;i<3;i++){ObjectCreate(0,lv[i].n,OBJ_TREND,0,st,lv[i].pr,tEnd,lv[i].pr);ObjectSetInteger(0,lv[i].n,OBJPROP_COLOR,lv[i].c);ObjectSetInteger(0,lv[i].n,OBJPROP_WIDTH,lv[i].w);ObjectSetInteger(0,lv[i].n,OBJPROP_STYLE,lv[i].s);ObjectSetInteger(0,lv[i].n,OBJPROP_RAY_RIGHT,true);ObjectSetInteger(0,lv[i].n,OBJPROP_SELECTABLE,false);
      string lb=lv[i].n+"_lb";ObjectCreate(0,lb,OBJ_TEXT,0,TimeCurrent()+PeriodSeconds(PERIOD_CURRENT)*2,lv[i].pr);ObjectSetString(0,lb,OBJPROP_TEXT,lv[i].t);ObjectSetInteger(0,lb,OBJPROP_COLOR,lv[i].c);ObjectSetInteger(0,lb,OBJPROP_FONTSIZE,8);ObjectSetString(0,lb,OBJPROP_FONT,"Consolas Bold");ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);}
   if(UseTrail){ObjectCreate(0,"PSL_TR",OBJ_TREND,0,st,p.trail,tEnd,p.trail);ObjectSetInteger(0,"PSL_TR",OBJPROP_COLOR,CRT_AMBER);ObjectSetInteger(0,"PSL_TR",OBJPROP_STYLE,STYLE_DOT);ObjectSetInteger(0,"PSL_TR",OBJPROP_WIDTH,2);ObjectSetInteger(0,"PSL_TR",OBJPROP_RAY_RIGHT,true);ObjectSetInteger(0,"PSL_TR",OBJPROP_SELECTABLE,false);}
   ChartRedraw(0);
}

void UpdateTrailLine()
{
   if(!UseTrail)return;
   int si=-1;for(int i=0;i<MAX_STRATEGIES;i++)if(g_strat[i].active){si=i;break;}
   if(si<0||g_strat[si].slh)return;
   if(ObjectFind(0,"PSL_TR")>=0){ObjectSetDouble(0,"PSL_TR",OBJPROP_PRICE,0,g_strat[si].trail);ObjectSetDouble(0,"PSL_TR",OBJPROP_PRICE,1,g_strat[si].trail);}
}

//+------------------------------------------------------------------+
//| Matrix Rain + Session BG + Brand + Watermark                       |
//+------------------------------------------------------------------+
void InitMatrix()
{
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,C'0,60,20');
   ChartSetInteger(0,CHART_COLOR_GRID,C'0,35,15');
   ChartSetInteger(0,CHART_COLOR_CHART_LINE,CRT_GREEN);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,CRT_GREEN);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,C'0,40,15');
   ChartSetInteger(0,CHART_COLOR_CHART_UP,CRT_GREEN);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,CRT_FAINT);
   ChartSetInteger(0,CHART_COLOR_BID,CRT_GREEN);
   ChartSetInteger(0,CHART_COLOR_ASK,CRT_RED);
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,CRT_RED);
   ChartSetInteger(0,CHART_COLOR_LAST,CRT_AMBER);
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);
   ChartSetInteger(0,CHART_SCALE,4);
   ChartSetInteger(0,CHART_SHOW_GRID,true);
   ChartSetInteger(0,CHART_SHOW_VOLUMES,false);

   // Brand
   string bt="mx_topb",bm="mx_midb",bb="mx_botb";
   if(ObjectFind(0,bt)<0){ObjectCreate(0,bt,OBJ_LABEL,0,0,0);ObjectSetInteger(0,bt,OBJPROP_CORNER,CORNER_LEFT_LOWER);ObjectSetInteger(0,bt,OBJPROP_YDISTANCE,58);ObjectSetInteger(0,bt,OBJPROP_COLOR,C'0,35,16');ObjectSetInteger(0,bt,OBJPROP_FONTSIZE,9);ObjectSetString(0,bt,OBJPROP_FONT,"Consolas");ObjectSetInteger(0,bt,OBJPROP_SELECTABLE,false);}
   if(ObjectFind(0,bm)<0){ObjectCreate(0,bm,OBJ_LABEL,0,0,0);ObjectSetInteger(0,bm,OBJPROP_CORNER,CORNER_LEFT_LOWER);ObjectSetInteger(0,bm,OBJPROP_YDISTANCE,40);ObjectSetInteger(0,bm,OBJPROP_COLOR,C'0,55,25');ObjectSetInteger(0,bm,OBJPROP_FONTSIZE,13);ObjectSetString(0,bm,OBJPROP_FONT,"Consolas Bold");ObjectSetInteger(0,bm,OBJPROP_SELECTABLE,false);}
   if(ObjectFind(0,bb)<0){ObjectCreate(0,bb,OBJ_LABEL,0,0,0);ObjectSetInteger(0,bb,OBJPROP_CORNER,CORNER_LEFT_LOWER);ObjectSetInteger(0,bb,OBJPROP_YDISTANCE,14);ObjectSetInteger(0,bb,OBJPROP_COLOR,C'0,35,16');ObjectSetInteger(0,bb,OBJPROP_FONTSIZE,9);ObjectSetString(0,bb,OBJPROP_FONT,"Consolas");ObjectSetInteger(0,bb,OBJPROP_SELECTABLE,false);}

   // Watermark "A"
   string wm="mx_alpha";
   if(ObjectFind(0,wm)<0){ObjectCreate(0,wm,OBJ_LABEL,0,0,0);ObjectSetInteger(0,wm,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetString(0,wm,OBJPROP_TEXT,"A");ObjectSetInteger(0,wm,OBJPROP_COLOR,C'0,30,16');ObjectSetInteger(0,wm,OBJPROP_FONTSIZE,200);ObjectSetString(0,wm,OBJPROP_FONT,"Verdana Bold");ObjectSetInteger(0,wm,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,wm,OBJPROP_BACK,true);}

   // Matrix symbols
   string syms[]={"$","¥","₿","€","0","1","¢","£","¤","@","*","#","λ","Σ","Δ"};
   int symCnt=ArraySize(syms);
   ArrayResize(g_mxSymbols,MATRIX_COUNT);ArrayResize(g_mxX,MATRIX_COUNT);ArrayResize(g_mxY,MATRIX_COUNT);ArrayResize(g_mxSpeed,MATRIX_COUNT);ArrayResize(g_mxColor,MATRIX_COUNT);
   color cols[]={CRT_FAINT,CRT_FAINT,CRT_FAINT,CRT_DIM,CRT_DIM,CRT_GREEN};
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   for(int i=0;i<MATRIX_COUNT;i++)
   {
      g_mxSymbols[i]=syms[MathRand()%symCnt];g_mxX[i]=MathRand()%cw;g_mxY[i]=MathRand()%ch;g_mxSpeed[i]=2+MathRand()%6;g_mxColor[i]=cols[MathRand()%6];
      string nm="mx_"+IntegerToString(i);
      ObjectCreate(0,nm,OBJ_LABEL,0,0,0);ObjectSetInteger(0,nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,g_mxX[i]);ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,g_mxY[i]);ObjectSetString(0,nm,OBJPROP_TEXT,g_mxSymbols[i]);ObjectSetInteger(0,nm,OBJPROP_COLOR,g_mxColor[i]);ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,8+MathRand()%6);ObjectSetString(0,nm,OBJPROP_FONT,"Consolas");ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,nm,OBJPROP_BACK,true);
   }
   g_matrixInit=true;
}

void UpdateMatrix()
{
   if(!g_matrixInit)InitMatrix();
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS),ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);

   // Session BG
   string ses=GetCurrentSession(); color sesBG;
   if(StringFind(ses,"LON")>=0&&StringFind(ses,"NY")>=0)sesBG=C'3,16,8';
   else if(StringFind(ses,"LONDON")>=0)sesBG=C'3,14,5';
   else if(StringFind(ses,"NEW YORK")>=0)sesBG=C'5,5,14';
   else if(StringFind(ses,"ASIA")>=0)sesBG=C'8,5,5';
   else sesBG=C'3,3,3';
   static string g_lastSes="";static bool si=false;
   if(!si||g_lastSes!=ses){g_lastSes=ses;si=true;ChartSetInteger(0,CHART_COLOR_BACKGROUND,sesBG);}

   int centerX=cw/2;

   // Session name
   string swm="mx_session";
   if(ObjectFind(0,swm)<0){ObjectCreate(0,swm,OBJ_LABEL,0,0,0);ObjectSetInteger(0,swm,OBJPROP_CORNER,CORNER_LEFT_UPPER);ObjectSetInteger(0,swm,OBJPROP_COLOR,C'0,50,25');ObjectSetInteger(0,swm,OBJPROP_FONTSIZE,36);ObjectSetString(0,swm,OBJPROP_FONT,"Verdana Bold");ObjectSetInteger(0,swm,OBJPROP_SELECTABLE,false);ObjectSetInteger(0,swm,OBJPROP_BACK,true);}
   int sw=StringLen(ses)*20,sx=centerX-sw/2;if(sx<0)sx=5;
   ObjectSetInteger(0,swm,OBJPROP_XDISTANCE,sx);ObjectSetInteger(0,swm,OBJPROP_YDISTANCE,80);ObjectSetString(0,swm,OBJPROP_TEXT,ses);

   // Brand box
   int boxW=cw/9;if(boxW<30)boxW=30;if(boxW>55)boxW=55;
   string tl=".";for(int j=0;j<boxW;j++)tl+="-";tl+=".";
   string mt="|  ALPHA LOGIC HUB  |";
   string bl="'";for(int j=0;j<boxW;j++)bl+="-";bl+="'";
   int tw=(boxW+2)*9,mw=StringLen(mt)*9,bw=(boxW+2)*9;
   int tx=centerX-tw/2,mx=centerX-mw/2,bx=centerX-bw/2;if(tx<0)tx=5;if(mx<0)mx=5;if(bx<0)bx=5;
   if(ObjectFind(0,"mx_topb")>=0){ObjectSetInteger(0,"mx_topb",OBJPROP_XDISTANCE,tx);ObjectSetString(0,"mx_topb",OBJPROP_TEXT,tl);}
   if(ObjectFind(0,"mx_midb")>=0){ObjectSetInteger(0,"mx_midb",OBJPROP_XDISTANCE,mx);ObjectSetString(0,"mx_midb",OBJPROP_TEXT,mt);}
   if(ObjectFind(0,"mx_botb")>=0){ObjectSetInteger(0,"mx_botb",OBJPROP_XDISTANCE,bx);ObjectSetString(0,"mx_botb",OBJPROP_TEXT,bl);}

   // Watermark "A"
   if(ObjectFind(0,"mx_alpha")>=0){int aw=130,ax=centerX-aw/2,ay=(ch-260)/2;if(ax<0)ax=5;if(ay<0)ay=40;ObjectSetInteger(0,"mx_alpha",OBJPROP_XDISTANCE,ax);ObjectSetInteger(0,"mx_alpha",OBJPROP_YDISTANCE,ay);}

   // Matrix rain
   string syms[]={"$","¥","₿","€","0","1","¢","£","¤","@","*","#","λ","Σ","Δ"};
   for(int i=0;i<MATRIX_COUNT;i++)
   {
      g_mxY[i]+=g_mxSpeed[i];
      if(g_mxY[i]>ch+40){g_mxY[i]=-20-MathRand()%60;g_mxX[i]=MathRand()%cw;g_mxSymbols[i]=syms[MathRand()%14];g_mxSpeed[i]=1+MathRand()%5;}
      if(MathRand()%8==0)g_mxSymbols[i]=syms[MathRand()%14];
      string nm="mx_"+IntegerToString(i);
      ObjectSetInteger(0,nm,OBJPROP_XDISTANCE,g_mxX[i]);ObjectSetInteger(0,nm,OBJPROP_YDISTANCE,g_mxY[i]);ObjectSetString(0,nm,OBJPROP_TEXT,g_mxSymbols[i]);
   }
   ChartRedraw(0);
}

void ClearMatrix()
{
   for(int i=0;i<MATRIX_COUNT;i++)ObjectDelete(0,"mx_"+IntegerToString(i));
   ObjectDelete(0,"mx_topb");ObjectDelete(0,"mx_midb");ObjectDelete(0,"mx_botb");ObjectDelete(0,"mx_alpha");ObjectDelete(0,"mx_session");
   g_matrixInit=false;
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,C'15,15,15');ChartSetInteger(0,CHART_COLOR_FOREGROUND,C'80,80,80');ChartSetInteger(0,CHART_COLOR_GRID,C'50,50,50');
}

#endif // _TERMINAL_UI_
