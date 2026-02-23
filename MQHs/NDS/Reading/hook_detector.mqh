#ifndef __NDS_HOOK_DETECTOR_MQH__
#define __NDS_HOOK_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"

class NdsHookDetector
  {
private:
   int               ClassifyHookType(const NdsSequenceState &seq,const int dir) const
     {
      if(dir == NDS_DIR_BULL)
        {
         double leg1 = MathAbs(seq.last_peak_2.price - seq.last_peak_1.price);
         double leg2 = MathAbs(seq.last_peak_3.price - seq.last_peak_2.price);
         return (leg2 >= leg1) ? NDS_HOOK_A : NDS_HOOK_B;
        }

      if(dir == NDS_DIR_BEAR)
        {
         double leg1 = MathAbs(seq.last_valley_2.price - seq.last_valley_1.price);
         double leg2 = MathAbs(seq.last_valley_3.price - seq.last_valley_2.price);
         return (leg2 >= leg1) ? NDS_HOOK_A : NDS_HOOK_B;
        }

      return NDS_HOOK_UNKNOWN;
     }
public:
   NdsHookState      Detect(const NdsSequenceState &seq) const
     {
      NdsHookState hook;
      hook.is_valid = false;
      hook.direction = NDS_DIR_NONE;
      hook.hook_type = NDS_HOOK_UNKNOWN;
      hook.level_86 = 0.0;
      hook.is_closed = false;

      if(!seq.is_valid)
         return hook;

      bool valley_after_peak3 = (seq.last_valley_3.bar_time > seq.last_peak_3.bar_time);
      bool peak_after_valley3 = (seq.last_peak_3.bar_time > seq.last_valley_3.bar_time);

      if(valley_after_peak3)
        {
         hook.is_valid = true;
         hook.direction = NDS_DIR_BULL;
         hook.n1 = seq.last_peak_1;
         hook.n2 = seq.last_peak_2;
         hook.n3 = seq.last_peak_3;
         hook.hook_type = ClassifyHookType(seq,NDS_DIR_BULL);
         hook.level_86 = seq.last_peak_3.price - (seq.last_peak_3.price - seq.last_valley_2.price) * 0.864;
         hook.is_closed = true;
         return hook;
        }

      if(peak_after_valley3)
        {
         hook.is_valid = true;
         hook.direction = NDS_DIR_BEAR;
         hook.n1 = seq.last_valley_1;
         hook.n2 = seq.last_valley_2;
         hook.n3 = seq.last_valley_3;
         hook.hook_type = ClassifyHookType(seq,NDS_DIR_BEAR);
         hook.level_86 = seq.last_valley_3.price + (seq.last_peak_2.price - seq.last_valley_3.price) * 0.864;
         hook.is_closed = true;
         return hook;
        }

      return hook;
     }
  };

#endif
