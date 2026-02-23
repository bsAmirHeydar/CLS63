#ifndef __NDS_NODE_DETECTOR_MQH__
#define __NDS_NODE_DETECTOR_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "data_window.mqh"

class NdsNodeDetector
  {
private:
   string            m_symbol;
   int               m_depth;
   int               m_lookback;

   bool              IsLocalPeak(const NdsDataWindow &dw,const ENUM_TIMEFRAMES tf,const int shift) const
     {
      double h = dw.High(tf,shift);
      for(int j = 1; j <= m_depth; j++)
        {
         if(h <= dw.High(tf,shift - j) || h < dw.High(tf,shift + j))
            return false;
        }
      return true;
     }
   bool              IsLocalValley(const NdsDataWindow &dw,const ENUM_TIMEFRAMES tf,const int shift) const
     {
      double l = dw.Low(tf,shift);
      for(int j = 1; j <= m_depth; j++)
        {
         if(l >= dw.Low(tf,shift - j) || l > dw.Low(tf,shift + j))
            return false;
        }
      return true;
     }
public:
                     NdsNodeDetector(void)
     {
      m_symbol = _Symbol;
      m_depth = 2;
      m_lookback = 300;
     }
   void              Configure(const string symbol,const NdsConfig &cfg)
     {
      m_symbol = symbol;
      m_depth = MathMax(1,cfg.pivot_depth);
      m_lookback = MathMax(50,cfg.lookback_bars);
     }
   int               FindRecentNodes(const ENUM_TIMEFRAMES tf,const int kind,const int need_count,NdsNode &out_nodes[]) const
     {
      ArrayResize(out_nodes,0);
      if(!(kind == NDS_NODE_PEAK || kind == NDS_NODE_VALLEY))
         return 0;
      NdsDataWindow dw(m_symbol);
      int bars = dw.CountBars(tf);
      int max_shift = MathMin(bars - m_depth - 2,m_lookback);
      int found = 0;

      for(int s = m_depth + 1; s <= max_shift && found < need_count; s++)
        {
         bool ok = (kind == NDS_NODE_PEAK) ? IsLocalPeak(dw,tf,s) : IsLocalValley(dw,tf,s);
         if(!ok)
            continue;

         NdsNode nd;
         nd.kind = kind;
         nd.seq_no = found + 1;
         nd.bar_index = s;
         nd.bar_time = dw.Time(tf,s);
         nd.price = (kind == NDS_NODE_PEAK) ? dw.High(tf,s) : dw.Low(tf,s);
         nd.is_open = false;

         int n = ArraySize(out_nodes);
         ArrayResize(out_nodes,n + 1);
         out_nodes[n] = nd;
         found++;
        }

      return found;
     }
  };

#endif
