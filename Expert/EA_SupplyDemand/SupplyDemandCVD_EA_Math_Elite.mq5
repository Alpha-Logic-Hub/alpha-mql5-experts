//+------------------------------------------------------------------+
//|                                     SupplyDemandCVD_EA_Elite.mq5 |
//|                                    Developed by Antigravity AI   |
//|                                    Strategy: S&D + CVD Flow      |
//+------------------------------------------------------------------+
#property copyright "Antigravity AI - Fabio Valentini"
#property link      "https://github.com/Antigravity-Elite"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

input group "=== SUPPORT / RESISTANCE OPERATOR ==="
input bool InpUseSupportResistance = true;
input int  InpSRLookback        = 100;
input double InpSRThreshold     = 0.0005;
static double supportLevels[];
static double resistanceLevels[];

input group "=== GESTION DE RIESGO ==="
input double   InpRiskPercent     = 0.15;
input double   InpMaxLot          = 0.05;
input int      InpMagicNumber     = 888123;
input int      InpStopLoss        = 200;
input double   InpRR              = 2.5;

input group "=== LUXALGO SMC & PIVOTS ==="
input int      InpPivotLength     = 3;
input int      InpMaxActiveZones  = 10;
input int      InpATRLen          = 14;
input int      InpTrendEMA        = 200;

input group "=== FILTRO DE CONSOLIDACION ==="
input bool     InpUseConsolidation= false;
input int      InpConsLength      = 10;
input double   InpAtrMult         = 3.0;

input group "=== FILTRO DE COOLDOWN ==="
input bool     InpUseCooldown     = true;
input int      InpCooldownBars    = 1;

input group "=== FILTROS DE CONFIRMACION ==="
input bool     InpUseCVDFilter    = false;
input bool     InpCloseOnOpposite = false;
input bool     InpUseTrailingStop   = true;
input double   InpTrailingTriggerUSD = 0.50;
input double   InpTrailATRMult     = 0.5;
input double   InpTrailingDistance = 10;
input bool     InpUseTrendFilter = false;

input group "=== FILTROS MATEMATICOS ALGEBRAICOS ==="
input bool     InpUseMathTrend    = true;
input int      InpMathPeriod      = 20;
input double   InpMathMinR2       = 0.20;
input bool     InpUseMathAngle    = true;
input double   InpMinAngleDeg     = 8.0;

input group "=== IMPULSO INSTITUCIONAL CAZA-TIBURONES ==="
input bool     InpUseMomentumBreakout = true;
input double   InpVolSpikeMultiplier = 2.0;
input double   InpMinAtrAcceleration = 1.0;

input group "=== VOLUME PROFILE INJECTION ==="
input bool     InpUseVolumeProfile      = true;
input int      InpVpLookback            = 20;
input int      InpVpRows                = 24;
input double   InpVpPercent             = 70.0;
input double   InpVpVolMultiplier       = 2.0;
input double   InpVpMinAtrAccel         = 1.0;

input group "=== GESTION DE SALIDAS PARCIALES Y BE ==="
input bool     InpUsePartialClose = true;
input double   InpPartialRatio    = 0.5;
input double   InpPartialTriggerRR= 1.5;
input bool     InpUseBreakEven    = true;
input double   InpBeOffsetPoints  = 10;
 
input group "=== OTE FIBONACCI (LuxAlgo Style) ==="
input bool     InpUseOTE          = true;
input double   InpFib30           = 0.3;
input double   InpFib50           = 0.5;
input double   InpFib70           = 0.7;
input bool     InpShowFibLines    = true;

input group "=== PERFILES DE RIESGO ==="
input int      InpRiskProfile        = 1;
input double   InpFixedLot           = 0.02;

input group "=== SHIELD DIARIO ==="
input bool     InpUseShield          = true;
input double   InpShieldPercent      = 4.0;

input group "=== FILTROS RSI Y SESION ==="
input int      InpRSIPeriod          = 14;
input double   InpRSIOverbought      = 70.0;
input double   InpRSIOversold        = 30.0;

input group "=== ESTETICA Y HUD ==="
input color    InpDemandColor     = clrMediumSpringGreen;
input color    InpSupplyColor     = clrTomato;
input bool     InpShowHUD         = true;

struct Zone { double top; double bottom; datetime startTime; double initialCVD; bool active; bool traded; string objName; };
Zone demandZones[];
Zone supplyZones[];

double   effRiskPercent; double effRR; double effShieldPercent;
datetime lastShieldResetDay = 0; double startOfDayEquity = 0; double dailyPL = 0;
int h_rsi, h_atr, h_ema; CTrade trade; CPositionInfo pos;
int dynATRLen, dynTrendEMA; double trailingDistPoints;
double max_equity_peak = 0;
double cachedCVD = 0; datetime lastCVDBarTime = 0;
double lastPivotHigh = 0; double lastPivotLow = 0;
datetime lastTradeTime = 0; datetime lastBarTime = 0;
double vah = 0; double val = 0; double poc = 0; double vpAvgVol = 0;

void ApplyChartColors() { ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrDarkSlateGray); ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrLime); ChartSetInteger(0,CHART_COLOR_GRID,C'15,30,45'); ChartSetInteger(0,CHART_COLOR_CHART_UP,clrGreen); ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrRed); ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrWhite); ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrGray); ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrLime); ChartSetInteger(0,CHART_COLOR_VOLUME,clrLimeGreen); ChartSetInteger(0,CHART_COLOR_BID,clrLime); ChartSetInteger(0,CHART_COLOR_ASK,clrRed); ChartSetInteger(0,CHART_COLOR_LAST,clrBlack); ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,clrRed); ChartRedraw(0); }

int OnInit() {
   ApplyChartColors(); SetDynamicParameters();
   h_atr = iATR(_Symbol,_Period,dynATRLen); if(h_atr==INVALID_HANDLE) return INIT_FAILED;
   h_ema = iMA(_Symbol,_Period,dynTrendEMA,0,MODE_EMA,PRICE_CLOSE); if(h_ema==INVALID_HANDLE) return INIT_FAILED;
   h_rsi = iRSI(_Symbol,_Period,InpRSIPeriod,PRICE_CLOSE); if(h_rsi==INVALID_HANDLE) return INIT_FAILED;
   ApplyRiskProfile(); ResetDailyShield();
   ArrayResize(demandZones,0); ArrayResize(supplyZones,0);
   trade.SetExpertMagicNumber(InpMagicNumber); max_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
   ScanHistory(300); DrawHUD(); ChartRedraw(0);
   return INIT_SUCCEEDED;
}

void SetDynamicParameters() {
   switch(_Period) {
      case PERIOD_M1: dynATRLen=10; dynTrendEMA=100; trailingDistPoints=5; break;
      case PERIOD_M5: dynATRLen=14; dynTrendEMA=150; trailingDistPoints=10; break;
      case PERIOD_M15: dynATRLen=14; dynTrendEMA=200; trailingDistPoints=15; break;
      default: dynATRLen=InpATRLen; dynTrendEMA=InpTrendEMA; trailingDistPoints=InpTrailingDistance;
   }
}

bool IsPivotHigh(int bar, int length) {
   if(bar<length||bar+length>=iBars(_Symbol,_Period)) return false;
   double h=iHigh(_Symbol,_Period,bar);
   for(int i=1;i<=length;i++) { if(iHigh(_Symbol,_Period,bar+i)>h) return false; if(iHigh(_Symbol,_Period,bar-i)>=h) return false; }
   return true;
}
bool IsPivotLow(int bar, int length) {
   if(bar<length||bar+length>=iBars(_Symbol,_Period)) return false;
   double l=iLow(_Symbol,_Period,bar);
   for(int i=1;i<=length;i++) { if(iLow(_Symbol,_Period,bar+i)<l) return false; if(iLow(_Symbol,_Period,bar-i)<=l) return false; }
   return true;
}

void ApplyRiskProfile() {
   switch(InpRiskProfile) {
      case 0: effRiskPercent=InpRiskPercent*0.5; effRR=1.5; effShieldPercent=3.0; break;
      case 1: effRiskPercent=InpRiskPercent; effRR=1.33; effShieldPercent=4.0; break;
      case 2: effRiskPercent=InpRiskPercent*1.5; effRR=1.2; effShieldPercent=6.0; break;
      default: effRiskPercent=InpRiskPercent; effRR=InpRR; effShieldPercent=InpShieldPercent;
   }
}

double GetEAPnL() {
   double pnl=0;
   for(int i=PositionsTotal()-1;i>=0;i--) { if(pos.SelectByIndex(i)&&pos.Magic()==InpMagicNumber&&pos.Symbol()==_Symbol) pnl+=pos.Profit()+pos.Swap()+pos.Commission(); }
   HistorySelect(TimeCurrent()-86400,TimeCurrent());
   for(int i=0;i<HistoryDealsTotal();i++) {
      ulong t=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t,DEAL_MAGIC)!=InpMagicNumber) continue;
      if(HistoryDealGetString(t,DEAL_SYMBOL)!=_Symbol) continue;
      if(HistoryDealGetInteger(t,DEAL_ENTRY)==DEAL_ENTRY_OUT) pnl+=HistoryDealGetDouble(t,DEAL_PROFIT);
   }
   return pnl;
}

void ResetDailyShield() { MqlDateTime dt; TimeCurrent(dt); lastShieldResetDay=StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",dt.year,dt.mon,dt.day)); startOfDayEquity=AccountInfoDouble(ACCOUNT_EQUITY); dailyPL=GetEAPnL(); }
void UpdateDailyShield() { MqlDateTime dt; TimeCurrent(dt); datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00:00",dt.year,dt.mon,dt.day)); if(today!=lastShieldResetDay){ lastShieldResetDay=today; startOfDayEquity=AccountInfoDouble(ACCOUNT_EQUITY); dailyPL=0; } else { dailyPL=GetEAPnL(); } }
bool IsShieldTriggered() { if(!InpUseShield) return false; double maxLoss=startOfDayEquity*(effShieldPercent/100.0); return (dailyPL<=-maxLoss); }

double CalculateRSI(int period) {
   if(iBars(_Symbol,_Period)<period+2) return 50.0;
   double gain=0,loss=0;
   for(int i=1;i<=period;i++) { double diff=iClose(_Symbol,_Period,i-1)-iClose(_Symbol,_Period,i); if(diff>0) gain+=diff; else loss-=diff; }
   if(loss==0) return 100.0;
   return 100.0-(100.0/(1.0+gain/loss));
}

enum ENUM_MARKET_SESSION { SESSION_ASIA, SESSION_LONDON, SESSION_NY, SESSION_OFF };
ENUM_MARKET_SESSION GetMarketSession() { MqlDateTime dt; TimeGMT(dt); int h=dt.hour; if(h>=13&&h<22) return SESSION_NY; if(h>=7&&h<14) return SESSION_LONDON; if(h>=0&&h<8) return SESSION_ASIA; return SESSION_OFF; }

int CountActivePositions() { int c=0; for(int i=PositionsTotal()-1;i>=0;i--) { if(pos.SelectByIndex(i)&&pos.Magic()==InpMagicNumber&&pos.Symbol()==_Symbol) c++; } return c; }

double GetMinStopDist() { int sl=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL); double usl=(InpStopLoss>0)?InpStopLoss*_Point:200*_Point; double atr[1],asl=0; if(CopyBuffer(h_atr,0,0,1,atr)>0) asl=atr[0]*0.5; return MathMax(MathMax(usl,asl),(sl+10)*_Point); }

double CalculateLot(double slPts) {
   if(InpFixedLot>0) { double s=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); double f=MathRound(InpFixedLot/s)*s; return MathMax(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),MathMin(InpMaxLot,f)); }
   double risk=AccountInfoDouble(ACCOUNT_EQUITY)*(effRiskPercent/100.0);
   double lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(slPts>0) { double pr=0,px=SymbolInfoDouble(_Symbol,SYMBOL_ASK); if(OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,px,px-slPts,pr)) { double al=MathAbs(pr); if(al>0) lot=risk/al; } else { double tv=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE); if(tv>0) lot=risk/(slPts/_Point*tv); } }
   double s=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); lot=MathRound(lot/s)*s;
   return MathMax(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),MathMin(InpMaxLot,lot));
}

bool CanTrade(ENUM_ORDER_TYPE type) {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)||!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   double atr[1]; CopyBuffer(h_atr,0,0,1,atr); double sp=SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)*_Point;
   if(atr[0]>0&&sp>(atr[0]*0.3)) { if(!MQLInfoInteger(MQL_TESTER)) Print("Spread alto"); return false; }
   if(IsShieldTriggered()) { if(!MQLInfoInteger(MQL_TESTER)) Print("Shield diario activado"); return false; }
   return true;
}

void OnTick() {
   UpdateDailyShield(); ScanForEntries();
   if(InpUseMomentumBreakout) CheckInstitutionalMomentum();
   if(InpUseVolumeProfile) CheckVolumeProfileInjection();
   ManagePositionExits(); UpdateTrailingStop(); DrawHUD();
   datetime cb=iTime(_Symbol,_Period,0); if(cb==lastBarTime) return; lastBarTime=cb;
   if(InpUseVolumeProfile) CalculateVolumeProfile();
   CheckMitigation(); DetectZones();
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0,"SND_"); if(h_atr!=INVALID_HANDLE) IndicatorRelease(h_atr); if(h_ema!=INVALID_HANDLE) IndicatorRelease(h_ema); }

void ScanForEntries() {
   int cd=9999; if(lastTradeTime>0) cd=iBarShift(_Symbol,_Period,lastTradeTime);
   bool canE=!InpUseCooldown||(lastTradeTime==0)||(cd>=InpCooldownBars); if(!canE) return;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ema[1]; bool useT=InpUseTrendFilter&&(CopyBuffer(h_ema,0,1,1,ema)>0);
   for(int i=0;i<ArraySize(demandZones);i++) { if(demandZones[i].active&&!demandZones[i].traded) { double zr=demandZones[i].top-demandZones[i].bottom; double oh=demandZones[i].bottom+zr*InpFib70,ol=demandZones[i].bottom+zr*InpFib30; bool inZ=(ask<=demandZones[i].top&&ask>=demandZones[i].bottom),inO=(ask<=oh&&ask>=ol); bool trig=InpUseOTE?inO:inZ; if(trig) { if(useT&&ask<ema[0]) continue; if(ExecuteTrade(ORDER_TYPE_BUY,demandZones[i].top,demandZones[i].bottom)) { demandZones[i].traded=true; return; } } } }
   for(int i=0;i<ArraySize(supplyZones);i++) { if(supplyZones[i].active&&!supplyZones[i].traded) { double zr=supplyZones[i].top-supplyZones[i].bottom; double ol2=supplyZones[i].top-zr*InpFib70,oh2=supplyZones[i].top-zr*InpFib30; bool inZ2=(bid>=supplyZones[i].bottom&&bid<=supplyZones[i].top),inO2=(bid>=ol2&&bid<=oh2); bool trig2=InpUseOTE?inO2:inZ2; if(trig2) { if(useT&&bid>ema[0]) continue; if(ExecuteTrade(ORDER_TYPE_SELL,supplyZones[i].top,supplyZones[i].bottom)) { supplyZones[i].traded=true; return; } } } }
   CheckSupportResistance();
}

bool ExecuteTrade(ENUM_ORDER_TYPE type, double top, double bottom) {
   if(!CanTrade(type)) return false;
   if(CountActivePositions()>0&&InpCloseOnOpposite) CloseOpposite(type);
   if(CountActivePositions()>=1) return false;
   double px=(type==ORDER_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double slD=GetMinStopDist(); double sl=(type==ORDER_TYPE_BUY)?px-slD:px+slD;
   double lot=CalculateLot(slD);
   if(trade.PositionOpen(_Symbol,type,lot,px,sl,0,"SMC Mitigacion")) { lastTradeTime=TimeCurrent(); return true; }
   return false;
}

void CloseOpposite(ENUM_ORDER_TYPE nt) { for(int i=PositionsTotal()-1;i>=0;i--) { if(pos.SelectByIndex(i)&&pos.Magic()==InpMagicNumber) { if((pos.PositionType()==POSITION_TYPE_BUY&&nt==ORDER_TYPE_SELL)||(pos.PositionType()==POSITION_TYPE_SELL&&nt==ORDER_TYPE_BUY)) trade.PositionClose(pos.Ticket()); } } }

void ManagePositionExits() {
   if(!InpUsePartialClose&&!InpUseBreakEven) return;
   for(int i=PositionsTotal()-1;i>=0;i--) { CPositionInfo pe; if(pe.SelectByIndex(i)&&pe.Magic()==InpMagicNumber&&pe.Symbol()==_Symbol) { double ep=pe.PriceOpen(),cp=pe.PriceCurrent(),sl=pe.StopLoss(),tp=pe.TakeProfit(),vol=pe.Volume(); ulong t=pe.Ticket(); if(sl==0) continue; double rd=MathAbs(ep-sl); if(rd==0) continue; double cpd=(pe.PositionType()==POSITION_TYPE_BUY)?cp-ep:ep-cp; double crr=cpd/rd; if(crr>=InpPartialTriggerRR) { bool ap=(pe.PositionType()==POSITION_TYPE_BUY)?(sl>=ep-(2*_Point)):(sl<=ep+(2*_Point)); if(!ap) { if(InpUsePartialClose) { double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),minL=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN); double cv=MathMax(MathRound((vol*InpPartialRatio)/step)*step,minL); if(cv<vol) trade.PositionClosePartial(t,cv,10); } if(InpUseBreakEven) { double off=InpBeOffsetPoints*_Point; double nsl=(pe.PositionType()==POSITION_TYPE_BUY)?ep+off:ep-off; trade.PositionModify(t,nsl,tp); } } } } }
}

void UpdateTrailingStop() {
   if(!InpUseTrailingStop) return;
   double atr[1],ap=0; if(CopyBuffer(h_atr,0,0,1,atr)>0&&atr[0]>0) ap=(atr[0]*InpTrailATRMult)/_Point;
   int sl=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL); double md=(double)sl+10.0;
   for(int i=PositionsTotal()-1;i>=0;i--) { CPositionInfo p; if(!p.SelectByIndex(i)||p.Magic()!=InpMagicNumber||p.Symbol()!=_Symbol) continue; double cp=(p.PositionType()==POSITION_TYPE_BUY)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK),sl2=p.StopLoss(),tp2=p.TakeProfit(),pu=p.Profit(); double pr=pu/MathMax(InpTrailingTriggerUSD,0.01); double tm=InpTrailATRMult; if(pr>=8.0) tm=InpTrailATRMult*0.3; else if(pr>=4.0) tm=InpTrailATRMult*0.5; else if(pr>=2.0) tm=InpTrailATRMult*0.7; double dap=(atr[0]*tm)/_Point,fp=MathMax(dap,MathMax(trailingDistPoints,md)),trl=fp*_Point; bool ct=(pu>=InpTrailingTriggerUSD); if(p.PositionType()==POSITION_TYPE_BUY) { if(ct) { double ns=NormalizeDouble(cp-trl,_Digits); double ms=3.0*_Point; if(sl2==0||(ns>sl2&&(ns-sl2>=ms))) trade.PositionModify(p.Ticket(),ns,tp2); } } else { if(ct) { double ns=NormalizeDouble(cp+trl,_Digits); double ms=3.0*_Point; if(sl2==0||(ns<sl2&&(sl2-ns>=ms))) trade.PositionModify(p.Ticket(),ns,tp2); } } }
}

void CalculateLinearRegression(int period, double &slope, double &r2) {
   slope=0; r2=0; int n=period; if(n<=2||iBars(_Symbol,_Period)<n) return;
   double sx=0,sy=0,sxy=0,sx2=0,sy2=0;
   for(int i=0;i<n;i++) { double y=iClose(_Symbol,_Period,i+1),x=n-i; sx+=x; sy+=y; sxy+=x*y; sx2+=x*x; sy2+=y*y; }
   double nm=(n*sxy)-(sx*sy),dn=(n*sx2)-(sx*sx); if(dn!=0) slope=nm/dn;
   double nr=nm,dr=(n*sx2-sx*sx)*(n*sy2-sy*sy); if(dr>0) r2=(nr*nr)/dr;
}

double CalculateSlopeAngle(double sv, double av) { if(av<=0) return 0; double ns=sv/av; return MathArctan(ns)*180.0/M_PI; }

double GetBarVolumeDelta(int shift) { MqlRates r[]; if(CopyRates(_Symbol,_Period,shift,1,r)<=0) return 0; double v=(r[0].real_volume>0)?(double)r[0].real_volume:(double)r[0].tick_volume; if(r[0].close>r[0].open) return v; if(r[0].close<r[0].open) return -v; return 0; }
double GetAverageAbsoluteVolumeDelta(int period) { MqlRates r[]; if(CopyRates(_Symbol,_Period,1,period,r)<=0) return 0; double s=0; for(int i=0;i<period;i++) { double v=(r[i].real_volume>0)?(double)r[i].real_volume:(double)r[i].tick_volume; s+=v; } return s/(double)period; }

void CheckInstitutionalMomentum() {
   if(!InpUseMomentumBreakout||CountActivePositions()>=1) return;
   int cd=9999; if(lastTradeTime>0) cd=iBarShift(_Symbol,_Period,lastTradeTime); if(InpUseCooldown&&lastTradeTime>0&&cd<InpCooldownBars) return;
   if(lastPivotHigh==0||lastPivotLow==0) return;
   double ld=GetBarVolumeDelta(0),av=GetAverageAbsoluteVolumeDelta(14); if(av<=0) return;
   if(MathAbs(ld)<InpVolSpikeMultiplier*av) return;
   double atr[1]; if(CopyBuffer(h_atr,0,0,1,atr)<=0) return;
   double cb=iHigh(_Symbol,_Period,0)-iLow(_Symbol,_Period,0); if(cb<atr[0]*InpMinAtrAcceleration) return;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ld>0&&ask>lastPivotHigh&&iClose(_Symbol,_Period,1)<=lastPivotHigh) { if(!CanTrade(ORDER_TYPE_BUY)) return; double sd=GetMinStopDist(),sl=ask-sd,lot=CalculateLot(sd); if(trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lot,ask,sl,0,"Tiburon COMPRA")) { lastTradeTime=TimeCurrent(); } }
   if(ld<0&&bid<lastPivotLow&&iClose(_Symbol,_Period,1)>=lastPivotLow) { if(!CanTrade(ORDER_TYPE_SELL)) return; double sd=GetMinStopDist(),sl=bid+sd,lot=CalculateLot(sd); if(trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lot,bid,sl,0,"Tiburon VENTA")) { lastTradeTime=TimeCurrent(); } }
}

void CalculateVolumeProfile() {
   int lb=InpVpLookback,b=iBars(_Symbol,_Period); if(b<lb+2) return;
   double hi=-1,lo=DBL_MAX;
   for(int i=1;i<=lb;i++) { double h=iHigh(_Symbol,_Period,i),l=iLow(_Symbol,_Period,i); if(h>hi) hi=h; if(l<lo) lo=l; }
   double rng=hi-lo; if(rng<=0) return;
   double rs=rng/InpVpRows; int rows=(int)InpVpRows;
   double vol[]; ArrayResize(vol,rows); ArrayInitialize(vol,0); double tv=0;
   for(int i=1;i<=lb;i++) { MqlRates rt[]; if(CopyRates(_Symbol,_Period,i,1,rt)<=0) continue; double vb=(rt[0].real_volume>0)?(double)rt[0].real_volume:(double)rt[0].tick_volume; int bn=(int)((rt[0].close-lo)/rs); if(bn<0) bn=0; if(bn>=rows) bn=rows-1; vol[bn]+=vb; tv+=vb; }
   if(tv<=0) return;
   int pb=0; double mv=0; for(int i=0;i<rows;i++) { if(vol[i]>mv) { mv=vol[i]; pb=i; } }
   double tgv=tv*InpVpPercent/100.0,cv=vol[pb]; int vb2=pb,va2=pb,up=pb+1,dn=pb-1;
   while(cv<tgv&&(up<rows||dn>=0)) { if(up<rows&&(dn<0||vol[up]>=vol[dn])) { cv+=vol[up]; vb2=up; up++; } else if(dn>=0) { cv+=vol[dn]; va2=dn; dn--; } else break; }
   vah=lo+(vb2+1)*rs; val=lo+va2*rs; poc=lo+(pb+0.5)*rs;
   double sv=0; for(int i=1;i<=lb;i++) { MqlRates rt2[]; if(CopyRates(_Symbol,_Period,i,1,rt2)<=0) continue; double v2=(rt2[0].real_volume>0)?(double)rt2[0].real_volume:(double)rt2[0].tick_volume; sv+=v2; } vpAvgVol=sv/lb;
}

void CheckVolumeProfileInjection() {
   if(!InpUseVolumeProfile||CountActivePositions()>=1||vah<=0||val<=0) return;
   int cd=9999; if(lastTradeTime>0) cd=iBarShift(_Symbol,_Period,lastTradeTime); if(InpUseCooldown&&lastTradeTime>0&&cd<InpCooldownBars) return;
   MqlRates r0[1]; if(CopyRates(_Symbol,_Period,0,1,r0)<=0) return;
   double cv2=(r0[0].real_volume>0)?(double)r0[0].real_volume:(double)r0[0].tick_volume; if(cv2<vpAvgVol*InpVpVolMultiplier) return;
   double atr[1]; if(CopyBuffer(h_atr,0,0,1,atr)<=0) return;
   double cr=iHigh(_Symbol,_Period,0)-iLow(_Symbol,_Period,0); if(cr<atr[0]*InpVpMinAtrAccel) return;
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ask>vah&&r0[0].close>r0[0].open) { if(!CanTrade(ORDER_TYPE_BUY)) return; double sd=GetMinStopDist(),sl=ask-sd,lot=CalculateLot(sd); if(trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lot,ask,sl,0,"VP Compra")) { lastTradeTime=TimeCurrent(); } }
   if(bid<val&&r0[0].close<r0[0].open) { if(!CanTrade(ORDER_TYPE_SELL)) return; double sd=GetMinStopDist(),sl=bid+sd,lot=CalculateLot(sd); if(trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lot,bid,sl,0,"VP Venta")) { lastTradeTime=TimeCurrent(); } }
}

void ScanHistory(int count) {
   int tb=iBars(_Symbol,_Period); if(tb<=InpPivotLength+5) return; int lm=MathMin(count,tb-InpPivotLength-5);
   lastPivotHigh=0; lastPivotLow=0;
   for(int i=lm;i>=1+InpPivotLength;i--) {
      if(IsPivotHigh(i,InpPivotLength)) lastPivotHigh=iHigh(_Symbol,_Period,i);
      if(IsPivotLow(i,InpPivotLength)) lastPivotLow=iLow(_Symbol,_Period,i);
      if(lastPivotHigh==0||lastPivotLow==0) continue;
      double ci=iClose(_Symbol,_Period,i-InpPivotLength),cp=iClose(_Symbol,_Period,i-InpPivotLength+1);
      if(cp<=lastPivotHigh&&ci>lastPivotHigh) { int lb2=i-InpPivotLength; double ll=iLow(_Symbol,_Period,lb2); for(int j=i-InpPivotLength;j<=i;j++) { double l=iLow(_Symbol,_Period,j); if(l<ll) { ll=l; lb2=j; } } double ot=iHigh(_Symbol,_Period,lb2),ob=iLow(_Symbol,_Period,lb2); if(!IsZoneOverlapping(ob,ot,true)) AddZone(ot,ob,true,iTime(_Symbol,_Period,lb2)); }
      if(cp>=lastPivotLow&&ci<lastPivotLow) { int hb=i-InpPivotLength; double hh=iHigh(_Symbol,_Period,hb); for(int j=i-InpPivotLength;j<=i;j++) { double h=iHigh(_Symbol,_Period,j); if(h>hh) { hh=h; hb=j; } } double ot=iHigh(_Symbol,_Period,hb),ob=iLow(_Symbol,_Period,hb); if(!IsZoneOverlapping(ob,ot,false)) AddZone(ot,ob,false,iTime(_Symbol,_Period,hb)); }
   }
}

void DetectZones() {
   int sh=InpPivotLength; if(IsPivotHigh(sh,InpPivotLength)) lastPivotHigh=iHigh(_Symbol,_Period,sh); if(IsPivotLow(sh,InpPivotLength)) lastPivotLow=iLow(_Symbol,_Period,sh);
   if(lastPivotHigh==0||lastPivotLow==0) return;
   double ph=iHigh(_Symbol,_Period,iHighest(_Symbol,_Period,MODE_HIGH,InpConsLength,1)),pl=iLow(_Symbol,_Period,iLowest(_Symbol,_Period,MODE_LOW,InpConsLength,1)),zr=ph-pl;
   double atr[1]; if(CopyBuffer(h_atr,0,1,1,atr)<1) return;
   bool isC=!InpUseConsolidation||(zr<=(atr[0]*InpAtrMult));
   int cd=9999; if(lastTradeTime>0) cd=iBarShift(_Symbol,_Period,lastTradeTime); bool canE=!InpUseCooldown||(lastTradeTime==0)||(cd>=InpCooldownBars);
   double c0=iClose(_Symbol,_Period,1),c1=iClose(_Symbol,_Period,2);
   if(c1<=lastPivotHigh&&c0>lastPivotHigh&&isC&&canE) { bool mv=true; if(InpUseMathTrend||InpUseMathAngle) { double sp=0,r2=0; double atr2[1]; CopyBuffer(h_atr,0,0,1,atr2); CalculateLinearRegression(5,sp,r2); double ag=CalculateSlopeAngle(sp,atr2[0]); if(InpUseMathTrend&&r2<0.35) mv=false; if(sp<=0) mv=false; if(InpUseMathAngle&&ag<InpMinAngleDeg) mv=false; } if(mv) { int ss=1,se=iBarShift(_Symbol,_Period,iTime(_Symbol,_Period,sh)); if(se<ss) se=ss+5; int lb2=ss; double ll=iLow(_Symbol,_Period,ss); for(int i=ss;i<=se;i++) { double l=iLow(_Symbol,_Period,i); if(l<ll) { ll=l; lb2=i; } } double ot=iHigh(_Symbol,_Period,lb2),ob=iLow(_Symbol,_Period,lb2); if(!IsZoneOverlapping(ob,ot,true)) { AddZone(ot,ob,true,iTime(_Symbol,_Period,lb2)); lastPivotHigh=0; } } }
   if(c1>=lastPivotLow&&c0<lastPivotLow&&isC&&canE) { bool mv=true; if(InpUseMathTrend||InpUseMathAngle) { double sp=0,r2=0; double atr2[1]; CopyBuffer(h_atr,0,0,1,atr2); CalculateLinearRegression(5,sp,r2); double ag=CalculateSlopeAngle(sp,atr2[0]); if(InpUseMathTrend&&r2<0.35) mv=false; if(sp>=0) mv=false; if(InpUseMathAngle&&MathAbs(ag)<InpMinAngleDeg) mv=false; } if(mv) { int ss=1,se=iBarShift(_Symbol,_Period,iTime(_Symbol,_Period,sh)); if(se<ss) se=ss+5; int hb=ss; double hh=iHigh(_Symbol,_Period,ss); for(int i=ss;i<=se;i++) { double h=iHigh(_Symbol,_Period,i); if(h>hh) { hh=h; hb=i; } } double ot=iHigh(_Symbol,_Period,hb),ob=iLow(_Symbol,_Period,hb); if(!IsZoneOverlapping(ob,ot,false)) { AddZone(ot,ob,false,iTime(_Symbol,_Period,hb)); lastPivotLow=0; } } }
}

bool IsZoneOverlapping(double low, double high, bool isD) { double mg=(high-low)*0.1; if(isD) { for(int i=0;i<ArraySize(demandZones);i++) if(demandZones[i].active&&(low-mg)<=demandZones[i].top&&(high+mg)>=demandZones[i].bottom) return true; } else { for(int i=0;i<ArraySize(supplyZones);i++) if(supplyZones[i].active&&(low-mg)<=supplyZones[i].top&&(high+mg)>=supplyZones[i].bottom) return true; } return false; }

void AddZone(double top, double bottom, bool isD, datetime zt) { Zone nz; nz.top=top; nz.bottom=bottom; nz.startTime=zt; nz.active=true; nz.traded=false; nz.objName="SND_"+(isD?"Dem_":"Sup_")+IntegerToString((int)nz.startTime); if(isD) { ArrayResize(demandZones,ArraySize(demandZones)+1); demandZones[ArraySize(demandZones)-1]=nz; DrawBox(nz.objName,nz.startTime,nz.top,nz.bottom,InpDemandColor,"Demand"); DrawFibLevels(nz.objName,nz.startTime,nz.top,nz.bottom,true); } else { ArrayResize(supplyZones,ArraySize(supplyZones)+1); supplyZones[ArraySize(supplyZones)-1]=nz; DrawBox(nz.objName,nz.startTime,nz.top,nz.bottom,InpSupplyColor,"Supply"); DrawFibLevels(nz.objName,nz.startTime,nz.top,nz.bottom,false); } }

void CheckMitigation() { double cl=iClose(_Symbol,_Period,0); datetime nw=TimeCurrent(); for(int i=0;i<ArraySize(demandZones);i++) { if(!demandZones[i].active) continue; ObjectSetInteger(0,demandZones[i].objName,OBJPROP_TIME,1,nw); if(cl<demandZones[i].bottom) { demandZones[i].active=false; ObjectDelete(0,demandZones[i].objName); } } for(int i=0;i<ArraySize(supplyZones);i++) { if(!supplyZones[i].active) continue; ObjectSetInteger(0,supplyZones[i].objName,OBJPROP_TIME,1,nw); if(cl>supplyZones[i].top) { supplyZones[i].active=false; ObjectDelete(0,supplyZones[i].objName); } } }

void DrawBox(string name, datetime st, double top, double bottom, color col, string type) { ObjectCreate(0,name,OBJ_RECTANGLE,0,st,top,TimeCurrent()+(PeriodSeconds()*5),bottom); ObjectSetInteger(0,name,OBJPROP_COLOR,col); ObjectSetInteger(0,name,OBJPROP_FILL,false); ObjectSetInteger(0,name,OBJPROP_BACK,false); ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID); ObjectSetInteger(0,name,OBJPROP_WIDTH,1); }

void DrawFibLevels(string bn, datetime st, double top, double bottom, bool isD) { if(!InpShowFibLines) return; double zr=top-bottom,f30,f50,f70; color cm=isD?InpDemandColor:InpSupplyColor,co=isD?clrAqua:clrGold; datetime t2=TimeCurrent()+(PeriodSeconds()*50); if(isD) { f30=bottom+zr*InpFib30; f50=bottom+zr*InpFib50; f70=bottom+zr*InpFib70; } else { f70=top-zr*InpFib30; f50=top-zr*InpFib50; f30=top-zr*InpFib70; } ObjectCreate(0,bn+"_F30",OBJ_TREND,0,st,f30,t2,f30); ObjectSetInteger(0,bn+"_F30",OBJPROP_COLOR,cm); ObjectSetInteger(0,bn+"_F30",OBJPROP_STYLE,STYLE_DOT); ObjectCreate(0,bn+"_F50",OBJ_TREND,0,st,f50,t2,f50); ObjectSetInteger(0,bn+"_F50",OBJPROP_COLOR,co); ObjectSetInteger(0,bn+"_F50",OBJPROP_STYLE,STYLE_SOLID); ObjectSetInteger(0,bn+"_F50",OBJPROP_WIDTH,2); ObjectCreate(0,bn+"_F70",OBJ_TREND,0,st,f70,t2,f70); ObjectSetInteger(0,bn+"_F70",OBJPROP_COLOR,cm); ObjectSetInteger(0,bn+"_F70",OBJPROP_STYLE,STYLE_DOT); }

void CalculateSupportResistance() { ArrayFree(supportLevels); ArrayFree(resistanceLevels); int lb=InpSRLookback; if(iBars(_Symbol,_Period)<lb+2) return; for(int i=1;i<lb-1;i++) { double pl=iLow(_Symbol,_Period,i+1),cl2=iLow(_Symbol,_Period,i),nl=iLow(_Symbol,_Period,i-1); if(cl2<pl&&cl2<nl) { bool dup=false; for(int k=0;k<ArraySize(supportLevels);k++) if(MathAbs(supportLevels[k]-cl2)<InpSRThreshold) dup=true; if(!dup) { ArrayResize(supportLevels,ArraySize(supportLevels)+1); supportLevels[ArraySize(supportLevels)-1]=cl2; } } double ph=iHigh(_Symbol,_Period,i+1),ch=iHigh(_Symbol,_Period,i),nh=iHigh(_Symbol,_Period,i-1); if(ch>ph&&ch>nh) { bool dup=false; for(int k=0;k<ArraySize(resistanceLevels);k++) if(MathAbs(resistanceLevels[k]-ch)<InpSRThreshold) dup=true; if(!dup) { ArrayResize(resistanceLevels,ArraySize(resistanceLevels)+1); resistanceLevels[ArraySize(resistanceLevels)-1]=ch; } } } }

void CheckSupportResistance() { if(!InpUseSupportResistance) return; double px=SymbolInfoDouble(_Symbol,SYMBOL_ASK),bd=SymbolInfoDouble(_Symbol,SYMBOL_BID); for(int i=0;i<ArraySize(supportLevels);i++) { if(px>=supportLevels[i]) { double ema[1]; if(CopyBuffer(h_ema,0,1,1,ema)<=0) continue; if(px<ema[0]) continue; if(ExecuteTrade(ORDER_TYPE_BUY,supportLevels[i]+_Point,supportLevels[i]-_Point)) return; } } for(int i=0;i<ArraySize(resistanceLevels);i++) { if(bd<=resistanceLevels[i]) { double ema[1]; if(CopyBuffer(h_ema,0,1,1,ema)<=0) continue; if(bd>ema[0]) continue; if(ExecuteTrade(ORDER_TYPE_SELL,resistanceLevels[i]-_Point,resistanceLevels[i]+_Point)) return; } } }

void DrawHUD() {
   if(!InpShowHUD) return;
   double r2=0,sp=0; CalculateLinearRegression(InpMathPeriod,sp,r2); double atr[1]; CopyBuffer(h_atr,0,0,1,atr); double ag=CalculateSlopeAngle(sp,atr[0]);
   double rsiV=CalculateRSI(InpRSIPeriod);
   string plS=(dailyPL>=0)?"+":""; double plP=MathAbs(dailyPL)*100.0/MathMax(startOfDayEquity,0.01); color sc=IsShieldTriggered()?clrTomato:clrMediumSpringGreen;
   string prN=""; switch(InpRiskProfile) { case 0:prN="Conservador"; break; case 1:prN="Balanceado"; break; case 2:prN="Agresivo"; break; default:prN="Manual"; }
   ENUM_MARKET_SESSION ss=GetMarketSession(); MqlDateTime dt; TimeGMT(dt); string ssN=""; switch(ss) { case SESSION_ASIA:ssN="Asia"; break; case SESSION_LONDON:ssN="Londres"; break; case SESSION_NY:ssN="NY"; break; default:ssN="Off"; }
   int nP=CountActivePositions(); bool sb=IsShieldTriggered();
   string bg="SND_HUD_BG"; if(ObjectFind(0,bg)<0) { ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,10); ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,10); ObjectSetInteger(0,bg,OBJPROP_XSIZE,280); ObjectSetInteger(0,bg,OBJPROP_YSIZE,220); ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,C'30,50,50'); ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDarkSlateGray); }
   string lbl[20]; string txt[20]; color clr[20];
   lbl[0]="SND_HUD_T"; txt[0]="SUPPLY/DEMAND CVD ELITE"; clr[0]=clrAqua;
   lbl[1]="SND_HUD_1"; txt[1]=StringFormat("P&L: %s$%.2f (%.1f%%) | Shield: %s",plS,dailyPL,plP,sb?"ACTIVO":"OK"); clr[1]=sc;
   lbl[2]="SND_HUD_2"; txt[2]=StringFormat("Perfil: %s | RSI: %.1f | %s %02d:%02d",prN,rsiV,ssN,dt.hour,dt.min); clr[2]=clrSandyBrown;
   lbl[3]="SND_HUD_3"; txt[3]=StringFormat("R2: %.2f | Ang: %.1f deg | Pos: %d",r2,ag,nP); clr[3]=clrLightGray;
   for(int i=0;i<4;i++) { if(ObjectFind(0,lbl[i])<0) { ObjectCreate(0,lbl[i],OBJ_LABEL,0,0,0); ObjectSetInteger(0,lbl[i],OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,lbl[i],OBJPROP_XDISTANCE,20); ObjectSetInteger(0,lbl[i],OBJPROP_YDISTANCE,20+i*18); ObjectSetInteger(0,lbl[i],OBJPROP_FONTSIZE,8); ObjectSetString(0,lbl[i],OBJPROP_FONT,"Consolas"); } ObjectSetString(0,lbl[i],OBJPROP_TEXT,txt[i]); ObjectSetInteger(0,lbl[i],OBJPROP_COLOR,clr[i]); }
}
