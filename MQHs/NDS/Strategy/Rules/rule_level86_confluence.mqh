#ifndef __NDS_RULE_LEVEL86_MQH__
#define __NDS_RULE_LEVEL86_MQH__

#include "..\\Contracts\\i_rule.mqh"

class RuleLevel86Confluence : public INdsRule
  {
private:
   string            m_symbol;
public:
                     RuleLevel86Confluence(void)
     {
      m_symbol = _Symbol;
     }
                     RuleLevel86Confluence(const string symbol)
     {
      m_symbol = symbol;
     }
   void              Configure(const string symbol)
     {
      m_symbol = symbol;
     }
   virtual string    Name(void) const
     {
      return "level86-confluence";
     }
   virtual int       Evaluate(const NdsSnapshot &shot,const NdsConfig &cfg,NdsRuleReport &report) const
     {
      if(!cfg.use_86_gate)
        {
         report.Add(Name(),NDS_RULE_SKIP,0.0,"gate disabled");
         return NDS_RULE_SKIP;
        }

      NdsHookState ref_hook = shot.cycle.has_hook2 ? shot.cycle.hook2 : shot.hook;
      if(!ref_hook.is_valid)
        {
         report.Add(Name(),NDS_RULE_FAIL,0.0,"hook missing");
         return NDS_RULE_FAIL;
        }

      double px = (ref_hook.direction == NDS_DIR_BULL) ?
                  SymbolInfoDouble(m_symbol,SYMBOL_BID) :
                  SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      bool near86 = (MathAbs(px - ref_hook.level_86) <= cfg.near_level86_tolerance * px);

      if(near86 || shot.symmetry.is_near_86)
        {
         report.Add(Name(),NDS_RULE_PASS,0.5,"near 86");
         return NDS_RULE_PASS;
        }

      report.Add(Name(),NDS_RULE_FAIL,0.0,"far from 86");
      return NDS_RULE_FAIL;
     }
  };

#endif
