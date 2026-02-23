//+------------------------------------------------------------------+
//|                                                   volatility.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_color1  clrLime
#property indicator_color2  clrYellowGreen
#property indicator_color3  clrRed
input int volScale = 200;
input int volPeriod = 20;
input int signalPeriod = 7;
double    ExtMajorBuffer[];
double    ExtMinorBuffer[];
double    ExtSignalBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMajorBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMinorBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtSignalBuffer,INDICATOR_DATA);
// SetIndexBuffer(2,ExtLongBuffer,INDICATOR_CALCULATIONS);
//  SetIndexBuffer(3,ExtShortBuffer,INDICATOR_CALCULATIONS);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,volScale);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int32_t rates_total,
                const int32_t prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int32_t &spread[])
  {
   int i,start;
   start = prev_calculated - 1;
   if(prev_calculated == 0)
      start = volScale + 1;
   for(i = start; i < rates_total && !IsStopped(); i++)
     {
      double  ExtLongBuffer[];
      double  ExtShortBuffer[];
      double  ExtSiCalBuffer[];
      ArrayResize(ExtLongBuffer, 0);
      ArrayResize(ExtLongBuffer, volScale);
      ArrayResize(ExtShortBuffer, 0);
      ArrayResize(ExtShortBuffer, volPeriod);
      ArrayResize(ExtSiCalBuffer, 0);
      ArrayResize(ExtSiCalBuffer, signalPeriod);
      for(int j = 0; j < volScale; j++)
        {
         double c0 = 1;
         double c1 = 1;
         c0 = close[i - j];
         c1 = close[i - j - 1];
         ExtLongBuffer[j] = MathAbs(MathLog(c0 / c1)) * 10000;
        }
      ArraySort(ExtLongBuffer);
      ExtMajorBuffer[i] =
         (volScale % 2 == 0)
         ? (ExtLongBuffer[volScale / 2 - 1] + ExtLongBuffer[volScale / 2]) * 0.5
         :  ExtLongBuffer[volScale / 2];
      for(int j = 0; j < volPeriod; j++)
        {
         double c0 = 1;
         double c1 = 1;
         c0 = close[i - j];
         c1 = close[i - j - 1];
         ExtShortBuffer[j] = MathAbs(MathLog(c0 / c1)) * 10000;
        }
      ArraySort(ExtShortBuffer);
      ExtMinorBuffer[i] =
         (volPeriod % 2 == 0)
         ? (ExtShortBuffer[volPeriod / 2 - 1] + ExtShortBuffer[volPeriod / 2]) * 0.5
         :  ExtShortBuffer[volPeriod / 2];
      for(int j = 0; j < signalPeriod; j++)
        {
         double c0 = 1;
         double c1 = 1;
         c0 = close[i - j];
         c1 = close[i - j - 1];
         ExtSiCalBuffer[j] = MathAbs(MathLog(c0 / c1)) * 10000;
        }
      ArraySort(ExtSiCalBuffer);
      ExtSignalBuffer[i] =
         (signalPeriod % 2 == 0)
         ? (ExtSiCalBuffer[signalPeriod / 2 - 1] + ExtSiCalBuffer[signalPeriod / 2]) * 0.5
         :  ExtSiCalBuffer[signalPeriod / 2];
     }
//---
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int32_t id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
  }
//+------------------------------------------------------------------+
