#ifndef __NDS_HOOK_ENGINE_MQH__
#define __NDS_HOOK_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "node_detector.mqh"
#include "sequence_engine.mqh"

struct NdsHookSeqLayer
  {
   NdsNode           nodes[]; // newest -> oldest
  };

string g_nds_hook_hist_symbols[];
NdsHookState g_nds_hook_hist_items[];

class NdsHookEngine
  {
private:
   string            m_symbol;
   NdsConfig         m_cfg;
   NdsNodeDetector   m_nodes;
   NdsSequenceEngine m_seq_engine;

   NdsNode           EmptyNode(const int kind) const
      {
      NdsNode nd;
      nd.kind = kind;
      nd.seq_no = 0;
      nd.bar_index = -1;
      nd.bar_time = 0;
      nd.price = 0.0;
      nd.is_open = false;
      return nd;
      }

   NdsHookState      EmptyHook(void) const
      {
      NdsHookState hook;
      hook.is_valid = false;
      hook.direction = NDS_DIR_NONE;
      hook.hook_type = NDS_HOOK_UNKNOWN;
      hook.scan_tf = PERIOD_CURRENT;
      hook.n1 = EmptyNode(NDS_NODE_NONE);
      hook.n2 = EmptyNode(NDS_NODE_NONE);
      hook.n3 = EmptyNode(NDS_NODE_NONE);
      hook.z = EmptyNode(NDS_NODE_NONE);
      hook.start_anchor = EmptyNode(NDS_NODE_NONE);
      hook.start_unbroken = false;
      hook.primary_layers = 0;
      hook.secondary_layers = 0;
      hook.primary_max_len = 0;
      hook.secondary_max_len = 0;
      hook.is_open = false;
      hook.level_86 = 0.0;
      hook.is_closed = false;
      return hook;
      }

   void              PushHook(const NdsHookState &hook,NdsHookState &hooks[]) const
      {
      int n = ArraySize(hooks);
      ArrayResize(hooks,n + 1);
      hooks[n] = hook;
      }

   void              CopyNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      int n = ArraySize(src);
      ArrayResize(dst,n);
      for(int i = 0; i < n; i++)
         dst[i] = src[i];
      }

   void              ReverseNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      int n = ArraySize(src);
      ArrayResize(dst,n);
      for(int i = 0; i < n; i++)
         dst[i] = src[n - 1 - i];
      }

   void              PushNode(const NdsNode &nd,NdsNode &arr[]) const
      {
      int n = ArraySize(arr);
      ArrayResize(arr,n + 1);
      arr[n] = nd;
      }

   void              ClearTailForNested(const bool valley_mode,const double new_price,NdsNode &arr[]) const
      {
      while(ArraySize(arr) > 0)
        {
         int last = ArraySize(arr) - 1;
         double p = arr[last].price;
         bool conflict = valley_mode ? (p > new_price) : (p < new_price);
         if(!conflict)
            break;
         ArrayResize(arr,last);
        }
      }

   void              CopyLayer(const NdsHookSeqLayer &src,NdsHookSeqLayer &dst) const
      {
      CopyNodes(src.nodes,dst.nodes);
      }

   void              BuildNestedLayersFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,NdsHookSeqLayer &layers[]) const
      {
      ArrayResize(layers,0);
      int n = ArraySize(src_old_to_new);
      if(n <= 0)
         return;

      NdsNode rev_new_to_old[];
      ReverseNodes(src_old_to_new,rev_new_to_old);

      ArrayResize(layers,1);
      ArrayResize(layers[0].nodes,0);
      PushNode(rev_new_to_old[0],layers[0].nodes);

      for(int i = 1; i < n; i++)
        {
         NdsNode nd = rev_new_to_old[i];
         NdsNode prev = rev_new_to_old[i - 1];
         int last = ArraySize(layers) - 1;

         bool continue_same = valley_mode ? (nd.price > prev.price) : (nd.price < prev.price);
         if(continue_same)
           {
            PushNode(nd,layers[last].nodes);
           }
         else
           {
            int next_index = last + 1;
            ArrayResize(layers,next_index + 1);
            CopyLayer(layers[last],layers[next_index]);
            ClearTailForNested(valley_mode,nd.price,layers[next_index].nodes);
            PushNode(nd,layers[next_index].nodes);
           }
        }
      }

   int               MaxLayerLength(const NdsHookSeqLayer &layers[]) const
      {
      int mx = 0;
      int n = ArraySize(layers);
      for(int i = 0; i < n; i++)
        {
         int len = ArraySize(layers[i].nodes);
         if(len > mx)
            mx = len;
        }
      return mx;
      }

   int               MinBarsForHook(const ENUM_TIMEFRAMES tf) const
      {
      int by_depth = m_cfg.pivot_depth * 12 + 30;
      return MathMax(80,by_depth);
      }

   bool              HasEnoughBars(const ENUM_TIMEFRAMES tf) const
      {
      long sync = SeriesInfoInteger(m_symbol,tf,SERIES_SYNCHRONIZED);
      if(sync == 0)
         return false;

      int bars = iBars(m_symbol,tf);
      return (bars >= MinBarsForHook(tf));
      }

   int               MaxSequenceLenForTf(const ENUM_TIMEFRAMES tf) const
      {
      if(!HasEnoughBars(tf))
         return 0;

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(tf,NDS_NODE_VALLEY,0,valleys_raw);

      NdsHookSeqLayer peak_layers[];
      NdsHookSeqLayer valley_layers[];
      BuildNestedLayersFromEnd(peaks_raw,false,peak_layers);
      BuildNestedLayersFromEnd(valleys_raw,true,valley_layers);

      int peak_max = MaxLayerLength(peak_layers);
      int valley_max = MaxLayerLength(valley_layers);
      return MathMax(peak_max,valley_max);
      }

   void              CountLayerStatsInWindow(const NdsHookSeqLayer &layers[],const datetime from_t,const datetime to_t,int &out_layers,int &out_max_len) const
      {
      out_layers = 0;
      out_max_len = 0;
      int n = ArraySize(layers);
      for(int i = 0; i < n; i++)
        {
         int cnt = 0;
         int m = ArraySize(layers[i].nodes);
         for(int j = 0; j < m; j++)
           {
            datetime t = layers[i].nodes[j].bar_time;
            if(t < from_t)
               continue;
            if(to_t > 0 && t > to_t)
               continue;
            cnt++;
           }
         if(cnt > 0)
           {
            out_layers++;
            if(cnt > out_max_len)
               out_max_len = cnt;
            }
        }
      }

   datetime          HookSortTime(const NdsHookState &hook) const
      {
      if(hook.z.bar_time > 0)
         return hook.z.bar_time;
      if(hook.n3.bar_time > 0)
         return hook.n3.bar_time;
      if(hook.n2.bar_time > 0)
         return hook.n2.bar_time;
      return hook.n1.bar_time;
      }

   bool              IsSameHookIdentity(const NdsHookState &a,const NdsHookState &b) const
      {
      if(a.direction != b.direction)
         return false;
      if(a.scan_tf != b.scan_tf)
         return false;
      if(a.n1.bar_time != b.n1.bar_time)
         return false;
      if(a.n2.bar_time != b.n2.bar_time)
         return false;
      if(a.n3.bar_time != b.n3.bar_time)
         return false;
      if(a.z.bar_time != b.z.bar_time)
         return false;
      return true;
      }

   bool              IsHookExpiredNow(const NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return true;
      if(hook.start_anchor.bar_time <= 0 || hook.start_anchor.price <= 0.0)
         return true;

      // Hook expires when its start anchor is violated:
      // bullish hook: price breaks below start valley
      // bearish hook: price breaks above start peak
      return !IsAnchorUnbroken(hook.scan_tf,hook.start_anchor,hook.direction);
      }

   void              PurgeExpiredHistoryForSymbol(void) const
      {
      for(int i = ArraySize(g_nds_hook_hist_items) - 1; i >= 0; i--)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(!HasEnoughBars(g_nds_hook_hist_items[i].scan_tf))
           {
            int last_no_data = ArraySize(g_nds_hook_hist_items) - 1;
            if(i != last_no_data)
              {
               g_nds_hook_hist_items[i] = g_nds_hook_hist_items[last_no_data];
               g_nds_hook_hist_symbols[i] = g_nds_hook_hist_symbols[last_no_data];
              }
            ArrayResize(g_nds_hook_hist_items,last_no_data);
            ArrayResize(g_nds_hook_hist_symbols,last_no_data);
            continue;
           }
         if(!IsHookExpiredNow(g_nds_hook_hist_items[i]))
            continue;

         int last = ArraySize(g_nds_hook_hist_items) - 1;
         if(i != last)
           {
            g_nds_hook_hist_items[i] = g_nds_hook_hist_items[last];
            g_nds_hook_hist_symbols[i] = g_nds_hook_hist_symbols[last];
           }
         ArrayResize(g_nds_hook_hist_items,last);
         ArrayResize(g_nds_hook_hist_symbols,last);
        }
      }

   bool              ClassifyHookOpenClosed(NdsHookState &hook) const
      {
      hook.is_open = false;
      hook.is_closed = false;

      if(hook.start_anchor.bar_time <= 0 || !hook.start_unbroken)
         return false;

      // Not a hook yet when max sequence nodes is 0/1.
      if(hook.primary_max_len <= 1)
         return false;

      if(hook.primary_max_len == 2)
        {
         hook.is_open = true;
         return true;
        }

      if(hook.primary_max_len == 3 || hook.primary_max_len == 4)
        {
         hook.is_closed = true;
         return true;
        }

      // >4 should be resolved by TF escalation; treat as invalid at this TF.
      return false;
      }

   void              UpsertHookHistory(const NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return;
      if(IsHookExpiredNow(hook))
         return;

      int n = ArraySize(g_nds_hook_hist_items);
      for(int i = 0; i < n; i++)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(!IsSameHookIdentity(g_nds_hook_hist_items[i],hook))
            continue;

         g_nds_hook_hist_items[i] = hook;
         return;
        }

      ArrayResize(g_nds_hook_hist_items,n + 1);
      ArrayResize(g_nds_hook_hist_symbols,n + 1);
      g_nds_hook_hist_items[n] = hook;
      g_nds_hook_hist_symbols[n] = m_symbol;
      }

   void              StoreHistoryBatch(const NdsHookState &hooks[]) const
      {
      for(int i = 0; i < ArraySize(hooks); i++)
         UpsertHookHistory(hooks[i]);
      }

   void              HarvestHistoryForTf(const ENUM_TIMEFRAMES scan_tf) const
      {
      if(!HasEnoughBars(scan_tf))
         return;

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_VALLEY,0,valleys_raw);

      NdsHookState bull_hooks[];
      NdsHookState bear_hooks[];
      BuildDirectionHooksFromSequences(NDS_DIR_BULL,peaks_raw,valleys_raw,scan_tf,bull_hooks);
      BuildDirectionHooksFromSequences(NDS_DIR_BEAR,valleys_raw,peaks_raw,scan_tf,bear_hooks);

      NdsHookState valid_for_memory[];
      ArrayResize(valid_for_memory,0);
      for(int i = 0; i < ArraySize(bull_hooks); i++)
        {
         PushHook(bull_hooks[i],valid_for_memory);
        }
      for(int j = 0; j < ArraySize(bear_hooks); j++)
        {
         PushHook(bear_hooks[j],valid_for_memory);
        }
      StoreHistoryBatch(valid_for_memory);
      }

   void              HarvestHistoryAllAllowed(const ENUM_TIMEFRAMES skip_tf) const
      {
      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i = 0; i < 6; i++)
        {
         if(allowed[i] == skip_tf)
            continue;
         HarvestHistoryForTf(allowed[i]);
        }
      }

   int               BuildExtendAwareChain(const NdsNode &src[],const bool rising,NdsNode &chain[]) const
      {
      ArrayResize(chain,0);
      int n = ArraySize(src);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = src[i];
         int c = ArraySize(chain);
         if(c == 0)
           {
            ArrayResize(chain,1);
            chain[0] = nd;
            continue;
           }

         bool equal_price = MathAbs(nd.price - chain[c - 1].price) <= _Point * 0.1;
         if(equal_price)
           {
            chain[c - 1] = nd;
            continue;
           }

         bool extend = rising ? (nd.price > chain[c - 1].price) : (nd.price < chain[c - 1].price);
         if(extend)
           {
            ArrayResize(chain,c + 1);
            chain[c] = nd;
            continue;
           }

         while(ArraySize(chain) > 0)
           {
            int last = ArraySize(chain) - 1;
            bool conflict = rising ? (chain[last].price > nd.price) : (chain[last].price < nd.price);
            if(!conflict)
               break;
            ArrayResize(chain,last);
           }

         int m = ArraySize(chain);
         ArrayResize(chain,m + 1);
         chain[m] = nd;
        }
      return ArraySize(chain);
      }

   bool              FindOppositeInWindow(const NdsNode &nodes[],const datetime start_t,const datetime end_t,const int hook_dir,NdsNode &out_node) const
      {
      bool found = false;
      out_node = EmptyNode(NDS_NODE_NONE);
      int n = ArraySize(nodes);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = nodes[i];
         if(nd.bar_time <= start_t)
            continue;
         if(end_t > 0 && nd.bar_time >= end_t)
            continue;

         if(!found)
           {
            out_node = nd;
            found = true;
            continue;
           }

         if(hook_dir == NDS_DIR_BULL && nd.price < out_node.price)
            out_node = nd;
         if(hook_dir == NDS_DIR_BEAR && nd.price > out_node.price)
            out_node = nd;
        }
      return found;
      }

   int               FindNodeIndex(const NdsNode &nodes[],const NdsNode &target) const
      {
      int n = ArraySize(nodes);
      if(n <= 0 || target.bar_time <= 0)
         return -1;

      double eps = MathMax(_Point * 0.1,1e-12);
      int best = -1;
      double best_diff = 1e100;
      for(int i = 0; i < n; i++)
        {
         if(nodes[i].bar_time != target.bar_time)
            continue;
         double d = MathAbs(nodes[i].price - target.price);
         if(d < best_diff)
           {
            best_diff = d;
            best = i;
           }
        }
      if(best >= 0 && best_diff <= eps * 10.0)
         return best;

      // Fallback: closest older-or-equal node by time.
      for(int j = n - 1; j >= 0; j--)
        {
         if(nodes[j].bar_time <= target.bar_time)
            return j;
        }
      return -1;
      }

   bool              FindPreviousNodeBeforeTime(const NdsNode &nodes[],const datetime before_t,NdsNode &out_node) const
      {
      out_node = EmptyNode(NDS_NODE_NONE);
      if(before_t <= 0)
         return false;

      bool found = false;
      int n = ArraySize(nodes);
      for(int i = 0; i < n; i++)
        {
         if(nodes[i].bar_time >= before_t)
            break;
         out_node = nodes[i];
         found = true;
        }
      return found;
      }

   bool              FindBoundaryFromEnd(const NdsNode &nodes[],const int end_idx,const bool valley_mode,NdsNode &out_boundary) const
      {
      out_boundary = EmptyNode(NDS_NODE_NONE);
      int n = ArraySize(nodes);
      if(n <= 0 || end_idx <= 0 || end_idx >= n)
         return false;

      double eps = MathMax(_Point * 0.1,1e-12);
      double ref = nodes[end_idx].price;
      for(int i = end_idx - 1; i >= 0; i--)
        {
         double p = nodes[i].price;
         if(valley_mode)
           {
            // Sequence continuation in reverse scan: older valley must be higher.
            if(p > ref + eps)
              {
               ref = p;
               continue;
              }
            // First lower valley is the hook start anchor.
            if(p < ref - eps)
              {
               out_boundary = nodes[i];
               return true;
              }
           }
         else
           {
            // Sequence continuation in reverse scan: older peak must be lower.
            if(p < ref - eps)
              {
               ref = p;
               continue;
              }
            // First higher peak is the hook start anchor.
            if(p > ref + eps)
              {
               out_boundary = nodes[i];
               return true;
              }
           }
        }
      return false;
      }

   int               SliceNodesByTime(const NdsNode &src_old_to_new[],const datetime from_t,const datetime to_t,NdsNode &out_nodes[]) const
      {
      ArrayResize(out_nodes,0);
      int n = ArraySize(src_old_to_new);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = src_old_to_new[i];
         if(nd.bar_time < from_t)
            continue;
         if(to_t > 0 && nd.bar_time > to_t)
            continue;
         PushNode(nd,out_nodes);
        }
      return ArraySize(out_nodes);
      }

   void              CollectLayerStatsAndRepresentative(const NdsHookSeqLayer &layers[],const datetime from_t,const datetime to_t,
                                                        int &out_layers,int &out_max_len,NdsNode &out_rep_old_to_new[]) const
      {
      out_layers = 0;
      out_max_len = 0;
      ArrayResize(out_rep_old_to_new,0);

      datetime rep_last_time = 0;
      int n = ArraySize(layers);
      for(int i = 0; i < n; i++)
        {
         NdsNode ord_old_to_new[];
         ReverseNodes(layers[i].nodes,ord_old_to_new); // layer nodes are stored newest->oldest

         NdsNode window_nodes[];
         int len = SliceNodesByTime(ord_old_to_new,from_t,to_t,window_nodes);
         if(len <= 0)
            continue;

         out_layers++;
         datetime last_t = window_nodes[len - 1].bar_time;
         bool better = (len > out_max_len) || (len == out_max_len && last_t > rep_last_time);
         if(better)
           {
            out_max_len = len;
            rep_last_time = last_t;
            CopyNodes(window_nodes,out_rep_old_to_new);
           }
        }
      }

   void              SelectLast123FromSequence(const NdsNode &seq_old_to_new[],NdsNode &out_n1,NdsNode &out_n2,NdsNode &out_n3) const
      {
      out_n1 = EmptyNode(NDS_NODE_NONE);
      out_n2 = EmptyNode(NDS_NODE_NONE);
      out_n3 = EmptyNode(NDS_NODE_NONE);

      int n = ArraySize(seq_old_to_new);
      if(n <= 0)
         return;

      int base = (n >= 3 ? n - 3 : 0);
      out_n1 = seq_old_to_new[base];
      out_n2 = seq_old_to_new[MathMin(base + 1,n - 1)];
      out_n3 = seq_old_to_new[MathMin(base + 2,n - 1)];
      }

   bool              FindZAfterPrimary(const NdsNode &opposite_nodes[],const datetime after_t,const datetime to_t,const int hook_dir,NdsNode &out_z) const
      {
      out_z = EmptyNode((hook_dir == NDS_DIR_BULL) ? NDS_NODE_VALLEY : NDS_NODE_PEAK);
      bool found = false;
      double eps = MathMax(_Point * 0.1,1e-12);

      int n = ArraySize(opposite_nodes);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = opposite_nodes[i];
         if(nd.bar_time <= after_t)
            continue;
         if(to_t > 0 && nd.bar_time > to_t)
            continue;

         if(!found)
           {
            out_z = nd;
            found = true;
            continue;
           }

         if(hook_dir == NDS_DIR_BULL)
           {
            bool better = (nd.price < out_z.price - eps) || (MathAbs(nd.price - out_z.price) <= eps && nd.bar_time > out_z.bar_time);
            if(better)
               out_z = nd;
           }
         else
            if(hook_dir == NDS_DIR_BEAR)
              {
               bool better = (nd.price > out_z.price + eps) || (MathAbs(nd.price - out_z.price) <= eps && nd.bar_time > out_z.bar_time);
               if(better)
                  out_z = nd;
              }
        }
      return found;
      }

   bool              BuildHookFromSequenceWindow(const int hook_dir,const ENUM_TIMEFRAMES scan_tf,
                                                 const NdsNode &start_anchor,const NdsNode &end_secondary,
                                                 const NdsHookSeqLayer &primary_layers[],const NdsHookSeqLayer &secondary_layers[],
                                                 const NdsNode &opposite_nodes[],NdsHookState &out_hook) const
      {
      out_hook = EmptyHook();
      if(start_anchor.bar_time <= 0 || end_secondary.bar_time <= 0)
         return false;
      if(end_secondary.bar_time <= start_anchor.bar_time)
         return false;

      out_hook.direction = hook_dir;
      out_hook.scan_tf = scan_tf;
      out_hook.start_anchor = start_anchor;
      out_hook.start_unbroken = IsAnchorUnbroken(scan_tf,start_anchor,hook_dir);
      if(!out_hook.start_unbroken)
         return false;

      datetime from_t = start_anchor.bar_time;
      datetime to_t = end_secondary.bar_time;

      NdsNode primary_rep[];
      CollectLayerStatsAndRepresentative(primary_layers,from_t,to_t,out_hook.primary_layers,out_hook.primary_max_len,primary_rep);

      NdsNode secondary_rep_unused[];
      CollectLayerStatsAndRepresentative(secondary_layers,from_t,to_t,out_hook.secondary_layers,out_hook.secondary_max_len,secondary_rep_unused);

      if(out_hook.primary_max_len <= 1)
         return false;
      if(out_hook.primary_max_len > 4)
         return false;

      SelectLast123FromSequence(primary_rep,out_hook.n1,out_hook.n2,out_hook.n3);
      if(out_hook.n1.bar_time <= 0 || out_hook.n2.bar_time <= 0 || out_hook.n3.bar_time <= 0)
         return false;

      if(!FindZAfterPrimary(opposite_nodes,out_hook.n3.bar_time,to_t,hook_dir,out_hook.z))
         out_hook.z = end_secondary;
      if(out_hook.z.bar_time <= 0)
         out_hook.z = end_secondary;

      if(hook_dir == NDS_DIR_BULL)
        {
         if(out_hook.z.price >= out_hook.n3.price)
            return false;
         out_hook.level_86 = out_hook.n3.price - (out_hook.n3.price - out_hook.z.price) * 0.864;
        }
      else
         if(hook_dir == NDS_DIR_BEAR)
           {
            if(out_hook.z.price <= out_hook.n3.price)
               return false;
            out_hook.level_86 = out_hook.n3.price + (out_hook.z.price - out_hook.n3.price) * 0.864;
           }
         else
            return false;

      out_hook.hook_type = NDS_HOOK_UNKNOWN;
      out_hook.is_valid = ClassifyHookOpenClosed(out_hook);
      return out_hook.is_valid;
      }

   int               BuildDirectionHooksFromSequences(const int hook_dir,const NdsNode &primary_raw[],
                                                      const NdsNode &secondary_raw[],const ENUM_TIMEFRAMES scan_tf,
                                                      NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);

      int sec_n = ArraySize(secondary_raw);
      if(sec_n < 2 || ArraySize(primary_raw) <= 0)
         return 0;

      NdsHookSeqLayer primary_layers[];
      NdsHookSeqLayer secondary_layers[];
      if(hook_dir == NDS_DIR_BULL)
        {
         BuildNestedLayersFromEnd(primary_raw,false,primary_layers);   // bullish primary = peaks
         BuildNestedLayersFromEnd(secondary_raw,true,secondary_layers); // secondary = valleys
        }
      else
         if(hook_dir == NDS_DIR_BEAR)
           {
            BuildNestedLayersFromEnd(primary_raw,true,primary_layers);   // bearish primary = valleys
            BuildNestedLayersFromEnd(secondary_raw,false,secondary_layers); // secondary = peaks
           }
         else
            return 0;

      bool valley_mode = (hook_dir == NDS_DIR_BULL);
      for(int end_idx = 1; end_idx < sec_n; end_idx++)
        {
         NdsNode start_anchor;
         if(!FindBoundaryFromEnd(secondary_raw,end_idx,valley_mode,start_anchor))
            continue;

         NdsHookState hook;
         if(!BuildHookFromSequenceWindow(hook_dir,scan_tf,start_anchor,secondary_raw[end_idx],
                                         primary_layers,secondary_layers,secondary_raw,hook))
            continue;

         PushHook(hook,out_hooks);
        }

      return ArraySize(out_hooks);
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

   void              AnnotateHook(const ENUM_TIMEFRAMES scan_tf,const NdsNode &peaks_raw[],const NdsNode &valleys_raw[],NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return;

      hook.scan_tf = scan_tf;
      hook.start_anchor = EmptyNode((hook.direction == NDS_DIR_BULL) ? NDS_NODE_VALLEY : NDS_NODE_PEAK);
      hook.start_unbroken = false;
      hook.primary_layers = 0;
      hook.secondary_layers = 0;
      hook.primary_max_len = 0;
      hook.secondary_max_len = 0;

      bool has_anchor = false;
      if(hook.direction == NDS_DIR_BULL)
        {
         int z_idx = FindNodeIndex(valleys_raw,hook.z);
         if(z_idx >= 0)
            has_anchor = FindBoundaryFromEnd(valleys_raw,z_idx,true,hook.start_anchor);
         if(!has_anchor)
            has_anchor = FindPreviousNodeBeforeTime(valleys_raw,hook.n1.bar_time,hook.start_anchor);
        }
      else
         if(hook.direction == NDS_DIR_BEAR)
           {
            int z_idx = FindNodeIndex(peaks_raw,hook.z);
            if(z_idx >= 0)
               has_anchor = FindBoundaryFromEnd(peaks_raw,z_idx,false,hook.start_anchor);
            if(!has_anchor)
               has_anchor = FindPreviousNodeBeforeTime(peaks_raw,hook.n1.bar_time,hook.start_anchor);
           }

      if(has_anchor)
         hook.start_unbroken = IsAnchorUnbroken(scan_tf,hook.start_anchor,hook.direction);

      datetime from_t = (has_anchor ? hook.start_anchor.bar_time : hook.n1.bar_time);
      datetime to_t = (hook.z.bar_time > 0 ? hook.z.bar_time : hook.n3.bar_time);
      if(from_t <= 0)
         from_t = hook.n1.bar_time;

      NdsHookSeqLayer primary_layers[];
      NdsHookSeqLayer secondary_layers[];
      if(hook.direction == NDS_DIR_BULL)
        {
         BuildNestedLayersFromEnd(peaks_raw,false,primary_layers);
         BuildNestedLayersFromEnd(valleys_raw,true,secondary_layers);
        }
      else
         if(hook.direction == NDS_DIR_BEAR)
           {
            BuildNestedLayersFromEnd(valleys_raw,true,primary_layers);
            BuildNestedLayersFromEnd(peaks_raw,false,secondary_layers);
           }

      CountLayerStatsInWindow(primary_layers,from_t,to_t,hook.primary_layers,hook.primary_max_len);
      CountLayerStatsInWindow(secondary_layers,from_t,to_t,hook.secondary_layers,hook.secondary_max_len);
      }

   bool              BuildBullHook(const NdsNode &p1,const NdsNode &p2,const NdsNode &p3,
                                   const NdsNode &v12,const NdsNode &v23,const NdsNode &z,const ENUM_TIMEFRAMES scan_tf,
                                   NdsHookState &out_hook) const
      {
      if(!(p1.price < p2.price && p2.price < p3.price))
         return false;
      if(!(v12.price < p2.price && v23.price < p3.price))
         return false;
      if(z.bar_time <= p3.bar_time)
         return false;
      if(z.price >= p3.price)
         return false;

      out_hook = EmptyHook();
      out_hook.is_valid = true;
      out_hook.is_closed = true;
      out_hook.direction = NDS_DIR_BULL;
      out_hook.n1 = p1;
      out_hook.n2 = p2;
      out_hook.n3 = p3;
      out_hook.z = z;
      out_hook.scan_tf = scan_tf;
      out_hook.level_86 = out_hook.n3.price - (out_hook.n3.price - out_hook.z.price) * 0.864;

      if(v23.price >= v12.price)
         out_hook.hook_type = NDS_HOOK_A;
      else
         out_hook.hook_type = NDS_HOOK_B;

      return true;
      }

   bool              BuildBearHook(const NdsNode &v1,const NdsNode &v2,const NdsNode &v3,
                                   const NdsNode &p12,const NdsNode &p23,const NdsNode &z,const ENUM_TIMEFRAMES scan_tf,
                                   NdsHookState &out_hook) const
      {
      if(!(v1.price > v2.price && v2.price > v3.price))
         return false;
      if(!(p12.price > v2.price && p23.price > v3.price))
         return false;
      if(z.bar_time <= v3.bar_time)
         return false;
      if(z.price <= v3.price)
         return false;

      out_hook = EmptyHook();
      out_hook.is_valid = true;
      out_hook.is_closed = true;
      out_hook.direction = NDS_DIR_BEAR;
      out_hook.n1 = v1;
      out_hook.n2 = v2;
      out_hook.n3 = v3;
      out_hook.z = z;
      out_hook.scan_tf = scan_tf;
      out_hook.level_86 = out_hook.n3.price + (out_hook.z.price - out_hook.n3.price) * 0.864;

      if(p23.price <= p12.price)
         out_hook.hook_type = NDS_HOOK_A;
      else
         out_hook.hook_type = NDS_HOOK_B;

      return true;
      }

   int               BuildDirectionHooks(const int hook_dir,const NdsNode &primary_chain[],
                                         const NdsNode &opposite_nodes[],const ENUM_TIMEFRAMES scan_tf,NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);
      int n = ArraySize(primary_chain);
      if(n < 3)
         return 0;

      for(int i = 2; i < n; i++)
        {
         NdsNode a = primary_chain[i - 2];
         NdsNode b = primary_chain[i - 1];
         NdsNode c = primary_chain[i];
         datetime next_primary_t = (i + 1 < n ? primary_chain[i + 1].bar_time : 0);

         NdsNode opp12;
         NdsNode opp23;
         NdsNode z;
         if(!FindOppositeInWindow(opposite_nodes,a.bar_time,b.bar_time,hook_dir,opp12))
            continue;
         if(!FindOppositeInWindow(opposite_nodes,b.bar_time,c.bar_time,hook_dir,opp23))
            continue;
         if(!FindOppositeInWindow(opposite_nodes,c.bar_time,next_primary_t,hook_dir,z))
            continue;

         NdsHookState hook;
         bool ok = false;
         if(hook_dir == NDS_DIR_BULL)
            ok = BuildBullHook(a,b,c,opp12,opp23,z,scan_tf,hook);
         else
            if(hook_dir == NDS_DIR_BEAR)
               ok = BuildBearHook(a,b,c,opp12,opp23,z,scan_tf,hook);

         if(ok)
            PushHook(hook,out_hooks);
        }

      return ArraySize(out_hooks);
      }

   void              SortByCloseTime(NdsHookState &hooks[]) const
      {
      int n = ArraySize(hooks);
      for(int i = 0; i < n - 1; i++)
        {
         for(int j = i + 1; j < n; j++)
           {
            if(HookSortTime(hooks[i]) > HookSortTime(hooks[j]))
              {
               NdsHookState tmp = hooks[i];
               hooks[i] = hooks[j];
               hooks[j] = tmp;
              }
           }
        }
      }

   int               CompactHooksInternal(const NdsHookState &hooks[],NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);
      int n = ArraySize(hooks);
      for(int i = 0; i < n; i++)
        {
         NdsHookState h = hooks[i];
         int m = ArraySize(out_hooks);
         if(m == 0)
           {
            PushHook(h,out_hooks);
            continue;
           }

         NdsHookState last = out_hooks[m - 1];
         if(last.direction != h.direction)
           {
            PushHook(h,out_hooks);
            continue;
           }

         bool non_overlap = (h.n1.bar_time > last.z.bar_time);
         if(non_overlap)
            PushHook(h,out_hooks);
         else
            if(h.z.bar_time > last.z.bar_time)
               out_hooks[m - 1] = h;
        }
      return ArraySize(out_hooks);
      }

   int               TfMinutes(const ENUM_TIMEFRAMES tf) const
      {
      int sec = PeriodSeconds(tf);
      if(sec <= 0)
         return 0;
      return sec / 60;
      }

   bool              IsAllowedHookTf(const ENUM_TIMEFRAMES tf) const
      {
      return (tf == PERIOD_M1 ||
              tf == PERIOD_M5 ||
              tf == PERIOD_M15 ||
              tf == PERIOD_H1 ||
              tf == PERIOD_H4 ||
              tf == PERIOD_D1);
      }

   ENUM_TIMEFRAMES   NormalizeHookTf(const ENUM_TIMEFRAMES tf) const
      {
      if(IsAllowedHookTf(tf))
         return tf;

      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      int target = TfMinutes(tf);
      if(target <= 0)
         return PERIOD_M1;

      int best_i = 0;
      int best_diff = 2147483647;
      for(int i = 0; i < 6; i++)
        {
         int d = MathAbs(TfMinutes(allowed[i]) - target);
         if(d < best_diff)
           {
            best_diff = d;
            best_i = i;
           }
        }
      return allowed[best_i];
      }

   ENUM_TIMEFRAMES   NextAllowedHookTf(const ENUM_TIMEFRAMES tf) const
      {
      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i = 0; i < 5; i++)
        {
         if(allowed[i] == tf)
            return allowed[i + 1];
        }
      return tf;
      }

   ENUM_TIMEFRAMES   SelectScanTf(const ENUM_TIMEFRAMES requested_tf) const
      {
      ENUM_TIMEFRAMES tf = NormalizeHookTf(requested_tf);
      if(!HasEnoughBars(tf))
         return tf;

      // If any sequence grows beyond 4 nodes, move to next allowed TF.
      for(int guard = 0; guard < 6; guard++)
        {
         int max_len = MaxSequenceLenForTf(tf);
         if(max_len <= 4)
            break;

         ENUM_TIMEFRAMES next_tf = NextAllowedHookTf(tf);
         if(next_tf == tf)
            break;
         if(!HasEnoughBars(next_tf))
            break;
         tf = next_tf;
        }

      return tf;
      }

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_cfg = cfg;
      m_nodes.Configure(symbol,cfg);
      }

   ENUM_TIMEFRAMES   ResolveScanTf(const ENUM_TIMEFRAMES requested_tf) const
      {
      return SelectScanTf(requested_tf);
      }

   int               HistoryCount(const ENUM_TIMEFRAMES tf = PERIOD_CURRENT) const
      {
      PurgeExpiredHistoryForSymbol();
      int cnt = 0;
      for(int i = 0; i < ArraySize(g_nds_hook_hist_items); i++)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(tf != PERIOD_CURRENT && g_nds_hook_hist_items[i].scan_tf != tf)
            continue;
         cnt++;
        }
      return cnt;
      }

   int               GetHistory(NdsHookState &out_hooks[],const ENUM_TIMEFRAMES tf = PERIOD_CURRENT) const
      {
      PurgeExpiredHistoryForSymbol();
      ArrayResize(out_hooks,0);
      for(int i = 0; i < ArraySize(g_nds_hook_hist_items); i++)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(tf != PERIOD_CURRENT && g_nds_hook_hist_items[i].scan_tf != tf)
            continue;
         if(IsHookExpiredNow(g_nds_hook_hist_items[i]))
            continue;

         int n = ArraySize(out_hooks);
         ArrayResize(out_hooks,n + 1);
         out_hooks[n] = g_nds_hook_hist_items[i];
        }
      if(ArraySize(out_hooks) > 1)
         SortByCloseTime(out_hooks);
      return ArraySize(out_hooks);
      }

   int               CollectCompacted(const ENUM_TIMEFRAMES tf,NdsHookState &out_hooks[]) const
      {
      PurgeExpiredHistoryForSymbol();
      ArrayResize(out_hooks,0);

      ENUM_TIMEFRAMES scan_tf = SelectScanTf(tf);
      if(!HasEnoughBars(scan_tf))
         return 0;

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_VALLEY,0,valleys_raw);

      NdsHookState bull_hooks[];
      NdsHookState bear_hooks[];
      BuildDirectionHooksFromSequences(NDS_DIR_BULL,peaks_raw,valleys_raw,scan_tf,bull_hooks);
      BuildDirectionHooksFromSequences(NDS_DIR_BEAR,valleys_raw,peaks_raw,scan_tf,bear_hooks);

      NdsHookState merged[];
      NdsHookState valid_for_memory[];
      ArrayResize(merged,0);
      ArrayResize(valid_for_memory,0);
      for(int i = 0; i < ArraySize(bull_hooks); i++)
        {
         PushHook(bull_hooks[i],merged);
         PushHook(bull_hooks[i],valid_for_memory);
        }
      for(int j = 0; j < ArraySize(bear_hooks); j++)
        {
         PushHook(bear_hooks[j],merged);
         PushHook(bear_hooks[j],valid_for_memory);
        }

      StoreHistoryBatch(valid_for_memory);
      HarvestHistoryAllAllowed(scan_tf);
      if(ArraySize(merged) == 0)
         return 0;

      SortByCloseTime(merged);
      return CompactHooksInternal(merged,out_hooks);
      }

   NdsHookState      DetectLatest(const ENUM_TIMEFRAMES tf) const
      {
      NdsHookState hooks[];
      if(CollectCompacted(tf,hooks) <= 0)
         return EmptyHook();
      return hooks[ArraySize(hooks) - 1];
      }

   bool              FindLatestPair(const ENUM_TIMEFRAMES tf,NdsHookState &hook1,NdsHookState &hook2) const
      {
      NdsHookState hooks[];
      int n = CollectCompacted(tf,hooks);
      if(n < 2)
         return false;

      for(int i = n - 1; i >= 1; i--)
        {
         NdsHookState h2 = hooks[i];
         NdsHookState h1 = hooks[i - 1];
         if(!h1.is_closed || !h2.is_closed)
            continue;
         if(h1.direction != h2.direction)
            continue;
         if(HookSortTime(h1) >= h2.n1.bar_time)
            continue;
         hook1 = h1;
         hook2 = h2;
         return true;
        }

      return false;
      }
  };

#endif
