#ifndef __NDS_ENTRY_PLANNER_MQH__
#define __NDS_ENTRY_PLANNER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\Core\\nds_config.mqh"
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
   NdsTradeIntent    Build(const NdsSnapshot &shot,const INdsStrategyProfile &profile,const NdsConfig &cfg,const double confidence) const
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

      if(!shot.cycle.has_hook2)
         return t;
      if(!shot.cycle.hook2.is_valid || !shot.cycle.hook2.is_closed)
         return t;
      if(shot.cycle.hook2.start_anchor.bar_time <= 0 || !shot.cycle.hook2.start_unbroken)
         return t;
      if(!shot.flag.is_valid)
         return t;
      if(shot.flag.direction != shot.cycle.direction)
         return t;
      if(confidence < profile.MinConfidence())
         return t;

      double bid = SymbolInfoDouble(m_symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double point = SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      double pad = point * 2.0;

      if(shot.cycle.direction == NDS_DIR_BULL)
        {
         double entry_limit = shot.cycle.hook2.level_86;
         if(entry_limit <= 0.0)
            entry_limit = shot.cycle.hook2.z.price + (shot.cycle.hook2.n3.price - shot.cycle.hook2.z.price) * MathMax(0.1,MathMin(0.9,cfg.limit_pullback_ratio));
         if(entry_limit >= ask)
            entry_limit = ask - point;

         t.can_trade = true;
         t.direction = NDS_DIR_BULL;
         t.reason = "reverse buy-limit at ND(86.4) of Hook2 with LTF flag confirm";
         t.entry = entry_limit;
         t.sl = shot.cycle.hook2.z.price - pad;
         if(t.sl >= t.entry)
            t.sl = t.entry - 3.0 * pad;
         t.tp1 = shot.cycle.hook2.n3.price;
         double rr = t.entry - t.sl;
         t.tp2 = shot.symmetry.target_price > t.entry ? shot.symmetry.target_price : (t.entry + 2.0 * rr);
        }
      else
         if(shot.cycle.direction == NDS_DIR_BEAR)
           {
            double entry_limit = shot.cycle.hook2.level_86;
            if(entry_limit <= 0.0)
               entry_limit = shot.cycle.hook2.z.price - (shot.cycle.hook2.z.price - shot.cycle.hook2.n3.price) * MathMax(0.1,MathMin(0.9,cfg.limit_pullback_ratio));
            if(entry_limit <= bid)
               entry_limit = bid + point;

            t.can_trade = true;
            t.direction = NDS_DIR_BEAR;
            t.reason = "reverse sell-limit at ND(86.4) of Hook2 with LTF flag confirm";
            t.entry = entry_limit;
            t.sl = shot.cycle.hook2.z.price + pad;
            if(t.sl <= t.entry)
               t.sl = t.entry + 3.0 * pad;
            t.tp1 = shot.cycle.hook2.n3.price;
            double rr = t.sl - t.entry;
            t.tp2 = shot.symmetry.target_price < t.entry && shot.symmetry.target_price > 0.0 ? shot.symmetry.target_price : (t.entry - 2.0 * rr);
           }

      return t;
     }
  };

#endif
