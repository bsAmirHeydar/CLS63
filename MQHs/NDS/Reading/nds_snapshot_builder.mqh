#ifndef __NDS_SNAPSHOT_BUILDER_MQH__
#define __NDS_SNAPSHOT_BUILDER_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "data_window.mqh"
#include "node_detector.mqh"
#include "sequence_engine.mqh"
#include "hook_detector.mqh"
#include "rally_detector.mqh"
#include "flag_detector.mqh"
#include "symmetry_engine.mqh"
#include "cycle_assembler.mqh"

class NdsSnapshotBuilder
  {
private:
   string            m_symbol;
   NdsConfig         m_cfg;
   NdsNodeDetector   m_nodes;
   NdsSequenceEngine m_seq_engine;
   NdsHookDetector   m_hook_detector;
   NdsRallyDetector  m_rally_detector;
   NdsFlagDetector   m_flag_detector;
   NdsSymmetryEngine m_symmetry_engine;
   NdsCycleAssembler m_cycle_assembler;

   void              InitSnapshot(NdsSnapshot &shot) const
     {
      ZeroMemory(shot);
      shot.symbol = m_symbol;
      shot.tf_htf = m_cfg.htf;
      shot.tf_ltf = m_cfg.ltf;
      shot.now_time = TimeCurrent();
      shot.is_valid = false;
     }

   bool              HasRequiredData(const NdsDataWindow &dw) const
     {
      int min_bars = MathMax(30,m_cfg.pivot_depth * 8 + 10);
      return dw.IsReady(m_cfg.ltf,min_bars);
     }

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
     {
      m_symbol = symbol;
      m_cfg = cfg;
      m_nodes.Configure(symbol,cfg);
      m_rally_detector.Configure(symbol);
     }

   NdsSnapshot       Build(void)
     {
      NdsSnapshot shot;
      InitSnapshot(shot);

      if(m_symbol == "")
         return shot;

      NdsDataWindow dw(m_symbol);
      if(!HasRequiredData(dw))
         return shot;

      datetime bar_time = dw.Time(m_cfg.ltf,0);
      if(bar_time > 0)
         shot.now_time = bar_time;

      shot.sequence = m_seq_engine.Build(m_cfg.ltf,m_nodes);
      shot.hook = m_hook_detector.Detect(shot.sequence);
      shot.rally = m_rally_detector.Detect(m_cfg.ltf,shot.hook);
      shot.flag = m_flag_detector.Detect(shot.sequence,shot.hook);
      shot.symmetry = m_symmetry_engine.Evaluate(m_cfg,shot.hook);
      shot.cycle = m_cycle_assembler.Assemble(shot.hook,shot.rally,shot.flag);

      shot.is_valid = shot.sequence.is_valid || shot.hook.is_valid || shot.flag.is_valid || shot.rally.is_valid;
      return shot;
     }
  };

#endif
