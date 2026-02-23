#ifndef __NDS_ORCHESTRATOR_MQH__
#define __NDS_ORCHESTRATOR_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"
#include "..\\Strategy\\Template\\strategy_template_base.mqh"
#include "..\\Strategy\\Profiles\\profile_03_71.mqh"
#include "..\\Strategy\\Profiles\\profile_5062_523.mqh"
#include "..\\Execution\\Orders\\order_builder.mqh"
#include "..\\Debug\\visual_debug.mqh"

class NdsOrchestrator
  {
private:
   NdsConfig                 m_cfg;
   NdsStrategyTemplateBase   m_template;
   NdsOrderBuilder           m_order_builder;
   NdsVisualDebug            m_visual;
   NdsTradeIntent            m_intent;
   NdsExecutionPlan          m_plan;

   string                    Upper(const string s) const
     {
      string x = s;
      StringToUpper(x);
      return x;
     }
public:
   void                      Configure(const string symbol,const NdsConfig &cfg)
     {
      m_cfg = cfg;
      m_template.Configure(symbol,cfg);
      m_visual.Configure("NDSDBG_" + symbol,cfg);
     }

   NdsTradeIntent            Evaluate(void)
     {
      string p = Upper(m_cfg.profile_name);
      if(p == "03-71")
        {
         NdsProfile0371 profile;
         m_intent = m_template.Evaluate(profile);
         m_plan = m_order_builder.Build(m_intent,profile);
        }
      else
         if(p == "5062-523")
           {
            NdsProfile5062523 profile;
            m_intent = m_template.Evaluate(profile);
            m_plan = m_order_builder.Build(m_intent,profile);
           }
         else
           {
            NdsProfile0371 profile;
            m_intent = m_template.Evaluate(profile);
            m_plan = m_order_builder.Build(m_intent,profile);
           }

      m_visual.Render(m_template.LastSnapshot(),m_intent,m_template.LastReport());
      return m_intent;
     }

   NdsExecutionPlan          Plan(void) const
     {
      return m_plan;
     }
   NdsSnapshot               Snapshot(void) const
     {
      return m_template.LastSnapshot();
     }
   NdsRuleReport             Report(void) const
     {
      return m_template.LastReport();
     }
   int                       ExitDirection(void) const
     {
      return m_template.ExitDirection();
     }
   int                       InvalidationDirection(void) const
     {
      return m_template.InvalidationDirection();
     }
  };

#endif
