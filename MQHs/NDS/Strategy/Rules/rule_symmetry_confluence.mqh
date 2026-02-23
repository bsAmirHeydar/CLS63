#ifndef __NDS_RULE_SYMMETRY_MQH__
#define __NDS_RULE_SYMMETRY_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleSymmetryConfluence : public INdsRule
  {
public:
   virtual string    Name(void) const
     {
      return "symmetry-confluence";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      if(!cfg.use_symmetry_gate)
        {
         report.Add(Name(),NDS_RULE_SKIP,0.0,"gate disabled");
         return NDS_RULE_SKIP;
        }

      if(shot.symmetry.is_valid)
        {
         report.Add(Name(),NDS_RULE_PASS,0.75,"symmetry ok");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"symmetry weak");
      return NDS_RULE_FAIL;
     }
  };

#endif
