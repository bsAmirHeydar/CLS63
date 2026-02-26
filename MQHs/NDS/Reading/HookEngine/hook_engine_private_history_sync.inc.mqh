   void              PurgeExpiredHistoryForSymbol(void) const
      {
      m_history_store.PurgeExpiredHistoryForSymbol();
      }

   void              ReplaceHistoryForSeedDirection(const ENUM_TIMEFRAMES seed_tf,const int hook_dir,const NdsHookState &hooks[]) const
      {
      m_history_store.ReplaceHistoryForSeedDirection(seed_tf,hook_dir,hooks);
      }

   void              UpsertHookHistory(const NdsHookState &hook) const
      {
      m_history_store.UpsertHookHistory(hook);
      }

   void              StoreHistoryBatch(const NdsHookState &hooks[]) const
      {
      m_history_store.StoreHistoryBatch(hooks);
      }

   void              HarvestHistoryForTf(const ENUM_TIMEFRAMES scan_tf) const
      {
      if(!HasEnoughBars(scan_tf))
         return;

      NdsNodeSet node_set;
      NdsNodeSetOps node_set_ops;
      m_nodes.DetectNodeSetAtTf(scan_tf,node_set,0);
      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      node_set_ops.ToArrays(node_set,peaks_raw,valleys_raw);

      bool bull_update = false;
      bool bear_update = false;
      m_seed_tracker.EvalAndCommit(scan_tf,peaks_raw,valleys_raw,bull_update,bear_update);

      if(bull_update)
        {
         NdsHookState bull_hooks[];
         BuildDirectionHooksFromSequences(NDS_DIR_BULL,peaks_raw,valleys_raw,scan_tf,bull_hooks);
         ReplaceHistoryForSeedDirection(scan_tf,NDS_DIR_BULL,bull_hooks);
        }

      if(bear_update)
        {
         NdsHookState bear_hooks[];
         BuildDirectionHooksFromSequences(NDS_DIR_BEAR,valleys_raw,peaks_raw,scan_tf,bear_hooks);
         ReplaceHistoryForSeedDirection(scan_tf,NDS_DIR_BEAR,bear_hooks);
        }
      }

   void              HarvestHistoryAllowedBelow(const ENUM_TIMEFRAMES base_tf) const
      {
      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i = 0; i < 6; i++)
        {
         if(allowed[i] == base_tf)
            break;
         HarvestHistoryForTf(allowed[i]);
        }
      }
