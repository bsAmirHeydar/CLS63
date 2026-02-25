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

      if(!shot.cycle.has_hook2)
        {
         report.Add(Name(),NDS_RULE_FAIL,0.0,"htf hook2 missing");
         return NDS_RULE_FAIL;
        }

      if(shot.cycle.hook2.start_anchor.bar_time <= 0 || !shot.cycle.hook2.start_unbroken)
        {
         report.Add(Name(),NDS_RULE_FAIL,0.0,"htf hook2 start invalid/broken");
         return NDS_RULE_FAIL;
        }

      bool pass = (!shot.flag.is_valid || shot.flag.direction == shot.cycle.direction);
      if(pass)
        {
         report.Add(Name(),NDS_RULE_PASS,1.0,"hook2 valid and direction aligned");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"flag/htf mismatch");
      return NDS_RULE_FAIL;
     }
  };

#endif
