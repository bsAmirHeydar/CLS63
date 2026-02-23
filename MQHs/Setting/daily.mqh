//+------------------------------------------------------------------+
//|                                                        daily.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
input double dailySl = 0.0; //daily sl
input double dailyTp = 0.0; //daily tp
class daily
  {
private:
   datetime          DateStart(const datetime value) const
     {
      MqlDateTime t;
      TimeToStruct(value,t);
      t.hour = 0;
      t.min = 0;
      t.sec = 0;
      return StructToTime(t);
     }

public:
   double            minBalance;
   double            maxBalance;
   datetime          today;
   void              init()
     {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      today = DateStart(TimeCurrent());
      minBalance = (dailySl > 0.0) ? (balance - dailySl) : -DBL_MAX;
      maxBalance = (dailyTp > 0.0) ? (balance + dailyTp) : DBL_MAX;
     }
   bool              dailyCheck()
     {
      datetime now = TimeCurrent();
      if(today == 0 || DateStart(now) != today)
         init();
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(dailySl > 0.0 && balance <= minBalance)
         return false;
      if(dailyTp > 0.0 && balance >= maxBalance)
         return false;
      return true;
     }
                     daily(void)
     {
      minBalance = -DBL_MAX;
      maxBalance = DBL_MAX;
      today = 0;
     }
                    ~daily(void) {}
  };
//+------------------------------------------------------------------+
