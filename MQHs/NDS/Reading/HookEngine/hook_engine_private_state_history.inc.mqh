   void              PurgeExpiredHistoryForSymbol(void) const
      {
      m_history_store.PurgeExpiredHistoryForSymbol();
      }

   void              ReplaceHistoryForSeedDirection(const ENUM_TIMEFRAMES seed_tf,const int hook_dir,const NdsHookState &hooks[]) const
      {
      m_history_store.ReplaceHistoryForSeedDirection(seed_tf,hook_dir,hooks);
      }

   bool              LoadHookNodesForTf(const int hook_dir,const ENUM_TIMEFRAMES scan_tf,
                                        NdsNode &primary_raw[],NdsNode &secondary_raw[],NdsNode &opposite_nodes[],
                                        NdsHookSeqLayer &primary_layers[],NdsHookSeqLayer &secondary_layers[]) const
      {
      if(!HasEnoughBars(scan_tf))
         return false;

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_VALLEY,0,valleys_raw);

      if(hook_dir == NDS_DIR_BULL)
        {
         CopyNodes(peaks_raw,primary_raw);
         CopyNodes(valleys_raw,secondary_raw);
         CopyNodes(valleys_raw,opposite_nodes);
         BuildNestedLayersFromEnd(primary_raw,false,primary_layers);
         BuildNestedLayersFromEnd(secondary_raw,true,secondary_layers);
         return true;
        }

      if(hook_dir == NDS_DIR_BEAR)
        {
         CopyNodes(valleys_raw,primary_raw);
         CopyNodes(peaks_raw,secondary_raw);
         CopyNodes(peaks_raw,opposite_nodes);
         BuildNestedLayersFromEnd(primary_raw,true,primary_layers);
         BuildNestedLayersFromEnd(secondary_raw,false,secondary_layers);
         return true;
        }

      return false;
      }

   bool              BuildOwnedHookCandidateAtTf(const int hook_dir,const ENUM_TIMEFRAMES scan_tf,
                                                 const datetime target_end_time,const ENUM_TIMEFRAMES seed_tf,
                                                 const int promotions_so_far,NdsHookState &out_hook) const
      {
      out_hook = EmptyHook();

      NdsNode primary_raw[];
      NdsNode secondary_raw[];
      NdsNode opposite_nodes[];
      NdsHookSeqLayer primary_layers[];
      NdsHookSeqLayer secondary_layers[];
      if(!LoadHookNodesForTf(hook_dir,scan_tf,primary_raw,secondary_raw,opposite_nodes,primary_layers,secondary_layers))
         return false;

      int end_idx = FindLastNodeIndexAtOrBeforeTime(secondary_raw,target_end_time);
      if(end_idx < 1)
         return false;

      bool valley_mode = (hook_dir == NDS_DIR_BULL);
      NdsNode start_anchor;
      if(!FindBoundaryFromEnd(secondary_raw,end_idx,valley_mode,start_anchor))
         return false;

      if(!BuildHookFromSequenceWindow(hook_dir,scan_tf,start_anchor,secondary_raw[end_idx],
                                      primary_layers,secondary_layers,opposite_nodes,out_hook))
         return false;

      out_hook.seed_tf = seed_tf;
      out_hook.ownership_promotions = promotions_so_far;
      out_hook.hook_seq_max = MathMax(out_hook.primary_max_len,out_hook.secondary_max_len);
      return true;
      }

   bool              PromoteHookToOwnedTf(const int hook_dir,const NdsNode &initial_start_anchor,
                                          const NdsNode &initial_end_secondary,const ENUM_TIMEFRAMES initial_tf,
                                          NdsHookState &owned_hook) const
      {
      owned_hook = EmptyHook();
      if(initial_end_secondary.bar_time <= 0)
         return false;
      if(initial_start_anchor.bar_time > 0 && initial_end_secondary.bar_time <= initial_start_anchor.bar_time)
         return false;

      ENUM_TIMEFRAMES tf = initial_tf;
      datetime carry_end_time = initial_end_secondary.bar_time;
      int promotions = 0;

      for(int guard = 0; guard < 6; guard++)
        {
         NdsHookState cand;
         if(!BuildOwnedHookCandidateAtTf(hook_dir,tf,carry_end_time,initial_tf,promotions,cand))
            return false;

         int seq_max = MathMax(cand.primary_max_len,cand.secondary_max_len);
         cand.hook_seq_max = seq_max;

         if(seq_max > 4)
           {
            ENUM_TIMEFRAMES next_tf = m_tf_policy.NextAllowedHookTf(tf);
            if(next_tf == tf)
               return false;
            if(!HasEnoughBars(next_tf))
               return false;

            tf = next_tf;
            promotions++;
            continue;
           }

         if(!cand.is_valid)
            return false;

         owned_hook = cand;
         return true;
        }

      return false;
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

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_PEAK,0,peaks_raw);
      m_nodes.FindRecentNodes(scan_tf,NDS_NODE_VALLEY,0,valleys_raw);

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

