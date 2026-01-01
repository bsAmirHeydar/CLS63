//+------------------------------------------------------------------+
//|                                                    time-main.mqh |
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
#include "..\Setting\order.mqh"

input int lnHourStart = 10; //London start session H
input int lnMinuteStart = 0; //London start session M
input int lnHourEnd = 0; //London end session H
input int lnMinuteEnd = 0; //London end session M
input int nyHourStart = 15; //NY start session H
input int nyMinuteStart = 0; //NY start session M
input int nyHourEnd = 18; //NY end session H
input int nyMinuteEnd = 0; //NY end session M
class strategy
  {
public:
   string            orderType;
   double            entry;
   double            sl;
   double            tp;

   int               Entry()
     {
      datetime now = TimeCurrent();
      MqlDateTime t;
      TimeToStruct(now, t);
      if((t.hour == lnHourStart && t.min == lnMinuteStart) || (t.hour == nyHourStart && t.min == nyMinuteStart)) // entry and start
        {
         double open = iOpen(_Symbol, PERIOD_M30, 1);
         double close = iClose(_Symbol, PERIOD_M30, 1);
         double high =  iHigh(_Symbol, PERIOD_M30, 1);
         double low =  iLow(_Symbol, PERIOD_M30, 1);
         bool buy = close > open
                    && (close - open) / (high - low) > 0.7;
         bool sell = close < open
                     && (open - close) / (high - low) > 0.7;
         if(buy)
            return 1;
         else
            if(sell)
               return -1;
        }
      if((t.hour == lnHourEnd && t.min == lnMinuteEnd) || (t.hour == nyHourEnd && t.min == nyMinuteEnd)) // close and end
        {
         closeAll(1);
         closeAll(-1);
        }
      return 0;
     }
   int               Exit()
     {
      return 0;
     }
   int               Delete()
     {
      return 0;
     }
   int               Trail(double &_newPrice)
     {
      return 0;
     }
                     strategy(void) {}
                    ~strategy(void) {}
  };
//+------------------------------------------------------------------+
