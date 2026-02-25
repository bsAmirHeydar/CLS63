#ifndef __NDS_CYCLE_ASSEMBLER_MQH__
#define __NDS_CYCLE_ASSEMBLER_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "hook_engine.mqh"
#include "rally_detector.mqh"

class NdsCycleAssembler
  {
private:
   NdsConfig         m_cfg;
   NdsHookEngine     m_hook_engine;
   NdsRallyDetector  m_rally_detector;

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

   NdsRallyState     EmptyRally(void) const
      {
      NdsRallyState rally;
      rally.is_valid = false;
      rally.direction = NDS_DIR_NONE;
      rally.start = EmptyNode(NDS_NODE_NONE);
      rally.end = EmptyNode(NDS_NODE_NONE);
      rally.length = 0.0;
      return rally;
      }

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_cfg = cfg;
      m_hook_engine.Configure(symbol,cfg);
      m_rally_detector.Configure(symbol);
      }

   NdsCycleState     Assemble(const NdsFlagState &ltf_flag) const
      {
      NdsCycleState cycle;
      cycle.is_valid = false;
      cycle.direction = NDS_DIR_NONE;
      cycle.phase = NDS_PHASE_UNKNOWN;
      cycle.hooks_count = 0;
      cycle.rallies_count = 0;
      cycle.has_flag = ltf_flag.is_valid;
      cycle.has_hook2 = false;
      cycle.has_rally_after_hook2 = false;
      cycle.hook1 = EmptyHook();
      cycle.hook2 = EmptyHook();
      cycle.rally_after_hook2 = EmptyRally();

      NdsHookState latest = m_hook_engine.DetectLatest(m_cfg.htf);
      if(!latest.is_valid)
         return cycle;

      cycle.is_valid = true;
      cycle.hooks_count = 1;
      cycle.phase = NDS_PHASE_HOOK_1;
      cycle.direction = latest.direction;
      cycle.hook1 = latest;

      NdsHookState hook1;
      NdsHookState hook2;
      if(!m_hook_engine.FindLatestPair(m_cfg.htf,hook1,hook2))
         return cycle;

      cycle.has_hook2 = true;
      cycle.hooks_count = 2;
      cycle.direction = hook2.direction;
      cycle.phase = NDS_PHASE_HOOK_2;
      cycle.hook1 = hook1;
      cycle.hook2 = hook2;

      ENUM_TIMEFRAMES rally_tf = (hook2.scan_tf != PERIOD_CURRENT ? hook2.scan_tf : m_cfg.htf);
      NdsRallyState rally = m_rally_detector.Detect(rally_tf,hook2);
      cycle.rally_after_hook2 = rally;
      cycle.has_rally_after_hook2 = rally.is_valid;
      cycle.rallies_count = rally.is_valid ? 1 : 0;

      if(rally.is_valid)
         cycle.phase = cycle.has_flag ? NDS_PHASE_FLAG : NDS_PHASE_RALLY_1;

      return cycle;
      }
  };

#endif
