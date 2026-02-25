#ifndef __NDS_NODE_RECORD_BUILDER_MQH__
#define __NDS_NODE_RECORD_BUILDER_MQH__

#include "..\\Common\\nds_node_factory.mqh"

class NdsNodeRecordBuilder
  {
private:
   string            m_symbol;
   NdsNodeFactory    m_factory;

public:
   void              Configure(const string symbol)
      {
      m_symbol = symbol;
      }

   void              AppendNode(const int kind,const ENUM_TIMEFRAMES tf,const int shift,NdsNode &out_nodes[]) const
      {
      int n = ArraySize(out_nodes);
      ArrayResize(out_nodes,n + 1);
      m_factory.FillDetectedNode(m_symbol,tf,kind,shift,out_nodes[n]);
      out_nodes[n].seq_no = 0;
      out_nodes[n].is_open = false;
      }
  };

#endif
