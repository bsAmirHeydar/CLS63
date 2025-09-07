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
   int type;
   ENUM_TIMEFRAMES tf;
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
   int findCandle(ENUM_TIMEFRAMES _tf, datetime _time) {
      for(int i = 0;true;i++) {
         if(iTime(_Symbol, _tf, i) <= _time) {
            return i;
         }
      }
      return -1;
   }
   void scan(int _type, ENUM_TIMEFRAMES _tfM, ENUM_TIMEFRAMES _tfN) {
      if(!(_type == 1 || _type == -1))
         return;
      type = _type;
      tf = _tfN;
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
   bool isBreak() {
      node nd();
      nd.scan(type, tf, index);
      for(int i = 0;i < nd.index;i++) {
         double close = iClose(_Symbol, tf, i);
         if((type == 1 && close > nd.price) || (type == -1 &&  close < nd.price)) {
            return true;
         }
      }
      return false;
   }
};
//+------------------------------------------------------------------+
class imbalance {
public:
   int fvgIndex;
   double fvgPrice;
   double obPrice;
   double wallPrice;
   bool isUse(int _type,ENUM_TIMEFRAMES _tf, int _fvgIndex, double _aPrice) {
      for(int i = 0;i < _fvgIndex;i++) {
         if((_type == 1 && iLow(_Symbol, _tf, i) < _aPrice) || (_type == -1 && iHigh(_Symbol, _tf, i) > _aPrice)) {
            return true;
         }
      }
      return false;
   }
   void scan(int _type, ENUM_TIMEFRAMES _tf, int _start_index, datetime _end_time) { // index : not nodes, = candles
      structure strc();
      int end_index = strc.findCandle(_tf, _end_time);
      for(int i = _start_index;i < end_index;i++) {
         if(_type == 1) {
            if(iLow(_Symbol, _tf, i) > iHigh(_Symbol, _tf, i + 2)) {
               if(true) { //!isUse(_type, _tf, i, iLow(_Symbol, _tf, i))) {
                  fvgIndex = i;
                  fvgPrice = iLow(_Symbol, _tf, i);
                  obPrice = iHigh(_Symbol, _tf, i + 2);
                  wallPrice = iLow(_Symbol, _tf, i + 2);
               }
            }
         } else if(_type == -1) {
            if(iHigh(_Symbol, _tf, i) < iLow(_Symbol, _tf, i + 2)) {
               if(true) { //!isUse(_type, _tf, i, iHigh(_Symbol, _tf, i))) {
                  fvgIndex = i;
                  fvgPrice = iHigh(_Symbol, _tf, i);
                  obPrice = iLow(_Symbol, _tf, i + 2);
                  wallPrice = iHigh(_Symbol, _tf, i + 2);
               }
            }
         }
      }
   }
   bool is() {
      if(fvgPrice != 0) {
         return true;
      }
      return false;
   }
   imbalance(void) {}
   ~imbalance(void) {}
};
//+------------------------------------------------------------------+
