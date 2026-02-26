   bool              LoadHookNodesForTf(const int hook_dir,const ENUM_TIMEFRAMES scan_tf,
                                        NdsNode &primary_raw[],NdsNode &secondary_raw[],NdsNode &opposite_nodes[],
                                        NdsHookSeqLayer &primary_layers[],NdsHookSeqLayer &secondary_layers[]) const
      {
      if(!HasEnoughBars(scan_tf))
         return false;

      NdsNodeSet node_set;
      NdsNodeSetOps node_set_ops;
      m_nodes.DetectNodeSetAtTf(scan_tf,node_set,0);
      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      node_set_ops.ToArrays(node_set,peaks_raw,valleys_raw);

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
                                                 const int promotions_so_far,datetime &out_mapped_end_time,
                                                 NdsHookState &out_hook) const
      {
      out_hook = EmptyHook();
      out_mapped_end_time = 0;

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
      out_mapped_end_time = secondary_raw[end_idx].bar_time;

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

   bool              ResolveOwnedHookTfForEndNode(const int hook_dir,const datetime initial_end_time,
                                                  const ENUM_TIMEFRAMES initial_tf,
                                                  ENUM_TIMEFRAMES &out_owned_tf,int &out_promotions,
                                                  datetime &out_owned_end_time) const
      {
      out_owned_tf = initial_tf;
      out_promotions = 0;
      out_owned_end_time = 0;
      if(initial_end_time <= 0)
         return false;

      ENUM_TIMEFRAMES tf = initial_tf;
      datetime carry_end_time = initial_end_time;
      int promotions = 0;

      for(int guard = 0; guard < 6; guard++)
        {
         datetime mapped_end_time = 0;
         NdsHookState cand;
         if(!BuildOwnedHookCandidateAtTf(hook_dir,tf,carry_end_time,initial_tf,promotions,mapped_end_time,cand))
            return false;

         int seq_max = MathMax(cand.primary_max_len,cand.secondary_max_len);
         if(seq_max > 4)
           {
            ENUM_TIMEFRAMES next_tf = m_tf_policy.NextAllowedHookTf(tf);
            if(next_tf == tf)
               return false;
            if(!HasEnoughBars(next_tf))
               return false;

            carry_end_time = mapped_end_time; // exact node path across TF promotion
            tf = next_tf;
            promotions++;
            continue;
           }

         if(!cand.is_valid)
            return false;

         out_owned_tf = tf;
         out_promotions = promotions;
         out_owned_end_time = mapped_end_time;
         return true;
        }

      return false;
      }

   bool              PromoteHookToOwnedTf(const int hook_dir,const NdsNode &initial_end_secondary,const ENUM_TIMEFRAMES initial_tf,
                                          NdsHookState &owned_hook) const
      {
      owned_hook = EmptyHook();
      if(initial_end_secondary.bar_time <= 0)
         return false;

      ENUM_TIMEFRAMES owned_tf = initial_tf;
      int promotions = 0;
      datetime owned_end_time = 0;
      if(!ResolveOwnedHookTfForEndNode(hook_dir,initial_end_secondary.bar_time,initial_tf,
                                       owned_tf,promotions,owned_end_time))
         return false;

      datetime final_mapped_end = 0;
      if(!BuildOwnedHookCandidateAtTf(hook_dir,owned_tf,owned_end_time,initial_tf,promotions,final_mapped_end,owned_hook))
         return false;

      return owned_hook.is_valid;
      }
