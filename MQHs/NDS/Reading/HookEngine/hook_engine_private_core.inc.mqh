   NdsNode           EmptyNode(const int kind) const
      {
      return m_state_factory.EmptyNode(kind);
      }

   NdsHookState      EmptyHook(void) const
      {
      return m_state_factory.EmptyHook();
      }

   void              PushHook(const NdsHookState &hook,NdsHookState &hooks[]) const
      {
      int n = ArraySize(hooks);
      ArrayResize(hooks,n + 1);
      hooks[n] = hook;
      }

   void              PushHookUniqueIdentity(const NdsHookState &hook,NdsHookState &hooks[]) const
      {
      if(!hook.is_valid)
         return;
      for(int i = 0; i < ArraySize(hooks); i++)
        {
         if(m_list_ops.IsSameHookIdentity(hooks[i],hook))
           {
            hooks[i] = hook;
            return;
           }
        }
      PushHook(hook,hooks);
      }

   void              PushHookUniqueAnchor(const NdsHookState &hook,NdsHookState &hooks[]) const
      {
      if(!hook.is_valid)
         return;
      for(int i = 0; i < ArraySize(hooks); i++)
        {
         if(!m_list_ops.IsSameHookAnchorIdentity(hooks[i],hook))
            continue;

         if(m_list_ops.PreferForSameAnchor(hooks[i],hook))
            hooks[i] = hook;
         return;
        }
      PushHook(hook,hooks);
      }

   void              CopyNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      m_node_ops.CopyNodes(src,dst);
      }

   void              ReverseNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      m_node_ops.ReverseNodes(src,dst);
      }

   void              PushNode(const NdsNode &nd,NdsNode &arr[]) const
      {
      m_node_ops.PushNode(nd,arr);
      }

   void              BuildNestedLayersFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,NdsHookSeqLayer &layers[]) const
      {
      m_layer_ops.BuildNestedLayersFromEnd(src_old_to_new,valley_mode,layers);
      }

   int               MinBarsForHook(const ENUM_TIMEFRAMES tf) const
      {
      return m_market_rules.MinBarsForHook(tf);
      }

   bool              HasEnoughBars(const ENUM_TIMEFRAMES tf) const
      {
      return m_market_rules.HasEnoughBars(tf);
      }

   bool              IsHookExpiredNow(const NdsHookState &hook) const
      {
      return m_market_rules.IsHookExpiredNow(hook);
      }
