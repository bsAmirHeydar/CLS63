#ifndef __NDS_TYPES_MQH__
#define __NDS_TYPES_MQH__

enum NdsDirection
  {
   NDS_DIR_NONE = 0,
   NDS_DIR_BULL = 1,
   NDS_DIR_BEAR = -1
  };

enum NdsNodeKind
  {
   NDS_NODE_NONE = 0,
   NDS_NODE_PEAK = 1,
   NDS_NODE_VALLEY = -1
  };

enum NdsHookType
  {
   NDS_HOOK_UNKNOWN = 0,
   NDS_HOOK_A = 1,
   NDS_HOOK_B = 2
  };

enum NdsCyclePhase
  {
   NDS_PHASE_UNKNOWN = 0,
   NDS_PHASE_HOOK_1 = 1,
   NDS_PHASE_HOOK_2 = 2,
   NDS_PHASE_RALLY_1 = 3,
   NDS_PHASE_RALLY_2 = 4,
   NDS_PHASE_FLAG = 5,
   NDS_PHASE_CLOSE = 6
  };

enum NdsRuleStatus
  {
   NDS_RULE_FAIL = 0,
   NDS_RULE_PASS = 1,
   NDS_RULE_SKIP = 2
  };

enum NdsOrderMode
  {
   NDS_ORDER_MARKET = 0,
   NDS_ORDER_LIMIT = 1,
   NDS_ORDER_STOP = 2
  };

#endif
