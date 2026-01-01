//+------------------------------------------------------------------+
//|                                           candle consistency.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
bool isConsistant(int bars_count, double threshold)
  {
   if(bars_count <= 0 || threshold <= 0.0)
      return false;
   if(Bars(_Symbol, _Period) < bars_count)
      return false;
   double max_range = 0.0;
   double min_range = DBL_MAX;
   for(int i = 1; i <= bars_count; i++)
     {
      double high = iHigh(_Symbol, _Period, i);
      double low  = iLow(_Symbol, _Period, i);
      double range = MathAbs(high - low);
      if(range <= 0.0)
         continue;
      if(range > max_range)
         max_range = range;
      if(range < min_range)
         min_range = range;
     }
   if(max_range == 0.0 || min_range == DBL_MAX)
      return false;
   double ratio = min_range / max_range;
   return (ratio > threshold);
  }
//+------------------------------------------------------------------+
