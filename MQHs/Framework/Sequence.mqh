//+------------------------------------------------------------------+
//|                                                     Sequence.mqh |
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
#include "Node.mqh"
input bool showSycle = true;
void ScanSequence(ENUM_TIMEFRAMES start_tf, bool up) {
   if(up) {
      int i = 0;
      while(Peak(start_tf, 0) >= Peak(start_tf, i)) {
         i++;
      }
      int sycleStartIndex = i;
      if(showSycle) {
         Peak(start_tf, i, true);
      }
   } else {
      int i = 0;
      while(Valley(start_tf, 0) <= Valley(start_tf, i)) {
         i++;
      }
      int sycleStartIndex = i;
      if(showSycle) {
         Valley(start_tf, i, true);
      }
   }
}
//+------------------------------------------------------------------+
