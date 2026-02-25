   int               FindLastNodeIndexAtOrBeforeTime(const NdsNode &nodes[],const datetime t) const
      {
      return m_node_ops.FindLastNodeIndexAtOrBeforeTime(nodes,t);
      }

   bool              FindBoundaryFromEnd(const NdsNode &nodes[],const int end_idx,const bool valley_mode,NdsNode &out_boundary) const
      {
      return m_boundary_ops.FindBoundaryFromEnd(nodes,end_idx,valley_mode,out_boundary);
      }

   int               SliceNodesByTime(const NdsNode &src_old_to_new[],const datetime from_t,const datetime to_t,NdsNode &out_nodes[]) const
      {
      return m_node_ops.SliceNodesByTime(src_old_to_new,from_t,to_t,out_nodes);
      }

   void              CollectLayerStatsAndRepresentative(const NdsHookSeqLayer &layers[],const datetime from_t,const datetime to_t,
                                                        int &out_layers,int &out_max_len,NdsNode &out_rep_old_to_new[]) const
      {
      m_layer_ops.CollectLayerStatsAndRepresentative(layers,from_t,to_t,out_layers,out_max_len,out_rep_old_to_new);
      }

   void              SelectLast123FromSequence(const NdsNode &seq_old_to_new[],NdsNode &out_n1,NdsNode &out_n2,NdsNode &out_n3) const
      {
      m_node_ops.SelectLast123FromSequence(seq_old_to_new,out_n1,out_n2,out_n3);
      }

   bool              FindZAfterPrimary(const NdsNode &opposite_nodes[],const datetime after_t,const datetime to_t,const int hook_dir,NdsNode &out_z) const
      {
      return m_boundary_ops.FindZAfterPrimary(opposite_nodes,after_t,to_t,hook_dir,out_z);
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
      out_hook.seed_tf = scan_tf;
      out_hook.ownership_promotions = 0;
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
      out_hook.is_valid = m_close_policy.ClassifyHookOpenClosed(out_hook);
      out_hook.hook_seq_max = MathMax(out_hook.primary_max_len,out_hook.secondary_max_len);
      return true;
      }

   int               BuildDirectionHooksFromSequences(const int hook_dir,const NdsNode &primary_raw[],
                                                      const NdsNode &secondary_raw[],const ENUM_TIMEFRAMES scan_tf,
                                                      NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);

      int sec_n = ArraySize(secondary_raw);
      if(sec_n < 2 || ArraySize(primary_raw) <= 0)
         return 0;

      if(!(hook_dir == NDS_DIR_BULL || hook_dir == NDS_DIR_BEAR))
         return 0;

      bool valley_mode = (hook_dir == NDS_DIR_BULL);
      for(int end_idx = 1; end_idx < sec_n; end_idx++)
        {
         NdsNode start_anchor;
         if(!FindBoundaryFromEnd(secondary_raw,end_idx,valley_mode,start_anchor))
            continue;

         NdsHookState hook;
         if(!PromoteHookToOwnedTf(hook_dir,start_anchor,secondary_raw[end_idx],scan_tf,hook))
            continue;

         PushHookUniqueIdentity(hook,out_hooks);
        }

      return ArraySize(out_hooks);
      }

   bool              IsAnchorUnbroken(const ENUM_TIMEFRAMES tf,const NdsNode &anchor,const int dir) const
      {
      return m_market_rules.IsAnchorUnbroken(tf,anchor,dir);
      }

