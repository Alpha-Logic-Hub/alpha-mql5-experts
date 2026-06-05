//+------------------------------------------------------------------+
//|                                            UI/BayesianUI.mqh       |
//|        PrecisionSniper — Glassmorphism Dashboard (CCanvas)         |
//+------------------------------------------------------------------+
#ifndef _BAYESIAN_UI_
#define _BAYESIAN_UI_

#include <Canvas/Canvas.mqh>

// ── Colors (ARGB) — Terminal Hacker Green-on-Black ─────────────────
#define BAY_BG       ColorToARGB(C'4,10,6', 238)
#define BAY_BORDER   ColorToARGB(C'0,140,50', 180)
#define BAY_ACCENT   ColorToARGB(C'0,255,65', 255)
#define BAY_GREEN    ColorToARGB(C'0,230,80', 255)
#define BAY_RED      ColorToARGB(C'255,55,55', 255)
#define BAY_AMBER    ColorToARGB(C'255,200,40', 255)
#define BAY_WHITE    ColorToARGB(C'200,255,200', 255)
#define BAY_GRAY     ColorToARGB(C'100,160,110', 200)
#define BAY_DIM      ColorToARGB(C'60,110,70', 180)
#define BAY_DARK     ColorToARGB(C'2,6,3', 245)
#define BAY_HEADERBG ColorToARGB(C'0,80,30', 50)
#define BAY_GLOW     ColorToARGB(C'0,255,65', 20)

#define BW 360
#define BH 580
#define BX 10
#define BY 10

// ── Tab state ───────────────────────────────────────────────────────
int g_bayTab = 0;  // 0=TRADES, 1=ESTRATEGIA, 2=SMC, 3=STATS

// ── Button zones ────────────────────────────────────────────────────
#define BTN_TAB0_X1 10
#define BTN_TAB0_Y1 54
#define BTN_TAB0_X2 96
#define BTN_TAB0_Y2 82

#define BTN_TAB1_X1 104
#define BTN_TAB1_Y1 54
#define BTN_TAB1_X2 190
#define BTN_TAB1_Y2 82

#define BTN_TAB2_X1 198
#define BTN_TAB2_Y1 54
#define BTN_TAB2_X2 284
#define BTN_TAB2_Y2 82

#define BTN_TAB3_X1 292
#define BTN_TAB3_Y1 54
#define BTN_TAB3_X2 BW-6
#define BTN_TAB3_Y2 82

#define BTN_CLOSE_X1 10
#define BTN_CLOSE_Y1 BH-54
#define BTN_CLOSE_X2 105
#define BTN_CLOSE_Y2 BH-28

#define BTN_STOP_X1 115
#define BTN_STOP_Y1 BH-54
#define BTN_STOP_X2 210
#define BTN_STOP_Y2 BH-28

#define BTN_RESET_X1 220
#define BTN_RESET_Y1 BH-54
#define BTN_RESET_X2 BW-10
#define BTN_RESET_Y2 BH-28

// ── Dashboard state ─────────────────────────────────────────────────
double g_bayScore      = 0;
double g_bayConfidence = 0;
string g_bayBias       = "NEUTRAL";
string g_baySession    = "ASIA";
int    g_bayTradesToday = 0;
double g_bayWinRate    = 0;
double g_bayPf         = 0;
double g_bayTotalR     = 0;
double g_bayEMA9       = 0;
double g_bayEMA21      = 0;
double g_bayEMA55      = 0;
double g_baySpread     = 0;
double g_bayATR        = 0;
int    g_bayBars       = 0;
string g_bayStatus     = "VIGILANDO...";
string g_bayPending    = "";
bool   g_bayVisible    = true;
int    g_bayConfCount  = 0;
string g_bayConfDots   = "";

CCanvas   g_canvas;
bool      g_canvasCreated = false;

//+------------------------------------------------------------------+
//| InitCanvas                                                        |
//+------------------------------------------------------------------+
void InitCanvas()
{
   if(g_canvasCreated) return;
   string objName = "bay_canvas";
   g_canvas.CreateBitmapLabel(0, 0, objName, BX, BY, BW, BH, COLOR_FORMAT_ARGB_NORMALIZE);
   g_canvas.Erase(ColorToARGB(clrBlack, 0));
   g_canvas.Update();
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTED, true);
   g_canvasCreated = true;
}

//+------------------------------------------------------------------+
//| UpdateDashboard — redraw the glass panel                           |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!g_bayVisible) { if(g_canvasCreated) { ObjectDelete(0, "bay_canvas"); g_canvasCreated = false; } return; }
   if(!g_canvasCreated) InitCanvas();

   // ── Compute score based on current state ────────────────────────
   double biasScore = 0;
   int fb = GetFullBias();
   if(fb != 0) biasScore = 30;
   double emaScore = 0;
   if(g_bayEMA9 > g_bayEMA21) emaScore = 20; else if(g_bayEMA9 < g_bayEMA21) emaScore = 10;
   double zoneScore = 0;
   int fC=0, oC=0;
   for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled) fC++;
   for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated) oC++;
   zoneScore = MathMin(30, (fC+oC)*5.0);
   double liqScore = (g_liquiditySweepUp||g_liquiditySweepDn) ? 20 : 0;
   g_bayScore = MathMin(100, biasScore + emaScore + zoneScore + liqScore);
   g_bayConfidence = MathMin(100, g_bayScore * 0.8);
   g_bayBias = (fb==1)?"ALCISTA":(fb==-1)?"BAJISTA":"NEUTRAL";
   g_baySession = GetCurrentSession();
   g_bayTradesToday = g_statTotal;
   g_bayWinRate = g_statTotal>0 ? (double)g_statWins/g_statTotal*100 : 0;
   g_bayPf = g_statLossR>0 ? g_statWinR/g_statLossR : (g_statWinR>0 ? 99 : 0);
   g_bayTotalR = g_statTotalR;

   g_canvas.Erase(ColorToARGB(C'4,8,6', 0));
   g_canvas.FillRectangle(0, 0, BW, BH, BAY_BG);
   g_canvas.Rectangle(0, 0, BW-1, BH-1, BAY_BORDER);
   g_canvas.Rectangle(1, 1, BW-2, BH-2, BAY_BORDER);

   // ── Header ──────────────────────────────────────────────────────
   g_canvas.FillRectangle(0, 0, BW, 50, BAY_HEADERBG);
   g_canvas.FontSet("Segoe UI", 18, FW_BOLD);
   g_canvas.TextOut(14, 12, "SNIPER", BAY_ACCENT);
   g_canvas.FontSet("Segoe UI", 13);
   string ts = TimeToString(TimeCurrent(), TIME_MINUTES|TIME_SECONDS);
   g_canvas.TextOut(BW-100, 16, ts, BAY_DIM);
   g_canvas.LineHorizontal(0, BW-1, 50, BAY_BORDER);

   // ── Tab buttons ─────────────────────────────────────────────────
   string tabs[4] = {"TRADES", "ESTRATEGIA", "SMC", "STATS"};
   int tabX[4] = {BTN_TAB0_X1, BTN_TAB1_X1, BTN_TAB2_X1, BTN_TAB3_X1};
   int tabW[4] = {BTN_TAB0_X2-BTN_TAB0_X1, BTN_TAB1_X2-BTN_TAB1_X1, BTN_TAB2_X2-BTN_TAB2_X1, BTN_TAB3_X2-BTN_TAB3_X1};
   int ty = 54;

   for(int t=0; t<4; t++)
   {
      color bg = (t==g_bayTab) ? ColorToARGB(C'0,100,40',180) : ColorToARGB(C'0,25,10',140);
      color tc = (t==g_bayTab) ? BAY_ACCENT : BAY_DIM;
      g_canvas.FillRectangle(tabX[t], ty, tabX[t]+tabW[t], ty+28, bg);
      g_canvas.Rectangle(tabX[t], ty, tabX[t]+tabW[t], ty+28, BAY_BORDER);
      g_canvas.FontSet("Segoe UI", 12, (t==g_bayTab)?FW_BOLD:FW_NORMAL);
      g_canvas.TextOut(tabX[t]+8, ty+6, tabs[t], tc);
   }
   g_canvas.LineHorizontal(0, BW-1, ty+28, BAY_BORDER);

   // ── Tab content ─────────────────────────────────────────────────
   int y = 96;
   
   if(g_bayTab == 0) // TRADES
   {
      int activeCnt = GetActiveCount();
      if(activeCnt > 0)
      {
         g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
         g_canvas.TextOut(14, y, "POSICIONES ACTIVAS", BAY_ACCENT);
         y += 30;
         for(int si=0; si<MAX_STRATEGIES; si++)
         {
            if(!g_strat[si].active) continue;
            StrategyPos p = g_strat[si];
            double cur = (p.direction==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double pips = (p.direction==1)?(cur-p.entry)/_Point:(p.entry-cur)/_Point;
            double rMult = (p.risk>0)?MathAbs(cur-p.entry)/p.risk:0;
            if(p.direction==-1) rMult=(p.risk>0)?MathAbs(p.entry-cur)/p.risk:0;
            
            g_canvas.FontSet("Segoe UI", 14);
            g_canvas.TextOut(14, y, g_stratNames[si], BAY_GRAY);
            g_canvas.FontSet("Segoe UI", 15, FW_BOLD);
            color pc = (p.direction==1)?BAY_GREEN:BAY_RED;
            g_canvas.TextOut(90, y, (p.direction==1?"LONG":"SHORT"), pc);
            y += 26;
            g_canvas.FontSet("Segoe UI", 13);
            g_canvas.TextOut(30, y, StringFormat("E:%.5f | SL:%.5f | %+.0fpts %.1fR",
                       p.entry, p.sl, pips, rMult), pips>=0?BAY_GREEN:BAY_RED);
            y += 26;
            string tpInfo = StringFormat("TP:%.5f", p.tp1);
            if(p.tp1h) tpInfo += " [HIT]";
            g_canvas.TextOut(30, y, tpInfo, p.tp1h?BAY_GREEN:BAY_DIM);
            y += 32;
         }
      }
      else
      {
         g_canvas.FontSet("Segoe UI", 17, FW_BOLD);
         g_canvas.TextOut(14, y, g_bayStatus, BAY_GRAY);
         y += 36;
         if(g_bayPending != "")
         {
            g_canvas.FontSet("Segoe UI", 15);
            g_canvas.TextOut(14, y, "ZONA: "+g_bayPending, BAY_AMBER);
            y += 30;
         }
         g_canvas.FontSet("Segoe UI", 15);
         g_canvas.TextOut(14, y, "SESGO: "+(g_bayBias=="ALCISTA"?"▲":"▼")+" "+g_bayBias,
                          (g_bayBias=="ALCISTA")?BAY_GREEN:(g_bayBias=="BAJISTA")?BAY_RED:BAY_AMBER);
         y += 30;
         g_canvas.TextOut(14, y, "SESION: "+g_baySession, BAY_DIM);
      }
   }
   else if(g_bayTab == 1) // ESTRATEGIA
   {
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      g_canvas.TextOut(14, y, "CONFIGURACION", BAY_ACCENT);
      y += 32;
      
      g_canvas.FontSet("Segoe UI", 15);
      g_canvas.TextOut(14, y, "EMA 9:  "+DoubleToString(g_bayEMA9,5), (g_bayEMA9>g_bayEMA21)?BAY_GREEN:BAY_RED);
      y += 28;
      g_canvas.TextOut(14, y, "EMA 21: "+DoubleToString(g_bayEMA21,5), (g_bayEMA21>g_bayEMA9)?BAY_GREEN:BAY_RED);
      y += 28;
      g_canvas.TextOut(14, y, "EMA 55: "+DoubleToString(g_bayEMA55,5), BAY_DIM);
      y += 32;
      
      g_canvas.TextOut(14, y, "SPREAD: "+DoubleToString(g_baySpread,1)+" pts", (g_baySpread>50)?BAY_RED:BAY_DIM);
      y += 28;
      g_canvas.TextOut(14, y, "ATR:    "+DoubleToString(g_bayATR,5), BAY_DIM);
      y += 28;
      g_canvas.TextOut(14, y, "BARRAS: "+IntegerToString(g_bayBars), BAY_DIM);
      y += 32;
      
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      g_canvas.TextOut(14, y, "PUNTUACION: "+DoubleToString(g_bayScore,0)+"/100", BAY_ACCENT);
      y += 26;
      int barW = (int)((g_bayScore/100.0)*(BW-28));
      g_canvas.FillRectangle(14, y, 14+barW, y+18, g_bayScore>60?BAY_GREEN:g_bayScore>30?BAY_AMBER:BAY_RED);
      g_canvas.Rectangle(14, y, BW-14, y+18, BAY_DIM);
      y += 30;
      
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      g_canvas.TextOut(14, y, "CONFIANZA: "+DoubleToString(g_bayConfidence,0)+"%", BAY_ACCENT);
      y += 26;
      int cBarW = (int)((g_bayConfidence/100.0)*(BW-28));
      g_canvas.FillRectangle(14, y, 14+cBarW, y+18, BAY_ACCENT);
      g_canvas.Rectangle(14, y, BW-14, y+18, BAY_DIM);
      y += 28;

      // ── Live confirmation counter ────────────────────────────────
      g_canvas.FontSet("Segoe UI", 15, FW_BOLD);
      g_canvas.TextOut(14, y, StringFormat("CONFIRMACIONES: %d/5", g_bayConfCount),
                        g_bayConfCount>=SMC_MinConf?BAY_GREEN:BAY_AMBER);
      y += 24;
      g_canvas.FontSet("Segoe UI", 22);
      g_canvas.TextOut(14, y, g_bayConfDots, BAY_GRAY);
      y += 30;
      string labels = "TND    EST    FVG    LIQ     OB";
      g_canvas.FontSet("Segoe UI", 12);
      g_canvas.TextOut(14, y, labels, BAY_DIM);
   }
   else if(g_bayTab == 2) // SMC
   {
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      g_canvas.TextOut(14, y, "SMART MONEY", BAY_ACCENT);
      y += 32;
      
      int fC=0, oC=0;
      for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled) fC++;
      for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated) oC++;
      
      g_canvas.FontSet("Segoe UI", 15);
      g_canvas.TextOut(14, y, "FVG: "+IntegerToString(fC)+" activos", fC>0?BAY_GREEN:BAY_DIM);
      y += 28;
      g_canvas.TextOut(14, y, "OB:  "+IntegerToString(oC)+" activos", oC>0?BAY_GREEN:BAY_DIM);
      y += 28;
      
      string bosStr = (g_bosUp?"BOS ▲":g_bosDn?"BOS ▼":"sin BOS");
      color bosC = g_bosUp?BAY_GREEN:g_bosDn?BAY_RED:BAY_DIM;
      g_canvas.TextOut(14, y, "BOS: "+bosStr, bosC);
      y += 28;
      
      string liqStr = (g_liquiditySweepUp?"SWEEP ▲":g_liquiditySweepDn?"SWEEP ▼":"sin sweep");
      color liqC = (g_liquiditySweepUp||g_liquiditySweepDn)?BAY_AMBER:BAY_DIM;
      g_canvas.TextOut(14, y, "LIQ: "+liqStr, liqC);
      y += 28;
      
      string chStr = (g_chochUp?"CHoCH ▲":g_chochDn?"CHoCH ▼":"sin CHoCH");
      color chC = g_chochUp?BAY_GREEN:g_chochDn?BAY_RED:BAY_DIM;
      g_canvas.TextOut(14, y, "CHoCH: "+chStr, chC);
      y += 28;
      
      g_canvas.TextOut(14, y, "FIB OTE: "+(g_fibOTE_Valid?"ACTIVO":"inactivo"), g_fibOTE_Valid?BAY_AMBER:BAY_DIM);
      y += 32;
      
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      int bias = GetFullBias();
      string bStr = (bias==1)?"ALCISTA":(bias==-1)?"BAJISTA":"NEUTRAL";
      g_canvas.TextOut(14, y, "BIAS: "+bStr, bias==1?BAY_GREEN:bias==-1?BAY_RED:BAY_AMBER);
   }
   else // STATS
   {
      g_canvas.FontSet("Segoe UI", 16, FW_BOLD);
      g_canvas.TextOut(14, y, "ESTADISTICAS", BAY_ACCENT);
      y += 32;
      
      if(g_statTotal > 0)
      {
         double wr = (double)g_statWins/g_statTotal*100;
         double pf = g_statLossR>0?g_statWinR/g_statLossR:(g_statWinR>0?99:0);
         
         g_canvas.FontSet("Segoe UI", 17, FW_BOLD);
         g_canvas.TextOut(14, y, StringFormat("%d/%d trades", g_statWins, g_statTotal), BAY_WHITE);
         y += 30;
         g_canvas.FontSet("Segoe UI", 15);
         g_canvas.TextOut(14, y, StringFormat("Acierto: %.0f%%", wr), wr>50?BAY_GREEN:wr>40?BAY_AMBER:BAY_RED);
         y += 28;
         g_canvas.TextOut(14, y, StringFormat("Profit Factor: %.2f", pf), pf>1.3?BAY_GREEN:pf>1.0?BAY_AMBER:BAY_RED);
         y += 28;
         g_canvas.TextOut(14, y, StringFormat("Total R: %.1f", g_statTotalR), g_statTotalR>0?BAY_GREEN:BAY_RED);
         y += 28;
         g_canvas.TextOut(14, y, StringFormat("Mejor R: %.1f | Peor R: %.1f", g_statBestR, g_statWorstR<-998?0:g_statWorstR), BAY_DIM);
         y += 28;
         g_canvas.TextOut(14, y, StringFormat("Max DD: %.1f%%", g_statMaxDDpct), g_statMaxDDpct>10?BAY_RED:BAY_DIM);
      }
      else
      {
         g_canvas.FontSet("Segoe UI", 17);
         g_canvas.TextOut(14, y, "Sin trades aun", BAY_DIM);
      }
   }

   // ── Bottom buttons (global, all tabs) ───────────────────────────
   int btnY = BH-58, btnH=30;
   g_canvas.LineHorizontal(0, BW-1, btnY-2, BAY_BORDER);

   g_canvas.FillRectangle(BTN_CLOSE_X1, btnY, BTN_CLOSE_X2, btnY+btnH, ColorToARGB(C'80,15,15',220));
   g_canvas.Rectangle(BTN_CLOSE_X1, btnY, BTN_CLOSE_X2, btnY+btnH, BAY_RED);
   g_canvas.FontSet("Segoe UI", 14, FW_BOLD);
   g_canvas.TextOut(BTN_CLOSE_X1+8, btnY+5, "CERRAR TODO", BAY_WHITE);

   g_canvas.FillRectangle(BTN_STOP_X1, btnY, BTN_STOP_X2, btnY+btnH, ColorToARGB(C'60,40,8',220));
   g_canvas.Rectangle(BTN_STOP_X1, btnY, BTN_STOP_X2, btnY+btnH, BAY_AMBER);
   g_canvas.FontSet("Segoe UI", 14, FW_BOLD);
   g_canvas.TextOut(BTN_STOP_X1+28, btnY+5, "DETENER", BAY_WHITE);

   g_canvas.FillRectangle(BTN_RESET_X1, btnY, BTN_RESET_X2, btnY+btnH, ColorToARGB(C'10,50,15',220));
   g_canvas.Rectangle(BTN_RESET_X1, btnY, BTN_RESET_X2, btnY+btnH, BAY_ACCENT);
   g_canvas.FontSet("Segoe UI", 14, FW_BOLD);
   g_canvas.TextOut(BTN_RESET_X1+14, btnY+5, "REINICIAR", BAY_WHITE);

   g_canvas.Update();
}

//+------------------------------------------------------------------+
//| SyncBayState — pull data from globals into dashboard state         |
//+------------------------------------------------------------------+
void SyncBayState()
{
   double ef[],es[],et[],atr[];
   ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);ArraySetAsSeries(et,true);ArraySetAsSeries(atr,true);
   CopyBuffer(hEmaFast,0,0,1,ef);CopyBuffer(hEmaSlow,0,0,1,es);CopyBuffer(hEmaTrend,0,0,1,et);CopyBuffer(hATR,0,0,1,atr);
   g_bayEMA9=ef[0]; g_bayEMA21=es[0]; g_bayEMA55=et[0]; g_bayATR=atr[0];
   g_baySpread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   g_bayBars=iBars(_Symbol,_Period);

   if(g_smcPendingDir != 0)
      g_bayStatus = (g_smcPendingDir==1)?"ESPERANDO COMPRA":"ESPERANDO VENTA";
   else if(GetActiveCount()>0)
      g_bayStatus = "EN POSICION";
   else
   {
      int fC=0,oC=0;
      for(int i=0;i<ArraySize(g_fvgs);i++)if(!g_fvgs[i].filled)fC++;
      for(int i=0;i<ArraySize(g_obs);i++)if(!g_obs[i].mitigated)oC++;
      if(fC+oC>0) g_bayStatus="VIGILANDO...";
      else g_bayStatus="ESPERANDO ESTRUCTURA";
   }

   // ── Live conf count ─────────────────────────────────────────────
   MqlRates pv[1]; CopyRates(_Symbol,_Period,1,1,pv);
   double etV=0; { double etB[1]; ArraySetAsSeries(etB,true); if(CopyBuffer(hEmaTrend,0,0,1,etB)>0) etV=etB[0]; }
   g_bayConfCount = 0;
   string dots = "";
   // 1. Trend aligned
   if(pv[0].close > etV) { g_bayConfCount++; dots += "●"; } else dots += "○";
   // 2. Structure
   if(g_bosUp || g_bosDn || g_chochUp || g_chochDn) { g_bayConfCount++; dots += " ●"; } else dots += " ○";
   // 3. FVG active
   { bool f=false; for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled){f=true;break;} if(f){g_bayConfCount++;dots+=" ●";}else dots+=" ○"; }
   // 4. Liq sweep
   if(g_liquiditySweepUp||g_liquiditySweepDn) { g_bayConfCount++; dots += " ●"; } else dots += " ○";
   // 5. OB active
   { bool o=false; for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated){o=true;break;} if(o){g_bayConfCount++;dots+=" ●";}else dots+=" ○"; }
   g_bayConfDots = dots;
}

void ClearBayesian() { ObjectDelete(0, "bay_canvas"); g_canvasCreated=false; }

#endif // _BAYESIAN_UI_
