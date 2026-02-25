#ifndef __NDS_HOOK_SEQ_LAYER_MQH__
#define __NDS_HOOK_SEQ_LAYER_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"

struct NdsHookSeqLayer
  {
   NdsNode           nodes[]; // newest -> oldest
  };

#endif
