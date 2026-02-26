#ifndef __NDS_HOOK_HISTORY_STORE_MQH__
#define __NDS_HOOK_HISTORY_STORE_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\..\\Core\\nds_config.mqh"
#include "..\\hook_list_ops.mqh"
#include "..\\Policies\\hook_market_rules.mqh"

string g_nds_hook_hist_symbols[];
NdsHookState g_nds_hook_hist_items[];

class NdsHookHistoryStore
  {
private:
   string            m_symbol;
   NdsHookListOps    m_list_ops;
   NdsHookMarketRules m_market_rules;

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_market_rules.Configure(symbol,cfg);
      }

   void              PurgeExpiredHistoryForSymbol(void) const
      {
      for(int i = ArraySize(g_nds_hook_hist_items) - 1; i >= 0; i--)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(!m_market_rules.HasEnoughBars(g_nds_hook_hist_items[i].scan_tf))
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
         if(!m_market_rules.IsHookExpiredNow(g_nds_hook_hist_items[i]))
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

   void              ReplaceHistoryForSeedDirection(const ENUM_TIMEFRAMES seed_tf,const int hook_dir,const NdsHookState &hooks[]) const
      {
      for(int i = ArraySize(g_nds_hook_hist_items) - 1; i >= 0; i--)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(g_nds_hook_hist_items[i].direction != hook_dir)
            continue;
         if(g_nds_hook_hist_items[i].seed_tf != seed_tf)
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

      for(int j = 0; j < ArraySize(hooks); j++)
        {
         if(!hooks[j].is_valid)
            continue;
         if(hooks[j].direction != hook_dir)
            continue;
         if(hooks[j].seed_tf != seed_tf)
            continue;
         UpsertHookHistory(hooks[j]);
        }
      }

   void              UpsertHookHistory(const NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return;
      if(m_market_rules.IsHookExpiredNow(hook))
         return;

      int n = ArraySize(g_nds_hook_hist_items);
      for(int i = 0; i < n; i++)
        {
         if(g_nds_hook_hist_symbols[i] != m_symbol)
            continue;
         if(!m_list_ops.IsSameHookIdentity(g_nds_hook_hist_items[i],hook))
           {
            if(m_list_ops.IsSameHookAnchorIdentity(g_nds_hook_hist_items[i],hook))
              {
               if(m_list_ops.PreferForSameAnchor(g_nds_hook_hist_items[i],hook))
                  g_nds_hook_hist_items[i] = hook;
               return;
              }
            continue;
           }

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
         if(m_market_rules.IsHookExpiredNow(g_nds_hook_hist_items[i]))
            continue;

         int n = ArraySize(out_hooks);
         ArrayResize(out_hooks,n + 1);
         out_hooks[n] = g_nds_hook_hist_items[i];
        }
      if(ArraySize(out_hooks) > 1)
         m_list_ops.SortByCloseTime(out_hooks);
      return ArraySize(out_hooks);
      }
  };

#endif
