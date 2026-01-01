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
#include "..\Setting\order.mqh"
#include "..\Tools\candle consistency.mqh"
#include "..\Tools\donchain.mqh"


input ENUM_TIMEFRAMES entryTF = PERIOD_CURRENT;
input ENUM_TIMEFRAMES bigTF = PERIOD_H4;
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
      nd.scan(-1, entryTF, 0);
      double val1 = nd.price;
      nd.scan(-1, entryTF, 2);
      double val2 = nd.price;
      nd.scan(1, entryTF,0);
      double peak1 = nd.price;
      nd.scan(1, entryTF,2);
      double peak2 = nd.price;
      nd.scan(-1, bigTF, 0);
      double bigval1 = nd.price;
      nd.scan(-1, bigTF, 2);
      double bigval2 = nd.price;
      nd.scan(1, bigTF,0);
      double bigpeak1 = nd.price;
      nd.scan(1, bigTF,2);
      double bigpeak2 = nd.price;
      nd.scan(1, PERIOD_H4, 1);
      double peakBig = nd.price;
      nd.scan(-1, PERIOD_H4, 1);
      double valBig = nd.price;
      bool buy =
         //bigpeak1 > bigpeak2 &&
         //HeikenColor(bigTF, 1) == 1 &&
         // iHigh(_Symbol, entryTF, 1) > donchian(55, 1, entryTF, 1) &&
        // iClose(_Symbol, entryTF, 1) > iOpen(_Symbol, entryTF, 1) &&
         //iClose(_Symbol, entryTF, 2) > iOpen(_Symbol, entryTF, 2) &&
        // iClose(_Symbol, entryTF, 3) > iOpen(_Symbol, entryTF, 3) &&
         iLow(_Symbol, entryTF, 1) > iLow(_Symbol, entryTF, 2) &&
         iLow(_Symbol, entryTF, 2) > iLow(_Symbol, entryTF, 3) &&
         iLow(_Symbol, entryTF, 1) > iHigh(_Symbol, entryTF, 3) 
         //iHigh(_Symbol, entryTF, 1) > iHigh(_Symbol, entryTF, 2) &&
       //  iHigh(_Symbol, entryTF, 2) > iHigh(_Symbol, entryTF, 3) 
       //  (iClose(_Symbol, entryTF, 1) - iOpen(_Symbol, entryTF, 3)) / (iHigh(_Symbol, entryTF, 1) - iLow(_Symbol, entryTF, 3)) > 0.6 &&
        // isConsistant(3, 0.7)
         ;
      bool sell =
         //bigval1 < bigval2 &&
         //HeikenColor(bigTF, 1) == -1 &&
         //  iLow(_Symbol, entryTF, 1) < donchian(55, -1, entryTF, 1) &&
    //     iClose(_Symbol, entryTF, 1) < iOpen(_Symbol, entryTF, 1) &&
      //   iClose(_Symbol, entryTF, 2) < iOpen(_Symbol, entryTF, 2) &&
        // iClose(_Symbol, entryTF, 3) < iOpen(_Symbol, entryTF, 3) &&
         iHigh(_Symbol, entryTF, 1) < iHigh(_Symbol, entryTF, 2) &&
         iHigh(_Symbol, entryTF, 2) < iHigh(_Symbol, entryTF, 3) &&
         iHigh(_Symbol, entryTF, 1) < iLow(_Symbol, entryTF, 3) 
       //  iLow(_Symbol, entryTF, 1) < iLow(_Symbol, entryTF, 2) &&
       //  iLow(_Symbol, entryTF, 2) < iLow(_Symbol, entryTF, 3) 
        // MathAbs(iClose(_Symbol, entryTF, 1) - iOpen(_Symbol, entryTF, 3)) / (iHigh(_Symbol, entryTF, 1) - iLow(_Symbol, entryTF, 3)) > 0.6  &&
         //isConsistant(3, 0.7)
         ;
      if(buy)
        {
         //   deleteAll(1);
         orderType = "market";
         entry =  SymbolInfoDouble(_Symbol, SYMBOL_ASK);//val1 + (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - val1) / 4;//
         sl = donchian(3, -1, entryTF, 1);//val1;//iLow(_Symbol, entryTF, 3);//
         tp =  entry + (entry - sl) * 1;
         return 1;
        }
      if(sell)
        {
         //   deleteAll(-1);
         orderType = "market";
         entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);//peak1 - (peak1 - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 4; //
         sl = donchian(3, 1, entryTF, 1);//peak1;//iHigh(_Symbol, entryTF, 3);//
         tp =  entry - (sl - entry) * 1;
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
      _newPrice = donchian(3, -1, entryTF, 1);
      return 1;
     }
                     strategy(void) {}
                    ~strategy(void) {}
  };
//+------------------------------------------------------------------+
