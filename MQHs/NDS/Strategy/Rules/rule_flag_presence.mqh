#ifndef __NDS_RULE_FLAG_PRESENCE_MQH__
#define __NDS_RULE_FLAG_PRESENCE_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleFlagPresence : public INdsRule
  {
public:
   virtual string    Name(void) const
     {
      return "flag-presence";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      if(!cfg.use_flag_gate)
        {
         report.Add(Name(),NDS_RULE_SKIP,0.0,"gate disabled");
         return NDS_RULE_SKIP;
        }

      if(shot.flag.is_valid)
        {
         report.Add(Name(),NDS_RULE_PASS,1.0,"flag found");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"flag missing");
      return NDS_RULE_FAIL;
     }
  };

#endif
