#ifndef __NDS_HOOK_ENGINE_MQH__
#define __NDS_HOOK_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "node_detector.mqh"

class NdsHookEngine
  {
private:
   string            m_symbol;
   NdsConfig         m_cfg;
   NdsNodeDetector   m_nodes;

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
      hook.n1 = EmptyNode(NDS_NODE_NONE);
      hook.n2 = EmptyNode(NDS_NODE_NONE);
      hook.n3 = EmptyNode(NDS_NODE_NONE);
      hook.z = EmptyNode(NDS_NODE_NONE);
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

   bool              BuildBullHook(const NdsNode &p1,const NdsNode &p2,const NdsNode &p3,
                                   const NdsNode &v12,const NdsNode &v23,const NdsNode &z,
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
      out_hook.level_86 = out_hook.n3.price - (out_hook.n3.price - out_hook.z.price) * 0.864;

      if(v23.price >= v12.price)
         out_hook.hook_type = NDS_HOOK_A;
      else
         out_hook.hook_type = NDS_HOOK_B;

      return true;
      }

   bool              BuildBearHook(const NdsNode &v1,const NdsNode &v2,const NdsNode &v3,
                                   const NdsNode &p12,const NdsNode &p23,const NdsNode &z,
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
      out_hook.level_86 = out_hook.n3.price + (out_hook.z.price - out_hook.n3.price) * 0.864;

      if(p23.price <= p12.price)
         out_hook.hook_type = NDS_HOOK_A;
      else
         out_hook.hook_type = NDS_HOOK_B;

      return true;
      }

   int               BuildDirectionHooks(const int hook_dir,const NdsNode &primary_chain[],
                                         const NdsNode &opposite_nodes[],NdsHookState &out_hooks[]) const
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
            ok = BuildBullHook(a,b,c,opp12,opp23,z,hook);
         else
            if(hook_dir == NDS_DIR_BEAR)
               ok = BuildBearHook(a,b,c,opp12,opp23,z,hook);

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
            if(hooks[i].z.bar_time > hooks[j].z.bar_time)
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

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_cfg = cfg;
      m_nodes.Configure(symbol,cfg);
      }

   int               CollectCompacted(const ENUM_TIMEFRAMES tf,NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(tf,NDS_NODE_VALLEY,0,valleys_raw);

      NdsNode peaks_chain[];
      NdsNode valleys_chain[];
      BuildExtendAwareChain(peaks_raw,true,peaks_chain);
      BuildExtendAwareChain(valleys_raw,false,valleys_chain);

      NdsHookState bull_hooks[];
      NdsHookState bear_hooks[];
      BuildDirectionHooks(NDS_DIR_BULL,peaks_chain,valleys_raw,bull_hooks);
      BuildDirectionHooks(NDS_DIR_BEAR,valleys_chain,peaks_raw,bear_hooks);

      NdsHookState merged[];
      ArrayResize(merged,0);
      for(int i = 0; i < ArraySize(bull_hooks); i++)
         PushHook(bull_hooks[i],merged);
      for(int j = 0; j < ArraySize(bear_hooks); j++)
         PushHook(bear_hooks[j],merged);
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
         if(h1.direction != h2.direction)
            continue;
         if(h1.z.bar_time >= h2.n1.bar_time)
            continue;
         hook1 = h1;
         hook2 = h2;
         return true;
        }

      return false;
      }
  };

#endif
