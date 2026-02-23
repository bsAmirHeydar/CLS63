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
input ENUM_TIMEFRAMES mTf = PERIOD_H1;
input ENUM_TIMEFRAMES nTf = PERIOD_CURRENT;
input bool isLondon = false;
input int lnHourStart = 7; //London start session H
input int lnMinuteStart = 30; //London start session M
input int lnHourEnd = 16; //London end session H
input int lnMinuteEnd = 0; //London end session M
input bool isNY = true;
input int nyHourStart = 13; //NY start session H
input int nyMinuteStart = 30; //NY start session M
input int nyHourEnd = 21; //NY end session H
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
      if((isLondon && (t.hour == lnHourStart && t.min == lnMinuteStart))
         || (isNY && (t.hour == nyHourStart && t.min == nyMinuteStart))) // entry and start
        {
         double open = iOpen(_Symbol, mTf, 1);
         double close = iClose(_Symbol, nTf, 1);
         double high =  iHigh(_Symbol, nTf, 1);
         double low =  iLow(_Symbol, PERIOD_M30, 1);
         double a = iCustom(_Symbol, PERIOD_M1, "volatility");
         double b = iCustom(_Symbol, PERIOD_M15, "volatility");
         bool buy = close < open;
         //  && (close - open) / (high - low) > 0.7;
         bool sell = close > open;
         //     && (open - close) / (high - low) > 0.7;
         if(buy)
           {
            orderType = "market";
            entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            sl = low;
         //   tp = entry + (entry - sl);
            return 0;
           }
         else
            if(sell)
              {
               orderType = "market";
               entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               sl = high;
            //   tp = entry - (sl - entry);
               return 0;
              }
        }
      if(
      (isLondon && (t.hour == lnHourEnd && t.min >= lnMinuteEnd) )
      ||(isNY && (t.hour == nyHourEnd && t.min >= nyMinuteEnd))) // close and end    (t.hour == lnHourEnd && t.min >= lnMinuteEnd) ||
        {
         closeAll(1);
         //     closeAll(-1);
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
