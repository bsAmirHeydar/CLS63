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
class structure {
public:
   int direction;
   double mainPrice;
   datetime mainTime;
   bool isBreak;
   double breakPrice;
   datetime breakTime;
   bool isImbalance;
   double entryImbalance;
   double slImbalance;

   structure(void) {}
   ~structure(void) {}

   double scanCHOCH(bool up) {
      if(up) {
         direction = 1;
         //double mainHigh = 0.0;
         mainPrice = 0.0;
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
            mainPrice = Nodes(strcTF, firstPeak);
            int finalPeak = firstPeak;
            for(int j = firstPeak + 1;j < secondValley;j++) {
               if(Nodes(strcTF,j) > mainPrice) {
                  finalPeak = j;
                  mainPrice = Nodes(strcTF, j);
               }
            }
            //mainPrice = Nodes(strcTF, finalPeak, true);
            node upNode();
            upNode.Nodes(strcTF, finalPeak, false);
            mainTime = upNode.time;
         }
      } else {
         direction = -1;
         //double mainLow = 0.0;
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
            mainPrice = -Nodes(strcTF, firstValley);
            int finalValley = firstValley;
            for(int j = firstValley + 1;j < secondPeak;j++) {
               if((Nodes(strcTF,j) < 0) && (-Nodes(strcTF,j) < mainPrice)) {
                  finalValley = j;
                  mainPrice = -Nodes(strcTF, j);
               }
            }
            //mainPrice = -Nodes(strcTF, finalValley, true);
            node downNode();
            downNode.Nodes(strcTF, finalValley, false);
            mainTime = downNode.time;
         }
      }
      return mainPrice;
   }
   void checkBreak() {
      isBreak = false;
      int i = 0;
      datetime currentTime = iTime(_Symbol, strcTF, i);
      if(mainPrice != 0 && mainTime != 0) {
         if(direction == 1) {
            while(currentTime > mainTime) {
               if(iClose(_Symbol, strcTF, i) > mainPrice) {
                  isBreak = true;
                  breakPrice = iHigh(_Symbol, strcTF, i);
                  breakTime = iTime(_Symbol, strcTF, i);
                  break;
               }
               i++;
               currentTime = iTime(_Symbol, strcTF, i);
            }
         } else if(direction == -1) {
            while(currentTime > mainTime) {
               if(iClose(_Symbol, strcTF, i) < mainPrice) {
                  isBreak = true;
                  breakPrice = iLow(_Symbol, strcTF, i);
                  breakTime = iTime(_Symbol, strcTF, i);
                  break;
               }
               i++;
               currentTime = iTime(_Symbol, strcTF, i);
            }
         }
      }
   }
   void scanImbalance() {
      int i = 0;
      datetime currentTime = iTime(_Symbol, strcTF, i);
      if(direction == -1) {
         while(currentTime > mainTime) {
            if(iHigh(_Symbol, strcTF, i) < iLow(_Symbol, strcTF, i + 2)) {
               if(checkValidImbalance(iTime(_Symbol, strcTF, i), iHigh(_Symbol, strcTF, i))) {
                  isImbalance = true;
                  entryImbalance = iLow(_Symbol, strcTF, i + 2);
                  node upNode();
                  slImbalance = upNode.scanFirstPeak(iTime(_Symbol,strcTF, i + 2), strcTF);
               }
            }
            i++;
            currentTime = iTime(_Symbol, strcTF, i);
         }
      } else if(direction == 1) {
         while(currentTime > mainTime) {
            if(iLow(_Symbol, strcTF, i) > iHigh(_Symbol, strcTF, i + 2)) {
               if(checkValidImbalance(iTime(_Symbol, strcTF, i), iLow(_Symbol, strcTF, i))) {
                  isImbalance = true;
                  entryImbalance = iHigh(_Symbol, strcTF, i + 2);
                  node downNode();
                  slImbalance = downNode.scanFirstValley(iTime(_Symbol,strcTF, i + 2), strcTF);
               }
            }
            i++;
            currentTime = iTime(_Symbol, strcTF, i);
         }
      }
   }
   bool checkValidImbalance(datetime time, double edge) {
      int i = 0;
      datetime currentTime = iTime(_Symbol, strcTF, i);
      if(direction == -1) {
         while(currentTime > time) {
            if(iHigh(_Symbol, strcTF, i) > edge) {
               return false;
            }
            i++;
            currentTime = iTime(_Symbol, strcTF, i);
         }
      } else if(direction == 1) {
         while(currentTime > time) {
            if(iLow(_Symbol, strcTF,i) < edge) {
               return false;
            }
            i++;
            currentTime = iTime(_Symbol, strcTF, i);
         }
      }
      return true;
   }
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
