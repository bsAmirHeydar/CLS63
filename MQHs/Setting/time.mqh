//+------------------------------------------------------------------+
//|                                                         time.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
input bool is1 = true;
input int aHour1 = 6;
input int aMinute1 = 45;
input int bHour1 = 7;
input int bMinute1 = 45;
bool time() {
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);
   if(is1 && !(
            (t.hour > aHour1 || (t.hour == aHour1 && t.min >= aMinute1)) &&
            (t.hour < bHour1 || (t.hour == bHour1 && t.min <= bMinute1))
         )) {
         return false;
   }
   return true;
}
//+------------------------------------------------------------------+
