#ifndef __NDS_I_RULE_MQH__
#define __NDS_I_RULE_MQH__

#include "..\\..\\Core\\nds_config.mqh"
#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\Core\\nds_result.mqh"

class INdsRule
  {
public:
   virtual string    Name(void) const
     {
      return "base-rule";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      report.Add(Name(),NDS_RULE_SKIP,0.0,"no-op");
      return NDS_RULE_SKIP;
     }
  };

#endif
