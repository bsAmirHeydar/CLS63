//+------------------------------------------------------------------+
//|                                                         time.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
input bool is1 = false;
input int aHour1 = 6;
input int aMinute1 = 45;
input int bHour1 = 7;
input int bMinute1 = 45;

bool IsMinuteInWindow(const int now_minute,const int start_minute,const int end_minute)
  {
   if(start_minute <= end_minute)
      return (now_minute >= start_minute && now_minute <= end_minute);
   return (now_minute >= start_minute || now_minute <= end_minute);
  }

bool time() {
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);

   if(!is1)
      return true;

   int start_minute = MathMax(0,MathMin(23,aHour1)) * 60 + MathMax(0,MathMin(59,aMinute1));
   int end_minute = MathMax(0,MathMin(23,bHour1)) * 60 + MathMax(0,MathMin(59,bMinute1));
   int now_minute = t.hour * 60 + t.min;

   if(!IsMinuteInWindow(now_minute,start_minute,end_minute))
      return false;

   return true;
}
//+------------------------------------------------------------------+
