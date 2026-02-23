#ifndef __NDS_I_STRATEGY_PROFILE_MQH__
#define __NDS_I_STRATEGY_PROFILE_MQH__

#include "..\\..\\Core\\nds_types.mqh"

class INdsStrategyProfile
  {
public:
   virtual string    Name(void) const
     {
      return "03-71";
     }
   virtual bool      NeedHtfTrend(void) const
     {
      return true;
     }
   virtual bool      NeedFlag(void) const
     {
      return true;
     }
   virtual bool      NeedSymmetry(void) const
     {
      return false;
     }
   virtual bool      NeedLevel86(void) const
     {
      return false;
     }
   virtual int       OrderMode(void) const
     {
      return NDS_ORDER_MARKET;
     }
   virtual double    MinConfidence(void) const
     {
      return 1.0;
     }
   virtual double    RiskPct(void) const
     {
      return 1.0;
     }
  };

#endif
