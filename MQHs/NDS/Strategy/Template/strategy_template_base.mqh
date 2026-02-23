#ifndef __NDS_STRATEGY_TEMPLATE_BASE_MQH__
#define __NDS_STRATEGY_TEMPLATE_BASE_MQH__

#include "..\\..\\Core\\nds_config.mqh"
#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\Core\\nds_result.mqh"
#include "..\\..\\Reading\\nds_snapshot_builder.mqh"
#include "..\\Contracts\\i_strategy_profile.mqh"
#include "..\\Rules\\rule_htf_trend.mqh"
#include "..\\Rules\\rule_sequence_123.mqh"
#include "..\\Rules\\rule_flag_presence.mqh"
#include "..\\Rules\\rule_symmetry_confluence.mqh"
#include "..\\Rules\\rule_level86_confluence.mqh"
#include "..\\Planning\\entry_planner.mqh"
#include "..\\Planning\\exit_planner.mqh"
#include "..\\Planning\\invalidation_planner.mqh"

class NdsStrategyTemplateBase
  {
private:
   NdsConfig               m_cfg;
   NdsSnapshotBuilder      m_builder;
   NdsEntryPlanner         m_entry_planner;
   NdsExitPlanner          m_exit_planner;
   NdsInvalidationPlanner  m_invalidation_planner;
   RuleHtfTrend            m_rule_htf;
   RuleSequence123         m_rule_seq;
   RuleFlagPresence        m_rule_flag;
   RuleSymmetryConfluence  m_rule_sym;
   RuleLevel86Confluence   m_rule_86;

protected:
   NdsSnapshot             m_last_snapshot;
   NdsTradeIntent          m_last_intent;
   NdsRuleReport           m_last_report;

public:
   void                    Configure(const string symbol,const NdsConfig &cfg)
     {
      m_cfg = cfg;
      m_builder.Configure(symbol,cfg);
      m_entry_planner.Configure(symbol);
      m_rule_htf.Configure(symbol);
      m_rule_86.Configure(symbol);
     }

   NdsSnapshot             LastSnapshot(void) const
     {
      return m_last_snapshot;
     }
   NdsTradeIntent          LastIntent(void) const
     {
      return m_last_intent;
     }
   NdsRuleReport           LastReport(void) const
     {
      return m_last_report;
     }

   NdsTradeIntent          Evaluate(const INdsStrategyProfile &profile)
     {
      m_last_report.Clear();
      m_last_snapshot = m_builder.Build();
      m_last_intent.can_trade = false;
      m_last_intent.direction = NDS_DIR_NONE;

      if(!m_last_snapshot.is_valid)
        {
         m_last_report.Add("snapshot",NDS_RULE_FAIL,0.0,"invalid snapshot");
         return m_last_intent;
        }

      if(profile.NeedHtfTrend())
        {
         int rs = m_rule_htf.Evaluate(m_last_snapshot,m_cfg,m_last_report);
         if(rs == NDS_RULE_FAIL)
            return m_last_intent;
        }

      if(m_rule_seq.Evaluate(m_last_snapshot,m_cfg,m_last_report) == NDS_RULE_FAIL)
         return m_last_intent;

      if(profile.NeedFlag())
        {
         if(m_rule_flag.Evaluate(m_last_snapshot,m_cfg,m_last_report) == NDS_RULE_FAIL)
            return m_last_intent;
        }

      if(profile.NeedSymmetry())
        {
         if(m_rule_sym.Evaluate(m_last_snapshot,m_cfg,m_last_report) == NDS_RULE_FAIL)
            return m_last_intent;
        }

      if(profile.NeedLevel86())
        {
         if(m_rule_86.Evaluate(m_last_snapshot,m_cfg,m_last_report) == NDS_RULE_FAIL)
            return m_last_intent;
        }

      double confidence = m_last_report.TotalScore();
      m_last_intent = m_entry_planner.Build(m_last_snapshot,profile,confidence);
      return m_last_intent;
     }

   int                     ExitDirection(void) const
     {
      return m_exit_planner.Build(m_last_snapshot);
     }
   int                     InvalidationDirection(void) const
     {
      return m_invalidation_planner.Direction(m_last_snapshot);
     }
  };

#endif
