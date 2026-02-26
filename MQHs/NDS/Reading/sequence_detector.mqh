#ifndef __NDS_SEQUENCE_DETECTOR_MQH__
#define __NDS_SEQUENCE_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "node_detector.mqh"
#include "sequence_engine.mqh"
#include "SequenceDetector\\sequence_update_tracker.mqh"
#include "SequenceDetector\\sequence_cache_store.mqh"

class NdsSequenceDetector
  {
private:
   string                 m_symbol;
   NdsNodeDetector        m_nodes;
   NdsSequenceEngine      m_engine;
   NdsSequenceUpdateTracker m_tracker;
   NdsSequenceCacheStore  m_cache;

public:
   void                   Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_nodes.Configure(symbol,cfg);
      m_tracker.Configure(symbol);
      m_cache.Configure(symbol);
      }

   NdsSequenceState       Detect(const ENUM_TIMEFRAMES tf) const
      {
      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      m_nodes.DetectAllNodes(tf,peaks_raw,valleys_raw,0);

      bool changed = m_tracker.EvalAndCommit(tf,peaks_raw,valleys_raw);

      NdsSequenceState cached;
      if(!changed && m_cache.TryGet(tf,cached))
         return cached;

      NdsSequenceState seq = m_engine.BuildFromNodes(peaks_raw,valleys_raw);
      m_cache.Put(tf,seq);
      return seq;
      }
  };

#endif
