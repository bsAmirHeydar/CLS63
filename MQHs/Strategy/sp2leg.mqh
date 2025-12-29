//+------------------------------------------------------------------+
//|                                                       sp2leg.mqh |
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
#include "..\Tools\heiken.mqh"
#include "..\Framework\Node.mqh"

input ENUM_TIMEFRAMES entryTF = PERIOD_CURRENT;
class strategy
  {
public:
   string               orderType;
   double            entry;
   double            sl;
   double            tp;

   int               Entry()
     {
      node nd();
      bool buy =
         iClose(_Symbol, entryTF, 1) > iOpen(_Symbol, entryTF, 1) &&
         iClose(_Symbol, entryTF, 2) > iOpen(_Symbol, entryTF, 2) &&
         iClose(_Symbol, entryTF, 3) > iOpen(_Symbol, entryTF, 3) &&
        // heiken(PERIOD_M15, "c", 1) > heiken(PERIOD_M15, "o", 1) &&
       //  heiken(PERIOD_M15, "c", 2) < heiken(PERIOD_M15, "o", 2) &&
         //  heiken(entryTF, "c", 2) > heiken(entryTF, "o", 2) &&
         //   heiken(entryTF, "c", 3) > heiken(entryTF, "o", 3) &&
         //   heiken(entryTF, "c", 4) < heiken(entryTF, "o", 4) &&
         iLow(_Symbol, entryTF, 1) > iLow(_Symbol, entryTF, 2) &&
         iLow(_Symbol, entryTF, 2) > iLow(_Symbol, entryTF, 3) &&
         iLow(_Symbol, entryTF, 1) > iHigh(_Symbol, entryTF, 3);
      bool sell =
         iClose(_Symbol, entryTF, 1) < iOpen(_Symbol, entryTF, 1) &&
         iClose(_Symbol, entryTF, 2) < iOpen(_Symbol, entryTF, 2) &&
         iClose(_Symbol, entryTF, 3) < iOpen(_Symbol, entryTF, 3) &&
       //  heiken(PERIOD_M15, "c", 1) < heiken(PERIOD_M15, "o", 1) &&
       //  heiken(PERIOD_M15, "c", 2) > heiken(PERIOD_M15, "o", 2) &&
         //    heiken(entryTF, "c", 2) < heiken(entryTF, "o", 2) &&
         //   heiken(entryTF, "c", 3) < heiken(entryTF, "o", 3) &&
         // heiken(entryTF, "c", 4) > heiken(entryTF, "o", 4) &&
         iLow(_Symbol, entryTF, 1) < iLow(_Symbol, entryTF, 2) &&
         iLow(_Symbol, entryTF, 2) < iLow(_Symbol, entryTF, 3) &&
         iLow(_Symbol, entryTF, 1) < iHigh(_Symbol, entryTF, 3);
      if(buy)
        {
         nd.scan(-1, entryTF, 1);
         double val1 = nd.price;
         nd.scan(-1, entryTF, 2);
         double val2 = nd.price;
         orderType = "market";
         entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sl = val1;//iLow(_Symbol, entryTF, 3);//
         tp = entry + (entry - sl) * 5;
         return 1;
        }
      if(sell)
        {
         nd.scan(1, entryTF,1);
         double peak1 = nd.price;
         nd.scan(1, entryTF,2);
         double peak2 = nd.price;
         orderType = "market";
         entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = peak1;//iHigh(_Symbol, entryTF, 3);//
         tp = entry - (sl - entry) * 5;
         return -1;
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
