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
      bool pass = (shot.hook.is_valid && shot.hook.is_closed);
      if(pass)
        {
         report.Add(Name(),NDS_RULE_PASS,2.0,"ltf closed 123 hook");
         return NDS_RULE_PASS;
        }
      report.Add(Name(),NDS_RULE_FAIL,0.0,"ltf 123 incomplete");
      return NDS_RULE_FAIL;
     }
  };

#endif
