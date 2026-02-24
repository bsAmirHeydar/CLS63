#ifndef __NDS_NODE_DETECTOR_MQH__
#define __NDS_NODE_DETECTOR_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"

class NdsNodeDetector
  {
private:
   string            m_symbol;
   int               m_depth;
   int               m_lookback;

   bool              IsPeakPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      if(shift - m_depth < 1)
         return false;
      if(shift + m_depth > last_shift)
         return false;

      double center = iHigh(m_symbol,tf,shift);
      for(int k = 1; k <= m_depth; k++)
        {
         double right = iHigh(m_symbol,tf,shift - k); // newer bars
         double left = iHigh(m_symbol,tf,shift + k);  // older bars

         // Tie-break rule: for equal highs, keep only the newest pivot.
         if(center <= right)
            return false;
         if(center < left)
            return false;
        }
      return true;
      }

   bool              IsValleyPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      if(shift - m_depth < 1)
         return false;
      if(shift + m_depth > last_shift)
         return false;

      double center = iLow(m_symbol,tf,shift);
      for(int k = 1; k <= m_depth; k++)
        {
         double right = iLow(m_symbol,tf,shift - k); // newer bars
         double left = iLow(m_symbol,tf,shift + k);  // older bars

         // Tie-break rule: for equal lows, keep only the newest pivot.
         if(center >= right)
            return false;
         if(center > left)
            return false;
        }
      return true;
      }

   void              AppendNode(const int kind,const ENUM_TIMEFRAMES tf,const int shift,NdsNode &out_nodes[]) const
      {
      int n = ArraySize(out_nodes);
      ArrayResize(out_nodes,n + 1);

      out_nodes[n].kind = kind;
      out_nodes[n].seq_no = 0;
      out_nodes[n].bar_index = shift;
      out_nodes[n].bar_time = iTime(m_symbol,tf,shift);
      out_nodes[n].price = (kind == NDS_NODE_PEAK ? iHigh(m_symbol,tf,shift) : iLow(m_symbol,tf,shift));
      out_nodes[n].is_open = false;
      }

   void              ScanKind(const ENUM_TIMEFRAMES tf,const int kind,const int min_shift,const int max_shift,const int last_shift,NdsNode &out_nodes[]) const
      {
      ArrayResize(out_nodes,0);
      for(int s = max_shift; s >= min_shift; s--)
        {
         bool is_pivot = false;
         if(kind == NDS_NODE_PEAK)
            is_pivot = IsPeakPivot(tf,s,last_shift);
         else
            if(kind == NDS_NODE_VALLEY)
               is_pivot = IsValleyPivot(tf,s,last_shift);

         if(is_pivot)
            AppendNode(kind,tf,s,out_nodes);
        }
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

      int bars_total = iBars(m_symbol,tf);
      if(bars_total <= m_depth * 2 + 3)
         return 0;

      int last_shift = bars_total - 1;
      int min_shift = m_depth + 1; // ignore forming-bar neighborhood
      int max_shift = MathMin(m_lookback,last_shift - m_depth);
      if(max_shift < min_shift)
         return 0;

      NdsNode scanned[];
      ScanKind(tf,kind,min_shift,max_shift,last_shift,scanned); // oldest -> newest

      int total = ArraySize(scanned);
      if(total <= 0)
         return 0;

      int take = (need_count > 0 ? MathMin(need_count,total) : total);
      int start = total - take;
      ArrayResize(out_nodes,take);
      for(int i = 0; i < take; i++)
        {
         out_nodes[i] = scanned[start + i];
         out_nodes[i].seq_no = i + 1;
        }

      return take;
      }
  };

#endif
