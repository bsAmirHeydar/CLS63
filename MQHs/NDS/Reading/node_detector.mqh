#ifndef __NDS_NODE_DETECTOR_MQH__
#define __NDS_NODE_DETECTOR_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "NodeDetector\\node_pivot_policy.mqh"
#include "NodeDetector\\node_scan_window_policy.mqh"
#include "NodeDetector\\node_record_builder.mqh"

class NdsNodeDetector
  {
private:
   string            m_symbol;
   NdsNodePivotPolicy m_pivot_policy;
   NdsNodeScanWindowPolicy m_window_policy;
   NdsNodeRecordBuilder m_record_builder;

   void              ScanKind(const ENUM_TIMEFRAMES tf,const int kind,const int min_shift,const int max_shift,const int last_shift,NdsNode &out_nodes[]) const
      {
      ArrayResize(out_nodes,0);
      for(int s = max_shift; s >= min_shift; s--)
        {
         if(m_pivot_policy.IsPivot(tf,kind,s,last_shift))
            m_record_builder.AppendNode(kind,tf,s,out_nodes);
        }
      }

   void              AppendOpenKindCandidates(const ENUM_TIMEFRAMES tf,const int kind,const int open_min_shift,const int open_max_shift,const int last_shift,NdsNode &out_nodes[]) const
      {
      if(last_shift < 1)
         return;
      for(int s = open_max_shift; s >= open_min_shift; s--)
        {
         if(!m_pivot_policy.IsOpenPivot(tf,kind,s,last_shift))
            continue;
         // Keep all temporary pivots in the right-edge unconfirmed zone.
         // Do not remove previous nodes from the node list; each candidate remains visible
         // until it naturally drops out of the recalculated structure.
         m_record_builder.AppendOpenNode(kind,tf,s,out_nodes);
        }
      }

public:
                     NdsNodeDetector(void)
      {
      m_symbol = _Symbol;
      m_pivot_policy.Configure(m_symbol,2);
      m_window_policy.Configure(2,300);
      m_record_builder.Configure(m_symbol);
      }

   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      int depth = MathMax(1,cfg.pivot_depth);
      int lookback = MathMax(50,cfg.lookback_bars);
      m_pivot_policy.Configure(m_symbol,depth);
      m_window_policy.Configure(depth,lookback);
      m_record_builder.Configure(m_symbol);
      }

   int               FindRecentNodes(const ENUM_TIMEFRAMES tf,const int kind,const int need_count,NdsNode &out_nodes[]) const
      {
      ArrayResize(out_nodes,0);
      if(!(kind == NDS_NODE_PEAK || kind == NDS_NODE_VALLEY))
         return 0;

      int min_shift = 0;
      int max_shift = -1;
      int last_shift = -1;

      NdsNode scanned[];
      ArrayResize(scanned,0);

      bool can_scan_confirmed = m_window_policy.Resolve(m_symbol,tf,min_shift,max_shift,last_shift);
      if(can_scan_confirmed)
         ScanKind(tf,kind,min_shift,max_shift,last_shift,scanned); // oldest -> newest
      else
        {
         int open_last_shift = -1;
         if(m_window_policy.ResolveCurrentOpenCheck(m_symbol,tf,open_last_shift))
            last_shift = open_last_shift;
         else
            return 0;
        }

      int open_min_shift = 0;
      int open_max_shift = -1;
      int open_last_shift = -1;
      if(m_window_policy.ResolveOpenZone(m_symbol,tf,open_min_shift,open_max_shift,open_last_shift))
         AppendOpenKindCandidates(tf,kind,open_min_shift,open_max_shift,open_last_shift,scanned);

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

   void              DetectNodeSetAtTf(const ENUM_TIMEFRAMES tf,NdsNodeSet &out_set,const int need_count = 0) const
      {
      ZeroMemory(out_set);
      out_set.tf = tf;
      out_set.sampled_at = TimeCurrent();
      FindRecentNodes(tf,NDS_NODE_PEAK,need_count,out_set.peaks);
      FindRecentNodes(tf,NDS_NODE_VALLEY,need_count,out_set.valleys);
      }

   void              DetectAllNodes(const ENUM_TIMEFRAMES tf,NdsNode &out_peaks[],NdsNode &out_valleys[],const int need_count = 0) const
      {
      NdsNodeSet set;
      DetectNodeSetAtTf(tf,set,need_count);

      int peak_count = ArraySize(set.peaks);
      ArrayResize(out_peaks,peak_count);
      for(int i = 0; i < peak_count; i++)
         out_peaks[i] = set.peaks[i];

      int valley_count = ArraySize(set.valleys);
      ArrayResize(out_valleys,valley_count);
      for(int j = 0; j < valley_count; j++)
         out_valleys[j] = set.valleys[j];
      }
  };

#endif
