#ifndef __NDS_HOOK_ENGINE_MQH__
#define __NDS_HOOK_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "node_detector.mqh"
#include "sequence_engine.mqh"
#include "HookEngine\\Types\\hook_seq_layer.mqh"
#include "HookEngine\\hook_tf_policy.mqh"
#include "HookEngine\\hook_list_ops.mqh"
#include "HookEngine\\hook_close_policy.mqh"
#include "HookEngine\\hook_seed_update_tracker.mqh"
#include "HookEngine\\Store\\hook_history_store.mqh"
#include "HookEngine\\Policies\\hook_market_rules.mqh"
#include "HookEngine\\Utils\\hook_state_factory.mqh"
#include "HookEngine\\Utils\\hook_node_ops.mqh"
#include "HookEngine\\Utils\\hook_layer_ops.mqh"
#include "HookEngine\\Utils\\hook_boundary_ops.mqh"

class NdsHookEngine
  {
private:
   string            m_symbol;
   NdsConfig         m_cfg;
   NdsNodeDetector   m_nodes;
   NdsHookTfPolicy   m_tf_policy;
   NdsHookListOps    m_list_ops;
   NdsHookClosePolicy m_close_policy;
   NdsHookSeedUpdateTracker m_seed_tracker;
   NdsHookHistoryStore m_history_store;
   NdsHookMarketRules m_market_rules;
   NdsHookStateFactory m_state_factory;
   NdsHookNodeOps   m_node_ops;
   NdsHookLayerOps  m_layer_ops;
   NdsHookBoundaryOps m_boundary_ops;

#include "HookEngine\\hook_engine_private_core.inc.mqh"
#include "HookEngine\\hook_engine_private_state_history.inc.mqh"
#include "HookEngine\\hook_engine_private_build.inc.mqh"

public:
#include "HookEngine\\hook_engine_public_api.inc.mqh"
  };

#endif
