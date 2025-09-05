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
class structure {
public:
   double price;
   int index;
   datetime time;
   structure(void) {}
   ~structure(void) {}

   int lowestNode(int _type, ENUM_TIMEFRAMES _tf, int _startIndex, int _endIndex) {
      if(!(_type == 1 || _type == -1))
         return -1;
      double low = 0.0;
      int result = _startIndex;
      for(int i = _startIndex;i < _endIndex;i++) {
         node nd();
         nd.scan(_type, _tf, i);
         if(nd.price < low || low == 0) {
            result = i;
            low = nd.price;
         }
      }
      return result;
   }
   int highestNode(int _type, ENUM_TIMEFRAMES _tf, int _startIndex, int _endIndex) {
      if(!(_type == 1 || _type == -1))
         return -1;
      double high = 0.0;
      int result = _startIndex;
      for(int i = _startIndex;i < _endIndex;i++) {
         node nd();
         nd.scan(_type, _tf, i);
         if(nd.price > high || high == 0) {
            result = i;
            high = nd.price;
         }
      }
      return result;
   }
   int findNode(int _type, ENUM_TIMEFRAMES _tf, datetime _time) {
      node nd;
      for(int i = 0;true;i++) {
         nd.scan(_type, _tf, i);
         if(nd.time <= _time) {
            return i;
         }
      }
      return -1;
   }
   void scanA_Node(int _type, ENUM_TIMEFRAMES _tfM, ENUM_TIMEFRAMES _tfN) {
      if(!(_type == 1 || _type == -1))
         return;
      node ndM0();
      node ndM1();
      // scan Major nodes
      ndM0.scan(-_type, _tfM, 0);
      ndM1.scan(-_type, _tfM, 1);
      if((_type == 1 && ndM0.price < ndM1.price) ||
            (_type == -1 && ndM0.price > ndM1.price)) { // check major structure for reverse
         node nd();
         if(_type == 1) {
            index = highestNode(_type, _tfN, findNode(_type, _tfN, ndM0.time), findNode(_type, _tfN, ndM1.time));
            nd.scan(_type, _tfN, index);
            price = nd.price;
            time = nd.time;
         } else if(_type == -1) {
            index = lowestNode(_type, _tfN, findNode(_type, _tfN, ndM0.time), findNode(_type, _tfN, ndM1.time));
            nd.scan(_type, _tfN, index);
            price = nd.price;
            time = nd.time;
         }
      }
   }
};
//+------------------------------------------------------------------+
