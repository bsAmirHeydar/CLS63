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
public:
   double            minBalance;
   double            maxBalance;
   void              init()
     {
      if(dailySl != 0.0)
         minBalance = AccountInfoDouble(ACCOUNT_BALANCE) - dailySl;
      if(dailyTp != 0.0)
         maxBalance = AccountInfoDouble(ACCOUNT_BALANCE) + dailyTp;
     }
   bool              dailyCheck()
     {
      if(dailySl != 0.0 && AccountInfoDouble(ACCOUNT_BALANCE) <= minBalance)
         return false;
      if(dailyTp != 0.0 && AccountInfoDouble(ACCOUNT_BALANCE) >= maxBalance)
         return false;
      return true;
     }
                     daily(void) {}
                    ~daily(void) {}
  };
//+------------------------------------------------------------------+
