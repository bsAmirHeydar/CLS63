#ifndef __NDS_VISUAL_DEBUG_MQH__
#define __NDS_VISUAL_DEBUG_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"
#include "..\\Infrastructure\\diagnostics.mqh"
#include "..\\Reading\\node_detector.mqh"
#include "..\\Reading\\Common\\nds_node_set_ops.mqh"
#include "..\\Reading\\hook_engine.mqh"

struct NdsDebugNodeLayer
  {
   NdsNode           nodes[]; // stored as newest -> oldest
  };

class NdsVisualDebug
  {
private:
   string            m_prefix;
   NdsConfig         m_cfg;

#include "VisualDebug\\visual_debug_private_primitives.inc.mqh"
#include "VisualDebug\\visual_debug_private_hook_plot.inc.mqh"
#include "VisualDebug\\visual_debug_private_node_plot.inc.mqh"
#include "VisualDebug\\visual_debug_private_sequence_plot.inc.mqh"

public:
#include "VisualDebug\\visual_debug_public_api.inc.mqh"
  };

#endif
