//+------------------------------------------------------------------+
//|                                                    Structure.mqh |
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
input ENUM_TIMEFRAMES strcTF = PERIOD_M15; //Minor timeframe - Structure
input ENUM_TIMEFRAMES mStrcTF = PERIOD_H1; //Major timeframe - Structure
bool mainValley(ENUM_TIMEFRAMES tf, int z) {
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CHOCH(bool up) {
   if(up) {
      double mainHigh = 0.0;
      if(Valley(mStrcTF, 0) < Valley(mStrcTF, 1)) {
         int i = 0;
         while(-Nodes(strcTF, i) != Valley(mStrcTF, 0)) {
            i++;
         }
         int mainIndex = i;
         int firstPeak = 0;
         i++;
         while(true) {
            if(Nodes(strcTF, i) > 0) {
               firstPeak = i;
               break;
            }
            i++;
         }
         int secondValley = 0;
         while(true) {
            if(Nodes(strcTF, i) < 0) {
               secondValley = i;
               break;
            }
            i++;
         }
         mainHigh = Nodes(strcTF, firstPeak);
         int finalPeak = firstPeak;
         for(int j = firstPeak + 1;j < secondValley;j++) {
            if(Nodes(strcTF,j) > mainHigh) {
               finalPeak = j;
               mainHigh = Nodes(strcTF, j);
            }
         }
         Nodes(strcTF, finalPeak, true);
      }
   } else {
      double mainLow = 0.0;
      if(Peak(mStrcTF, 0) > Peak(mStrcTF, 1)) {
         int i = 0;
         while(Nodes(strcTF, i) != Peak(mStrcTF, 0)) {
            i++;
         }
         int mainIndex = i;
         int firstValley = 0;
         i++;
         while(true) {
            if(Nodes(strcTF, i) < 0) {
               firstValley = i;
               break;
            }
            i++;
         }
         int secondPeak = 0;
         while(true) {
            if(Nodes(strcTF, i) > 0) {
               secondPeak = i;
               break;
            }
            i++;
         }
         mainLow = -Nodes(strcTF, firstValley);
         int finalValley = firstValley;
         for(int j = firstValley + 1;j < secondPeak;j++) {
            if((Nodes(strcTF,j) < 0) && (-Nodes(strcTF,j) < mainLow)) {
               finalValley = j;
               mainLow = -Nodes(strcTF, j);
            }
         }
         Nodes(strcTF, finalValley, true);
      }
   }
   return false;
}
//+------------------------------------------------------------------+
