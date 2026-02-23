#ifndef __NDS_DIAGNOSTICS_MQH__
#define __NDS_DIAGNOSTICS_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"

class NdsDiagnostics
  {
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
      txt += "\nSym(price/time): " + DoubleToString(s.symmetry.price_ratio,3) + " / " + DoubleToString(s.symmetry.time_ratio,3);
      return txt;
     }
  };

#endif
