#ifndef __NDS_FLAG_DETECTOR_MQH__
#define __NDS_FLAG_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"

class NdsFlagDetector
  {
public:
   NdsFlagState      DetectForDirection(const NdsSequenceState &seq,const int dir) const
     {
      NdsFlagState flag;
      flag.is_valid = false;
      flag.direction = NDS_DIR_NONE;

      if(dir == NDS_DIR_BULL)
        {
         bool corrective = (seq.last_peak_3.price <= seq.last_peak_2.price * 1.02 &&
                            seq.last_valley_3.price < seq.last_valley_2.price);
         if(corrective)
           {
            flag.is_valid = true;
            flag.direction = NDS_DIR_BULL;
            flag.f1 = seq.last_peak_1;
            flag.f2 = seq.last_valley_1;
            flag.f3 = seq.last_peak_2;
            flag.f4 = seq.last_valley_2;
           }
         return flag;
        }

      if(dir == NDS_DIR_BEAR)
        {
         bool corrective = (seq.last_valley_3.price >= seq.last_valley_2.price * 0.98 &&
                            seq.last_peak_3.price > seq.last_peak_2.price);
         if(corrective)
           {
            flag.is_valid = true;
            flag.direction = NDS_DIR_BEAR;
            flag.f1 = seq.last_valley_1;
            flag.f2 = seq.last_peak_1;
            flag.f3 = seq.last_valley_2;
            flag.f4 = seq.last_peak_2;
           }
         return flag;
        }

      return flag;
     }

   NdsFlagState      Detect(const NdsSequenceState &seq,const NdsHookState &hook) const
     {
      if(!hook.is_valid)
         return DetectForDirection(seq,NDS_DIR_NONE);

      return DetectForDirection(seq,hook.direction);
     }
  };

#endif
