#ifndef __NDS_SNAPSHOT_BUILDER_MQH__
#define __NDS_SNAPSHOT_BUILDER_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "data_window.mqh"
#include "sequence_detector.mqh"
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
   NdsSequenceDetector m_seq_detector;
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
      m_seq_detector.Configure(symbol,cfg);
      m_hook_detector.Configure(symbol,cfg);
      m_rally_detector.Configure(symbol);
      m_cycle_assembler.Configure(symbol,cfg);
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

      shot.sequence = m_seq_detector.Detect(m_cfg.ltf);
      shot.hook = m_hook_detector.Detect(m_cfg.ltf);
      shot.rally = m_rally_detector.Detect(m_cfg.ltf,shot.hook);
      shot.flag = m_flag_detector.Detect(shot.sequence,shot.hook);
      shot.cycle = m_cycle_assembler.Assemble(shot.flag);

      if(shot.cycle.has_hook2)
        {
         shot.flag = m_flag_detector.DetectForDirection(shot.sequence,shot.cycle.direction);
         shot.cycle.has_flag = shot.flag.is_valid;

         if(shot.cycle.has_flag)
            shot.cycle.phase = NDS_PHASE_FLAG;
         else
            if(shot.cycle.has_rally_after_hook2)
               shot.cycle.phase = NDS_PHASE_RALLY_1;
            else
               shot.cycle.phase = NDS_PHASE_HOOK_2;
        }

      // Keep snapshot TF labels aligned with owned hook/cycle TFs after per-hook promotion.
      if(shot.hook.is_valid && shot.hook.scan_tf != PERIOD_CURRENT)
         shot.tf_ltf = shot.hook.scan_tf;
      if(shot.cycle.has_hook2 && shot.cycle.hook2.is_valid && shot.cycle.hook2.scan_tf != PERIOD_CURRENT)
         shot.tf_htf = shot.cycle.hook2.scan_tf;
      else
         if(shot.cycle.hook1.is_valid && shot.cycle.hook1.scan_tf != PERIOD_CURRENT)
            shot.tf_htf = shot.cycle.hook1.scan_tf;

      NdsHookState sym_hook = shot.cycle.has_hook2 ? shot.cycle.hook2 : shot.hook;
      shot.symmetry = m_symmetry_engine.Evaluate(m_cfg,sym_hook);

      shot.is_valid = shot.cycle.has_hook2 || shot.sequence.is_valid || shot.hook.is_valid || shot.flag.is_valid || shot.rally.is_valid;
      return shot;
     }
  };

#endif
