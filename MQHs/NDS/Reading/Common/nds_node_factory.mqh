#ifndef __NDS_READING_NODE_FACTORY_MQH__
#define __NDS_READING_NODE_FACTORY_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsNodeFactory
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

   void              FillDetectedNode(const string symbol,const ENUM_TIMEFRAMES tf,const int kind,const int shift,NdsNode &out_node) const
      {
      out_node = EmptyNode(kind);
      out_node.bar_index = shift;
      out_node.bar_time = iTime(symbol,tf,shift);
      out_node.price = (kind == NDS_NODE_PEAK ? iHigh(symbol,tf,shift) : iLow(symbol,tf,shift));
      }
  };

#endif
