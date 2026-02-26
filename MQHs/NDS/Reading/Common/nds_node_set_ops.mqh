#ifndef __NDS_READING_NODE_SET_OPS_MQH__
#define __NDS_READING_NODE_SET_OPS_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsNodeSetOps
  {
public:
   void              ToArrays(const NdsNodeSet &src,NdsNode &out_peaks[],NdsNode &out_valleys[]) const
      {
      int pn = ArraySize(src.peaks);
      ArrayResize(out_peaks,pn);
      for(int i = 0; i < pn; i++)
         out_peaks[i] = src.peaks[i];

      int vn = ArraySize(src.valleys);
      ArrayResize(out_valleys,vn);
      for(int j = 0; j < vn; j++)
         out_valleys[j] = src.valleys[j];
      }
  };

#endif
