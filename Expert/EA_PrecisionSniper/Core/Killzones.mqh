//+------------------------------------------------------------------+
//|                                             Core/Killzones.mqh     |
//|              Market Sessions + News Detection (Info Only)          |
//+------------------------------------------------------------------+
#ifndef _KILLZONES_
#define _KILLZONES_

// ── Session times in GMT (server time assumed to be GMT) ──────────
// Asia:   23:00–08:00 GMT
// London: 07:00–16:00 GMT  
// NY:     12:00–21:00 GMT
int    g_sAsiaStartH   = 23;  int g_sAsiaStartM   = 0;
int    g_sAsiaEndH     = 8;   int g_sAsiaEndM     = 0;
int    g_sLondonStartH = 7;   int g_sLondonStartM = 0;
int    g_sLondonEndH   = 16;  int g_sLondonEndM   = 0;
int    g_sNYStartH     = 12;  int g_sNYStartM     = 0;
int    g_sNYEndH       = 21;  int g_sNYEndM       = 0;

// ── News ─────────────────────────────────────────────────────────────
#define MAX_NEWS_WINDOWS 10
datetime g_newsWindows[MAX_NEWS_WINDOWS][2];
int      g_newsWindowCount = 0;
int      g_newsMinutesBefore = 15;
int      g_newsMinutesAfter  = 15;
bool     g_newsFilterEnabled = false;

//+------------------------------------------------------------------+
//| IsWithinTimeWindow                                                 |
//+------------------------------------------------------------------+
bool IsWithinTimeWindow(int startH, int startM, int endH, int endM)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int now = dt.hour * 60 + dt.min;
   int start = startH * 60 + startM;
   int end   = endH * 60 + endM;
   if(start <= end) return (now >= start && now < end);
   else return (now >= start || now < end);
}

//+------------------------------------------------------------------+
//| GetCurrentSession — returns active session name                    |
//+------------------------------------------------------------------+
string GetCurrentSession()
{
   bool asia   = IsWithinTimeWindow(g_sAsiaStartH,   g_sAsiaStartM,   g_sAsiaEndH,   g_sAsiaEndM);
   bool london = IsWithinTimeWindow(g_sLondonStartH, g_sLondonStartM, g_sLondonEndH, g_sLondonEndM);
   bool ny     = IsWithinTimeWindow(g_sNYStartH,     g_sNYStartM,     g_sNYEndH,     g_sNYEndM);

   if(london && ny)     return "LON+NY";
   if(london)           return "LONDON";
   if(ny)               return "NEW YORK";
   if(asia)             return "ASIA";
   return "LOW VOL";
}

//+------------------------------------------------------------------+
//| IsNearNews — check if current time is near a news event            |
//+------------------------------------------------------------------+
bool IsNearNews()
{
   if(!g_newsFilterEnabled || g_newsWindowCount == 0) return false;
   datetime now = TimeCurrent();
   for(int i=0; i<g_newsWindowCount; i++)
      if(now >= g_newsWindows[i][0] && now <= g_newsWindows[i][1]) return true;
   return false;
}

//+------------------------------------------------------------------+
//| GetNewsStatus — string for display: "CLEAR" or "NEWS ACTIVE"       |
//+------------------------------------------------------------------+
string GetNewsStatus()
{
   if(!g_newsFilterEnabled) return "OFF";
   if(g_newsWindowCount == 0) return "—";
   return IsNearNews() ? "⚠ NEWS" : "CLEAR";
}

//+------------------------------------------------------------------+
//| AddNewsEvent                                                       |
//+------------------------------------------------------------------+
void AddNewsEvent(datetime eventTime)
{
   if(g_newsWindowCount >= MAX_NEWS_WINDOWS) return;
   g_newsWindows[g_newsWindowCount][0] = eventTime - g_newsMinutesBefore * 60;
   g_newsWindows[g_newsWindowCount][1] = eventTime + g_newsMinutesAfter  * 60;
   g_newsWindowCount++;
}

void ClearNewsWindows() { g_newsWindowCount = 0; }

#endif // _KILLZONES_
