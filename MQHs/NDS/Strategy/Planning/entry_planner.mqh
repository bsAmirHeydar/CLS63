#ifndef __NDS_ENTRY_PLANNER_MQH__
#define __NDS_ENTRY_PLANNER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\Contracts\\i_strategy_profile.mqh"

class NdsEntryPlanner
  {
private:
   string            m_symbol;
public:
   void              Configure(const string symbol)
     {
      m_symbol = symbol;
     }
   NdsTradeIntent    Build(const NdsSnapshot &shot,const INdsStrategyProfile &profile,const double confidence) const
     {
      NdsTradeIntent t;
      t.can_trade = false;
      t.direction = NDS_DIR_NONE;
      t.order_mode = profile.OrderMode();
      t.reason = "no setup";
      t.entry = 0.0;
      t.sl = 0.0;
      t.tp1 = 0.0;
      t.tp2 = 0.0;
      t.confidence = confidence;

      if(!shot.hook.is_valid || !shot.hook.is_closed)
         return t;
      if(confidence < profile.MinConfidence())
         return t;

      double bid = SymbolInfoDouble(m_symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double point = SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      double pad = point * 5.0;

      if(shot.hook.direction == NDS_DIR_BULL)
        {
         t.can_trade = true;
         t.direction = NDS_DIR_BULL;
         t.reason = "hook->bull continuation";
         t.entry = ask;
         t.sl = shot.flag.is_valid ? (MathMin(shot.flag.f2.price,shot.flag.f4.price) - pad) : (shot.hook.n3.price - pad);
         t.tp1 = shot.hook.n2.price;
         t.tp2 = shot.symmetry.target_price;
        }
      else
         if(shot.hook.direction == NDS_DIR_BEAR)
           {
            t.can_trade = true;
            t.direction = NDS_DIR_BEAR;
            t.reason = "hook->bear continuation";
            t.entry = bid;
            t.sl = shot.flag.is_valid ? (MathMax(shot.flag.f2.price,shot.flag.f4.price) + pad) : (shot.hook.n3.price + pad);
            t.tp1 = shot.hook.n2.price;
            t.tp2 = shot.symmetry.target_price;
           }

      return t;
     }
  };

#endif
