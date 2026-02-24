#ifndef __NDS_DIAGNOSTICS_MQH__
#define __NDS_DIAGNOSTICS_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"

class NdsDiagnostics
  {
private:
   string            RuleStatus(const int status) const
     {
      if(status == NDS_RULE_PASS)
         return "PASS";
      if(status == NDS_RULE_FAIL)
         return "FAIL";
      return "SKIP";
     }
public:
   string            BuildSnapshotText(const NdsSnapshot &s,const NdsTradeIntent &intent,const NdsRuleReport &rep) const
     {
      string txt = "NDS Snapshot";
      txt += "\nDir: " + IntegerToString(intent.direction);
      txt += "\nIntent: " + (intent.can_trade ? "YES" : "NO");
      txt += "\nEntry: " + DoubleToString(intent.entry,_Digits);
      txt += "\nSL/TP2: " + DoubleToString(intent.sl,_Digits) + " / " + DoubleToString(intent.tp2,_Digits);
      txt += "\nRuleScore: " + DoubleToString(rep.TotalScore(),2);
      txt += "\nHookValid: " + (s.hook.is_valid ? "1" : "0") + " Flag: " + (s.flag.is_valid ? "1" : "0");
      if(s.hook.is_valid)
         txt += "\nLTF Hook(type,dir): " + IntegerToString(s.hook.hook_type) + " / " + IntegerToString(s.hook.direction) +
                " 1,2,3,Z=" + DoubleToString(s.hook.n1.price,_Digits) + " / " +
                DoubleToString(s.hook.n2.price,_Digits) + " / " +
                DoubleToString(s.hook.n3.price,_Digits) + " / " +
                DoubleToString(s.hook.z.price,_Digits);
      txt += "\nSym(price/time): " + DoubleToString(s.symmetry.price_ratio,3) + " / " + DoubleToString(s.symmetry.time_ratio,3);
      txt += "\nHTF Cycle: dir=" + IntegerToString(s.cycle.direction) +
             " hooks=" + IntegerToString(s.cycle.hooks_count) +
             " rally=" + IntegerToString(s.cycle.rallies_count) +
             " hook2=" + (s.cycle.has_hook2 ? "1" : "0");
      if(s.cycle.hook1.is_valid)
         txt += "\nH1(1,2,3,Z): " + DoubleToString(s.cycle.hook1.n1.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook1.n2.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook1.n3.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook1.z.price,_Digits);
      if(s.cycle.has_hook2)
         txt += "\nH2(1,2,3,Z): " + DoubleToString(s.cycle.hook2.n1.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook2.n2.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook2.n3.price,_Digits) + " / " +
                DoubleToString(s.cycle.hook2.z.price,_Digits);
      txt += "\nRules:";
      int count = rep.Count();
      for(int i = 0; i < count; i++)
        {
         NdsRuleCheck c = rep.Get(i);
         txt += "\n- " + c.name + ": " + RuleStatus(c.status);
         if(c.note != "")
            txt += " (" + c.note + ")";
        }
      return txt;
     }
  };

#endif
