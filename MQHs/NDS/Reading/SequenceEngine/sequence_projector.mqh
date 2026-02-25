#ifndef __NDS_SEQUENCE_PROJECTOR_MQH__
#define __NDS_SEQUENCE_PROJECTOR_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsSequenceProjector
  {
public:
   void              ProjectLast123(const NdsNode &seq_nodes_old_to_new[],const int kind,
                                    NdsNode &out_1,NdsNode &out_2,NdsNode &out_3) const
      {
      int n = ArraySize(seq_nodes_old_to_new);
      if(n >= 1)
        {
         out_3 = seq_nodes_old_to_new[n - 1];
         out_3.seq_no = 3;
        }
      if(n >= 2)
        {
         out_2 = seq_nodes_old_to_new[n - 2];
         out_2.seq_no = 2;
        }
      if(n >= 3)
        {
         out_1 = seq_nodes_old_to_new[n - 3];
         out_1.seq_no = 1;
        }
      // `kind` intentionally passed for semantic clarity (peak/valley projection), no extra logic needed.
      if(kind == NDS_NODE_NONE)
         return;
      }
  };

#endif
