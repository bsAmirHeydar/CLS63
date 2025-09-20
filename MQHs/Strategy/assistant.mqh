//+------------------------------------------------------------------+
//|                                                    assistant.mqh |
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
input ENUM_TIMEFRAMES zoneHTf = PERIOD_H4;
input ENUM_TIMEFRAMES zoneLTf = PERIOD_M15;
//input ENUM_TIMEFRAMES entryTf = PERIOD_M1;
class strategy
  {
public:
   int               orderType;
   double            entry;
   double            sl;
   double            tp;

   int               Entry(int _index = 0)
     {
      zone znL();
      zone znH();
      if(znH.scan(zoneHTf) < 0.25)   // major zone
        {
         if(znL.scan(zoneLTf) < -0.75)
           {
            node nd();
            nd.liquidityScan(-1, zoneLTf, znL.get(), _index);
            entry = nd.price;
            nd.liquidityScan(-1, zoneLTf, entry, _index + 1);
            sl = nd.price;
            return 1;
           }
        }
      if(znH.scan(zoneHTf) > -0.25)   // major zone
        {
         if(znL.scan(zoneLTf) > 0.75)
           {
            node nd();
            nd.liquidityScan(1, zoneLTf, znL.get(), _index);
            entry = nd.price;
            nd.liquidityScan(1, zoneLTf, entry, _index + 1);
            sl = nd.price;
            return -1;
           }
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
   int               Trail(double & _newPrice)
     {
      return 0;
     }
                     strategy(void) {}
                    ~strategy(void) {}
  };
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
