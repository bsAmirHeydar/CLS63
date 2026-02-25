#ifndef __NDS_RULE_SEQUENCE_123_MQH__
#define __NDS_RULE_SEQUENCE_123_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleSequence123 : public INdsRule
  {
public:
   virtual string    Name(void) const
     {
      return "sequence-123";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      bool pass = (shot.cycle.has_hook2 &&
                   shot.cycle.hook2.is_valid &&
                   shot.cycle.hook2.is_closed &&
                   shot.cycle.hook2.start_anchor.bar_time > 0 &&
                   shot.cycle.hook2.start_unbroken);
      if(pass)
        {
         report.Add(Name(),NDS_RULE_PASS,2.0,"htf hook2 valid (123 structure closed)");
         return NDS_RULE_PASS;
        }
      report.Add(Name(),NDS_RULE_FAIL,0.0,"hook2 structure invalid/incomplete");
      return NDS_RULE_FAIL;
     }
  };

#endif
