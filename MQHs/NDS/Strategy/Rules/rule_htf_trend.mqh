#ifndef __NDS_RULE_HTF_TREND_MQH__
#define __NDS_RULE_HTF_TREND_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleHtfTrend : public INdsRule
  {
public:
                     RuleHtfTrend(void) {}
   void              Configure(const string symbol) {}
   virtual string    Name(void) const
     {
      return "htf-trend";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      if(!cfg.use_htf_trend_gate)
        {
         report.Add(Name(),NDS_RULE_SKIP,0.0,"gate disabled");
         return NDS_RULE_SKIP;
        }

      if(!shot.cycle.has_hook2 || !shot.cycle.has_rally_after_hook2)
        {
         report.Add(Name(),NDS_RULE_FAIL,0.0,"htf hook2/rally missing");
         return NDS_RULE_FAIL;
        }

      bool pass = (shot.hook.direction == NDS_DIR_NONE || shot.hook.direction == shot.cycle.direction);
      if(pass)
        {
         report.Add(Name(),NDS_RULE_PASS,1.0,"hook2+rally aligned");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"ltf/htf mismatch");
      return NDS_RULE_FAIL;
     }
  };

#endif
