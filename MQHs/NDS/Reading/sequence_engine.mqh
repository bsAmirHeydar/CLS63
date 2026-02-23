#ifndef __NDS_SEQUENCE_ENGINE_MQH__
#define __NDS_SEQUENCE_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "node_detector.mqh"

class NdsSequenceEngine
  {
private:
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
public:
   NdsSequenceState  Build(const ENUM_TIMEFRAMES tf,const NdsNodeDetector &detector) const
     {
      NdsSequenceState seq;
      seq.last_peak_1 = EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_2 = EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_3 = EmptyNode(NDS_NODE_PEAK);
      seq.last_valley_1 = EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_2 = EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_3 = EmptyNode(NDS_NODE_VALLEY);
      seq.has_open_12_up = false;
      seq.has_open_12_down = false;
      seq.is_valid = false;

      NdsNode peaks[];
      NdsNode valleys[];
      int peak_count = detector.FindRecentNodes(tf,NDS_NODE_PEAK,3,peaks);
      int valley_count = detector.FindRecentNodes(tf,NDS_NODE_VALLEY,3,valleys);

      if(peak_count >= 1) seq.last_peak_1 = peaks[peak_count - 1];
      if(peak_count >= 2) seq.last_peak_2 = peaks[peak_count - 2];
      if(peak_count >= 3) seq.last_peak_3 = peaks[peak_count - 3];

      if(valley_count >= 1) seq.last_valley_1 = valleys[valley_count - 1];
      if(valley_count >= 2) seq.last_valley_2 = valleys[valley_count - 2];
      if(valley_count >= 3) seq.last_valley_3 = valleys[valley_count - 3];

      // open 1/2 means we still do not have a complete 1/2/3 chain on that side
      seq.has_open_12_up = (peak_count == 2);
      seq.has_open_12_down = (valley_count == 2);

      if(peak_count >= 3 && valley_count >= 3)
        {
         bool peaks_up = (seq.last_peak_1.price < seq.last_peak_2.price && seq.last_peak_2.price < seq.last_peak_3.price);
         bool valleys_down = (seq.last_valley_1.price > seq.last_valley_2.price && seq.last_valley_2.price > seq.last_valley_3.price);
         seq.is_valid = (peaks_up && valleys_down);
        }

      return seq;
     }
  };

#endif
