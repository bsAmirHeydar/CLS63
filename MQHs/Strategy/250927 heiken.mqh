//+------------------------------------------------------------------+
//|                                                250927 heiken.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
input string name = "sample strategy";
#include "..\Framework\Node.mqh"
//#include "..\Framework\Sequence.mqh"
//#include "..\Framework\Structure.mqh"
//#include "..\Framework\zone.mqh"
//input ENUM_TIMEFRAMES zoneTf = PERIOD_H4;
//input ENUM_TIMEFRAMES liquidityTf = PERIOD_H1;
input ENUM_TIMEFRAMES entryTf = PERIOD_M3;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double hOpen[], hClose[], hHigh[], hLow[];
class strategy
  {
public:
   int               hHeiken;
   string            orderType;
   double            entry;
   double            sl;
   double            tp;

   int               Entry()
     {
      ArrayResize(hOpen, 0);
      ArrayResize(hClose, 0);
      ArrayResize(hLow, 0);
      ArrayResize(hHigh, 0);
      CopyBuffer(hHeiken, 0, 1, 2, hOpen);   // Open
      CopyBuffer(hHeiken, 1, 1, 2, hHigh);   // High
      CopyBuffer(hHeiken, 2, 1, 2, hLow);    // Low
      CopyBuffer(hHeiken, 3, 1, 2, hClose);  // Close
      double ma = iMA(_Symbol, entryTf, 60, 0, MODE_EMA, PRICE_CLOSE);
      if(hClose[1] > hOpen[1] && iClose(_Symbol, entryTf, 0) > ma)
        {
         node nd();nd.scan(-1, entryTf, 0);
         orderType = "market";
         entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         sl = nd.price;
         tp = entry + (entry - sl) * 4;
         return 1;
        }
      if(hClose[1] < hOpen[1] && iClose(_Symbol, entryTf, 0) < ma)
        {
         node nd();nd.scan(1, entryTf, 0);
         orderType = "market";
         entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = nd.price;
         tp = entry - (sl - entry) * 4;
         return -1;
        }
      return 0;
     }
   int               Exit()
     {     
return 0;
      ArrayResize(hOpen, 0);
      ArrayResize(hClose, 0);
      ArrayResize(hLow, 0);
      ArrayResize(hHigh, 0);
      CopyBuffer(hHeiken, 0, 1, 2, hOpen);   // Open
      CopyBuffer(hHeiken, 1, 1, 2, hHigh);   // High
      CopyBuffer(hHeiken, 2, 1, 2, hLow);    // Low
      CopyBuffer(hHeiken, 3, 1, 2, hClose);  // Close
      if(hClose[1] > hOpen[1] && hClose[0] < hOpen[0])
         return -1;
      if(hClose[1] < hOpen[1] && hClose[0] > hOpen[0])
         return 1;
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
