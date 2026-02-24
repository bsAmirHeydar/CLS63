//+------------------------------------------------------------------+
//|                                                        CLS63.mq5 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link "https://www.mql5.com"
#property version "1.10"

input int direction = 0; // 0=both, 1=buy only, -1=sell only

#include "MQHs\Setting\order.mqh"
#include "MQHs\Setting\daily.mqh"
#include "MQHs\Setting\time.mqh"
#include "MQHs\Strategy\nds-main.mqh"

strategy edge;

int OnInit()
  {
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   Comment("");
   ObjectsDeleteAll(0,"NDSDBG_" + _Symbol + "_");
  }

void OnTick()
  {
   static daily this_day;
   static bool day_inited = false;
   static datetime last_bar_time = 0;

   datetime cur_bar_time = iTime(_Symbol,_Period,0);
   if(cur_bar_time <= 0 || cur_bar_time == last_bar_time)
      return;
   last_bar_time = cur_bar_time;

   if(!day_inited)
     {
      this_day.init();
      day_inited = true;
     }

   if(!time())
      return;
   if(!this_day.dailyCheck())
      return;

   int exit_dir = edge.Exit();
   if(exit_dir != 0)
      closeAll(exit_dir);

   int delete_dir = edge.Delete();
   if(delete_dir != 0)
      deleteAll(delete_dir);

   int sig = edge.Entry();
   if((direction == 0 || direction == 1) && sig == 1)
      buy(edge.orderType,edge.entry,edge.sl,edge.tp);
   if((direction == 0 || direction == -1) && sig == -1)
      sell(edge.orderType,edge.entry,edge.sl,edge.tp);
  }
