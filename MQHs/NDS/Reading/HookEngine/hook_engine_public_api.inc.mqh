   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_cfg = cfg;
      m_nodes.Configure(symbol,cfg);
      m_market_rules.Configure(symbol,cfg);
      m_close_policy.Configure(symbol,cfg);
      m_seed_tracker.Configure(symbol);
      m_history_store.Configure(symbol,cfg);
      }

   int               HistoryCount(const ENUM_TIMEFRAMES tf = PERIOD_CURRENT) const
      {
      return m_history_store.HistoryCount(tf);
      }

   int               GetHistory(NdsHookState &out_hooks[],const ENUM_TIMEFRAMES tf = PERIOD_CURRENT) const
      {
      return m_history_store.GetHistory(out_hooks,tf);
      }

   int               CollectCompacted(const ENUM_TIMEFRAMES tf,NdsHookState &out_hooks[]) const
      {
      PurgeExpiredHistoryForSymbol();
      ArrayResize(out_hooks,0);

      NdsHookState merged[];
      NdsHookState valid_for_memory[];
      ArrayResize(merged,0);
      ArrayResize(valid_for_memory,0);

      ENUM_TIMEFRAMES base_tf = m_tf_policy.NormalizeHookTf(tf);
      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      bool started = false;
      for(int a = 0; a < 6; a++)
        {
         ENUM_TIMEFRAMES scan_tf = allowed[a];
         if(scan_tf == base_tf)
            started = true;
         if(!started)
            continue;
         if(!HasEnoughBars(scan_tf))
            continue;

         NdsNode peaks_raw[];
         NdsNode valleys_raw[];
         m_nodes.FindRecentNodes(scan_tf,NDS_NODE_PEAK,0,peaks_raw);
         m_nodes.FindRecentNodes(scan_tf,NDS_NODE_VALLEY,0,valleys_raw);

         NdsHookState bull_hooks[];
         NdsHookState bear_hooks[];
         BuildDirectionHooksFromSequences(NDS_DIR_BULL,peaks_raw,valleys_raw,scan_tf,bull_hooks);
         BuildDirectionHooksFromSequences(NDS_DIR_BEAR,valleys_raw,peaks_raw,scan_tf,bear_hooks);

         for(int i = 0; i < ArraySize(bull_hooks); i++)
           {
            PushHookUniqueIdentity(bull_hooks[i],merged);
            PushHookUniqueIdentity(bull_hooks[i],valid_for_memory);
           }
         for(int j = 0; j < ArraySize(bear_hooks); j++)
           {
            PushHookUniqueIdentity(bear_hooks[j],merged);
            PushHookUniqueIdentity(bear_hooks[j],valid_for_memory);
           }
        }

      StoreHistoryBatch(valid_for_memory);
      HarvestHistoryAllowedBelow(base_tf);
      if(ArraySize(merged) == 0)
         return 0;

      m_list_ops.SortByCloseTime(merged);
      return m_list_ops.CompactHooksInternal(merged,out_hooks);
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
         if(h1.scan_tf != h2.scan_tf)
            continue;
         if(m_list_ops.HookSortTime(h1) >= h2.n1.bar_time)
            continue;
         hook1 = h1;
         hook2 = h2;
         return true;
        }

      return false;
      }
