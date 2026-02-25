#ifndef __NDS_HOOK_MARKET_RULES_MQH__
#define __NDS_HOOK_MARKET_RULES_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\..\\Core\\nds_config.mqh"

class NdsHookMarketRules
  {
private:
   string            m_symbol;
   NdsConfig         m_cfg;

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_cfg = cfg;
      }

   int               MinBarsForHook(const ENUM_TIMEFRAMES tf) const
      {
      int by_depth = m_cfg.pivot_depth * 12 + 30;
      return MathMax(80,by_depth);
      }

   bool              HasEnoughBars(const ENUM_TIMEFRAMES tf) const
      {
      int bars = iBars(m_symbol,tf);
      return (bars >= MinBarsForHook(tf));
      }

   bool              IsAnchorUnbroken(const ENUM_TIMEFRAMES tf,const NdsNode &anchor,const int dir) const
      {
      if(anchor.bar_time <= 0 || anchor.price <= 0.0)
         return false;
      int shift = iBarShift(m_symbol,tf,anchor.bar_time,false);
      if(shift < 0)
         return false;

      double eps = MathMax(_Point * 0.1,1e-12);
      for(int s = shift - 1; s >= 0; s--)
        {
         if(dir == NDS_DIR_BULL)
           {
            double lo = iLow(m_symbol,tf,s);
            if(lo < anchor.price - eps)
               return false;
           }
         else
            if(dir == NDS_DIR_BEAR)
              {
               double hi = iHigh(m_symbol,tf,s);
               if(hi > anchor.price + eps)
                  return false;
              }
        }
      return true;
      }

   bool              IsHookExpiredNow(const NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return true;
      if(hook.start_anchor.bar_time <= 0 || hook.start_anchor.price <= 0.0)
         return true;
      return !IsAnchorUnbroken(hook.scan_tf,hook.start_anchor,hook.direction);
      }
  };

#endif
