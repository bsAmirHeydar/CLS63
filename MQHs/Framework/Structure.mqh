//+------------------------------------------------------------------+
//|                                                    Structure.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#include "Node.mqh"
class structure { // everything we need in structure
public:
   int type;
   ENUM_TIMEFRAMES tf;
   double price;
   int index;
   datetime time;
   structure(void) {}
   ~structure(void) {}

   int lowestNode(int _type, ENUM_TIMEFRAMES _tf, int _startIndex, int _endIndex) { // find lowest node in a interval
      if(!(_type == 1 || _type == -1)) // invalid type
         return -1;
      double low = 0.0;
      int resultIndex = _startIndex;
      for(int i = _startIndex;i < _endIndex;i++) {
         node nd();
         nd.scan(_type, _tf, i);
         if(nd.price < low || low == 0) {
            resultIndex = i;
            low = nd.price;
         }
      }
      return resultIndex;
   }
   int highestNode(int _type, ENUM_TIMEFRAMES _tf, int _startIndex, int _endIndex) { // find highest node in a interval
      if(!(_type == 1 || _type == -1)) // invalid type
         return -1;
      double high = 0.0;
      int resultIndex = _startIndex;
      for(int i = _startIndex; i < _endIndex; i++) {
         node nd();
         nd.scan(_type, _tf, i);
         if(nd.price > high || high == 0) {
            resultIndex = i;
            high = nd.price;
         }
      }
      return resultIndex;
   }
   int findNodeIndex(int _type, ENUM_TIMEFRAMES _tf, datetime _time) { // find node from time
      node nd;
      for(int i = 0;true;i++) {
         nd.scan(_type, _tf, i);
         if(nd.time <= _time) {
            return i;
         }
      }
      return -1;
   }
   int findNodeCandleIndex(int _type, ENUM_TIMEFRAMES _tf, datetime _time) { // find node from time
      node nd;
      for(int i = 0;true;i++) {
         nd.scan(_type, _tf, i);
         if(nd.time <= _time) {
            return nd.index;
         }
      }
      return -1;
   }
   int findCandle(ENUM_TIMEFRAMES _tf, datetime _time) { // find candle from time
      for(int i = 0;true;i++) {
         if(iTime(_Symbol, _tf, i) <= _time) {
            return i;
         }
      }
      return -1;
   }
   double topHook(int _type, ENUM_TIMEFRAMES _tf,datetime _start, datetime _end) {
      if(!(_type == 1 || _type == -1)) // invalid type
         return 0;
      int start = findNodeCandleIndex(-_type, _tf, _start);
      int end = findNodeCandleIndex(-_type, _tf, _end);
      int i = -1;
      if(_type == 1) {
         i = iHighest(_Symbol, _tf, MODE_HIGH, end - start, start);
         return iHigh(_Symbol, _tf, i);
      } else {
         i = iLowest(_Symbol, _tf, MODE_LOW, end - start, start);
         return iLow(_Symbol, _tf, i);
      }
   }
   double percentHook(int _type, ENUM_TIMEFRAMES _tf,datetime _start, datetime _end, double _percent) {
      if(!(_type == 1 || _type == -1)) // invalid type
         return 0;
      double start = iLow(_Symbol, _tf,findNodeCandleIndex(-_type, _tf, _start));
      double end = topHook(_type, _tf, _start, _end);
      if(_type == 1) {
         return  start + (end - start) * _percent;
      } else {
         return  start - (start - end) * _percent;
      }
   }
   void scan(int _type, ENUM_TIMEFRAMES _tfM, ENUM_TIMEFRAMES _tfN) {
      if(!(_type == 1 || _type == -1))
         return;
      type = _type;
      tf = _tfN;
      node ndMajorA();
      node ndMajorB();
      // scan Major nodes
      ndMajorA.scan(-_type, _tfM, 0);
      ndMajorB.scan(-_type, _tfM, 1);
      if((_type == 1 && ndMajorA.price < ndMajorB.price) ||
            (_type == -1 && ndMajorA.price > ndMajorB.price)) { // check major structure for reverse
         node nd();
         // find highest and lowest node for CHOCH and ...
         if(_type == 1)
            index = highestNode
                    (_type, _tfN, findNodeIndex(_type, _tfN, ndMajorA.time), findNodeIndex(_type, _tfN, ndMajorB.time));
         else // _type == -1
            index = lowestNode
                    (_type, _tfN, findNodeIndex(_type, _tfN, ndMajorA.time), findNodeIndex(_type, _tfN, ndMajorB.time));
         nd.scan(_type, _tfN, index);
         price = nd.price;
         time = nd.time;
      }
   }
   bool isBreak() { // check break of structure BOS or CHOCH
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
   void scan(int _type, ENUM_TIMEFRAMES _tf, int _start_index, datetime _end_time, bool first = false) { // index : not nodes, = candles
      structure strc();
      int end_index = strc.findCandle(_tf, _end_time);
      for(int i = _start_index;i < end_index;i++) {
         if(_type == 1) {
            if(iLow(_Symbol, _tf, i) > iHigh(_Symbol, _tf, i + 2)) {
               if(!isUse(_type, _tf, i, iLow(_Symbol, _tf, i))) {
                  fvgIndex = i;
                  fvgPrice = iLow(_Symbol, _tf, i);
                  obPrice = iHigh(_Symbol, _tf, i + 2);
                  wallPrice = iLow(_Symbol, _tf, i + 2);
                  if(first) break;
               }
            }
         } else if(_type == -1) {
            if(iHigh(_Symbol, _tf, i) < iLow(_Symbol, _tf, i + 2)) {
               if(!isUse(_type, _tf, i, iHigh(_Symbol, _tf, i))) {
                  fvgIndex = i;
                  fvgPrice = iHigh(_Symbol, _tf, i);
                  obPrice = iLow(_Symbol, _tf, i + 2);
                  wallPrice = iHigh(_Symbol, _tf, i + 2);
                  if(first) break;
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
