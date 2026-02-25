#ifndef __NDS_SEQUENCE_STATE_FACTORY_MQH__
#define __NDS_SEQUENCE_STATE_FACTORY_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\Common\\nds_node_factory.mqh"

class NdsSequenceStateFactory
  {
private:
   NdsNodeFactory    m_node_factory;

public:
   NdsSequenceState  EmptyState(void) const
      {
      NdsSequenceState seq;
      seq.last_peak_1 = m_node_factory.EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_2 = m_node_factory.EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_3 = m_node_factory.EmptyNode(NDS_NODE_PEAK);
      seq.last_valley_1 = m_node_factory.EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_2 = m_node_factory.EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_3 = m_node_factory.EmptyNode(NDS_NODE_VALLEY);
      seq.has_open_12_up = false;
      seq.has_open_12_down = false;
      seq.peak_active_len = 0;
      seq.valley_active_len = 0;
      seq.peak_max_len = 0;
      seq.valley_max_len = 0;
      seq.is_valid = false;
      return seq;
      }
  };

#endif
