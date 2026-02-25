#ifndef __NDS_SEQUENCE_STATUS_POLICY_MQH__
#define __NDS_SEQUENCE_STATUS_POLICY_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsSequenceStatusPolicy
  {
public:
   void              ApplyStatus(NdsSequenceState &seq) const
      {
      bool peaks_down = (seq.peak_active_len >= 3 &&
                         seq.last_peak_1.price > seq.last_peak_2.price &&
                         seq.last_peak_2.price > seq.last_peak_3.price);
      bool valleys_up = (seq.valley_active_len >= 3 &&
                         seq.last_valley_1.price < seq.last_valley_2.price &&
                         seq.last_valley_2.price < seq.last_valley_3.price);

      seq.has_open_12_up = (seq.valley_active_len == 2);
      seq.has_open_12_down = (seq.peak_active_len == 2);
      seq.is_valid = (peaks_down || valleys_up || seq.peak_max_len >= 3 || seq.valley_max_len >= 3);
      }
  };

#endif
