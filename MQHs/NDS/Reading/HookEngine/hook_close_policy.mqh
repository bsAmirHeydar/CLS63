#ifndef __NDS_HOOK_CLOSE_POLICY_MQH__
#define __NDS_HOOK_CLOSE_POLICY_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\Core\\nds_config.mqh"

class NdsHookClosePolicy
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

   bool              ClassifyHookOpenClosed(NdsHookState &hook) const
      {
      hook.is_open = false;
      hook.is_closed = false;

      if(hook.start_anchor.bar_time <= 0 || !hook.start_unbroken)
         return false;

      int hook_max_len = MathMax(hook.primary_max_len,hook.secondary_max_len);
      hook.hook_seq_max = hook_max_len;

      if(hook_max_len <= 1)
         return false;

      if(hook_max_len == 2)
        {
         hook.is_open = true;
         return true;
        }

      if(hook_max_len == 3 || hook_max_len == 4)
        {
         double retrace_need = MathMax(0.0,MathMin(1.0,m_cfg.hook_close_retrace_ratio));
         if(retrace_need <= 0.0)
           {
            hook.is_closed = true;
            return true;
           }

         double retrace_ratio = HookCloseRetraceRatioNow(hook);
         if(retrace_ratio + 1e-12 >= retrace_need)
            hook.is_closed = true;
         else
            hook.is_open = true;
         return true;
        }

      return false;
      }

   double            HookCloseRetraceRatioNow(const NdsHookState &hook) const
      {
      if(!hook.is_valid && hook.n3.bar_time <= 0)
         return 0.0;
      if(hook.scan_tf == PERIOD_CURRENT)
         return 0.0;
      if(hook.n3.bar_time <= 0 || hook.z.bar_time <= 0)
         return 0.0;

      double eps = MathMax(_Point * 0.1,1e-12);
      int z_shift = iBarShift(m_symbol,hook.scan_tf,hook.z.bar_time,false);
      if(z_shift < 0)
         return 0.0;

      int count_after_z = z_shift;
      if(count_after_z <= 0)
         return 0.0;

      if(hook.direction == NDS_DIR_BULL)
        {
         double hook_len = hook.n3.price - hook.z.price;
         if(hook_len <= eps)
            return 0.0;
         int hh_shift = iHighest(m_symbol,hook.scan_tf,MODE_HIGH,count_after_z,0);
         if(hh_shift < 0)
            return 0.0;
         double hh = iHigh(m_symbol,hook.scan_tf,hh_shift);
         double retr = (hh - hook.z.price) / hook_len;
         return MathMax(0.0,MathMin(2.0,retr));
        }

      if(hook.direction == NDS_DIR_BEAR)
        {
         double hook_len = hook.z.price - hook.n3.price;
         if(hook_len <= eps)
            return 0.0;
         int ll_shift = iLowest(m_symbol,hook.scan_tf,MODE_LOW,count_after_z,0);
         if(ll_shift < 0)
            return 0.0;
         double ll = iLow(m_symbol,hook.scan_tf,ll_shift);
         double retr = (hook.z.price - ll) / hook_len;
         return MathMax(0.0,MathMin(2.0,retr));
        }

      return 0.0;
      }
  };

#endif
