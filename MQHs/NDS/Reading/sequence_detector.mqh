#ifndef __NDS_SEQUENCE_DETECTOR_MQH__
#define __NDS_SEQUENCE_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "node_detector.mqh"
#include "sequence_engine.mqh"
#include "Common\\nds_node_set_ops.mqh"
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
   NdsNodeSetOps         m_node_set_ops;

public:
   void                   Configure(const string symbol,const NdsConfig &cfg)
      {
      m_symbol = symbol;
      m_nodes.Configure(symbol,cfg);
      m_tracker.Configure(symbol);
      m_cache.Configure(symbol);
      }

   NdsSequenceState       DetectAtTf(const ENUM_TIMEFRAMES tf) const
      {
      NdsNodeSet node_set;
      m_nodes.DetectNodeSetAtTf(tf,node_set,0);

      bool changed = m_tracker.EvalAndCommit(tf,node_set.peaks,node_set.valleys);

      NdsSequenceState cached;
      if(!changed && m_cache.TryGet(tf,cached))
         return cached;

      NdsSequenceState seq = m_engine.BuildFromNodeSet(node_set);
      m_cache.Put(tf,seq);
      return seq;
      }

   NdsSequenceState       Detect(const ENUM_TIMEFRAMES tf) const
      {
      return DetectAtTf(tf);
      }

   void                   DetectAtTf(const ENUM_TIMEFRAMES tf,NdsNodeSet &out_nodes,NdsSequenceState &out_seq) const
      {
      m_nodes.DetectNodeSetAtTf(tf,out_nodes,0);

      bool changed = m_tracker.EvalAndCommit(tf,out_nodes.peaks,out_nodes.valleys);

      NdsSequenceState cached;
      if(!changed && m_cache.TryGet(tf,cached))
        {
         out_seq = cached;
         return;
        }

      out_seq = m_engine.BuildFromNodeSet(out_nodes);
      m_cache.Put(tf,out_seq);
      }

   void                   DetectAtTf(const ENUM_TIMEFRAMES tf,NdsNode &out_peaks[],NdsNode &out_valleys[],NdsSequenceState &out_seq) const
      {
      NdsNodeSet node_set;
      DetectAtTf(tf,node_set,out_seq);

      m_node_set_ops.ToArrays(node_set,out_peaks,out_valleys);
      }
  };

#endif
