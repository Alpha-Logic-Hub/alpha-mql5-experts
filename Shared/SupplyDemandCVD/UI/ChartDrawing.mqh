//+------------------------------------------------------------------+
//| Chart Drawing — colors, boxes, fib levels, signals               |
//+------------------------------------------------------------------+

void ApplyChartColors()
{
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrDarkSlateGray);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrLime);
   ChartSetInteger(0, CHART_COLOR_GRID, C'15,30,45');
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrGreen);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrGray);
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrLime);
   ChartSetInteger(0, CHART_COLOR_VOLUME, clrLimeGreen);
   ChartSetInteger(0, CHART_COLOR_BID, clrLime);
   ChartSetInteger(0, CHART_COLOR_ASK, clrRed);
   ChartSetInteger(0, CHART_COLOR_LAST, clrBlack);
   ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrRed);
   ChartRedraw(0);
}

void DrawBox(string name, datetime startTime, double top, double bottom, color col, string type)
{
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, startTime, top, TimeCurrent() + (PeriodSeconds()*5), bottom);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);

   string lbl = name + "_LBL";
   ObjectCreate(0, lbl, OBJ_TEXT, 0, TimeCurrent() + (PeriodSeconds()*5), (top + bottom)/2);
   ObjectSetString(0, lbl, OBJPROP_TEXT, " " + type + " | CVD: 0  ");
   ObjectSetInteger(0, lbl, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, lbl, OBJPROP_ANCHOR, ANCHOR_RIGHT);
}

void DrawFibLevels(string baseName, datetime startTime, double top, double bottom, bool isDemand)
{
   if(!InpShowFibLines) return;

   double zoneRange = top - bottom;
   color colMain  = isDemand ? InpDemandColor : InpSupplyColor;
   color colOTE   = isDemand ? clrAqua        : clrGold;
   datetime t2    = TimeCurrent() + (PeriodSeconds() * 50);

   double f30, f50, f70;
   if(isDemand) {
      f30 = bottom + zoneRange * InpFib30;
      f50 = bottom + zoneRange * InpFib50;
      f70 = bottom + zoneRange * InpFib70;
   } else {
      f70 = top - zoneRange * InpFib30;
      f50 = top - zoneRange * InpFib50;
      f30 = top - zoneRange * InpFib70;
   }

   string n30 = baseName + "_F30";
   ObjectCreate(0, n30, OBJ_TREND, 0, startTime, f30, t2, f30);
   ObjectSetInteger(0, n30, OBJPROP_COLOR, colMain);
   ObjectSetInteger(0, n30, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, n30, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, n30, OBJPROP_BACK, true);
   ObjectSetInteger(0, n30, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n30, OBJPROP_RAY_RIGHT, false);

   string n50 = baseName + "_F50";
   ObjectCreate(0, n50, OBJ_TREND, 0, startTime, f50, t2, f50);
   ObjectSetInteger(0, n50, OBJPROP_COLOR, colOTE);
   ObjectSetInteger(0, n50, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, n50, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, n50, OBJPROP_BACK, false);
   ObjectSetInteger(0, n50, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n50, OBJPROP_RAY_RIGHT, false);

   string n70 = baseName + "_F70";
   ObjectCreate(0, n70, OBJ_TREND, 0, startTime, f70, t2, f70);
   ObjectSetInteger(0, n70, OBJPROP_COLOR, colMain);
   ObjectSetInteger(0, n70, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, n70, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, n70, OBJPROP_BACK, true);
   ObjectSetInteger(0, n70, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n70, OBJPROP_RAY_RIGHT, false);
}

void DrawSignal(double price, string text, color col)
{
   string name = "SND_Sig_" + IntegerToString(TimeCurrent()) + "_" + DoubleToString(price, 5);
   ObjectCreate(0, name, OBJ_TEXT, 0, TimeCurrent(), price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
}

void DrawTarget(double startPrice, double targetPrice, ENUM_ORDER_TYPE type)
{
   string name = "SND_Target_" + IntegerToString(TimeCurrent());
   color col = (type == ORDER_TYPE_BUY) ? clrMediumSpringGreen : clrTomato;

   ObjectCreate(0, name, OBJ_RECTANGLE, 0, TimeCurrent(), startPrice, TimeCurrent() + (PeriodSeconds()*50), targetPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FILL, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);

   string lbl = name + "_LBL";
   ObjectCreate(0, lbl, OBJ_TEXT, 0, TimeCurrent() + (PeriodSeconds()*25), targetPrice);
   ObjectSetString(0, lbl, OBJPROP_TEXT, " TP TARGET");
   ObjectSetInteger(0, lbl, OBJPROP_COLOR, col);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, lbl, OBJPROP_ANCHOR, ANCHOR_CENTER);
}
