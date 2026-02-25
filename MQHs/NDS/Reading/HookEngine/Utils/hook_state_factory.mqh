#ifndef __NDS_HOOK_STATE_FACTORY_MQH__
#define __NDS_HOOK_STATE_FACTORY_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"

class NdsHookStateFactory
  {
public:
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
      hook.seed_tf = PERIOD_CURRENT;
      hook.ownership_promotions = 0;
      hook.hook_seq_max = 0;
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
  };

#endif
