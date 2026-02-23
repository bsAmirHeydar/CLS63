#ifndef __NDS_RULE_HTF_TREND_MQH__
#define __NDS_RULE_HTF_TREND_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleHtfTrend : public INdsRule
  {
private:
   string            m_symbol;
public:
                     RuleHtfTrend(void)
     {
      m_symbol = _Symbol;
     }
                     RuleHtfTrend(const string symbol)
     {
      m_symbol = symbol;
     }
   void              Configure(const string symbol)
     {
      m_symbol = symbol;
     }
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

      double c1 = iClose(m_symbol,cfg.htf,1);
      double c2 = iClose(m_symbol,cfg.htf,2);
      if(c1 == 0.0 || c2 == 0.0)
        {
         report.Add(Name(),NDS_RULE_FAIL,0.0,"no htf data");
         return NDS_RULE_FAIL;
        }

      bool pass = (shot.hook.direction == NDS_DIR_BULL && c1 > c2) ||
                  (shot.hook.direction == NDS_DIR_BEAR && c1 < c2);
      if(pass)
        {
         report.Add(Name(),NDS_RULE_PASS,1.0,"trend aligned");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"trend mismatch");
      return NDS_RULE_FAIL;
     }
  };

#endif
