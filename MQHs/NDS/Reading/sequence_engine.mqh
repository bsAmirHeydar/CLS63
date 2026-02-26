#ifndef __NDS_SEQUENCE_ENGINE_MQH__
#define __NDS_SEQUENCE_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "node_detector.mqh"
#include "SequenceEngine\\sequence_state_factory.mqh"
#include "SequenceEngine\\sequence_nested_builder.mqh"
#include "SequenceEngine\\sequence_projector.mqh"
#include "SequenceEngine\\sequence_status_policy.mqh"

class NdsSequenceEngine
  {
private:
   NdsSequenceStateFactory m_state_factory;
   NdsSequenceNestedBuilder m_nested_builder;
   NdsSequenceProjector m_projector;
   NdsSequenceStatusPolicy m_status_policy;

public:
   NdsSequenceState  BuildFromNodes(const NdsNode &peaks_raw[],const NdsNode &valleys_raw[]) const
      {
      NdsSequenceState seq = m_state_factory.EmptyState();

      NdsNode peaks_seq[];
      NdsNode valleys_seq[];
      int peaks_nested_max = 0;
      int valleys_nested_max = 0;

      int peak_count = m_nested_builder.BuildNestedFromEnd(peaks_raw,false,peaks_seq,peaks_nested_max);
      int valley_count = m_nested_builder.BuildNestedFromEnd(valleys_raw,true,valleys_seq,valleys_nested_max);

      seq.peak_active_len = peak_count;
      seq.valley_active_len = valley_count;
      seq.peak_max_len = peaks_nested_max;
      seq.valley_max_len = valleys_nested_max;

      m_projector.ProjectLast123(peaks_seq,NDS_NODE_PEAK,seq.last_peak_1,seq.last_peak_2,seq.last_peak_3);
      m_projector.ProjectLast123(valleys_seq,NDS_NODE_VALLEY,seq.last_valley_1,seq.last_valley_2,seq.last_valley_3);

      m_status_policy.ApplyStatus(seq);
      return seq;
      }

   NdsSequenceState  Build(const ENUM_TIMEFRAMES tf,const NdsNodeDetector &detector) const
      {
      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      detector.DetectAllNodes(tf,peaks_raw,valleys_raw,0); // oldest -> newest
      return BuildFromNodes(peaks_raw,valleys_raw);
      }
  };

#endif
