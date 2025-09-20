//+------------------------------------------------------------------+
//|                                                       sample.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
input string name = "sample strategy";
#include "..\Framework\Node.mqh"
#include "..\Framework\Sequence.mqh"
#include "..\Framework\Structure.mqh"
#include "..\Framework\zone.mqh"
input ENUM_TIMEFRAMES zoneTf = PERIOD_H4;
input ENUM_TIMEFRAMES liquidityTf = PERIOD_H1;
input ENUM_TIMEFRAMES entryTf = PERIOD_M1;
class strategy
  {
public:
   int               orderType;
   double            entry;
   double            sl;
   double            tp;

   int               Entry()
     {
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
