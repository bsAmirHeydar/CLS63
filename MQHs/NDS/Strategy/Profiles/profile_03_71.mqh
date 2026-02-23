#ifndef __NDS_PROFILE_03_71_MQH__
#define __NDS_PROFILE_03_71_MQH__

#include "..\\Contracts\\i_strategy_profile.mqh"

class NdsProfile0371 : public INdsStrategyProfile
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
      return true;
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
      return 2.6;
     }
   virtual double    RiskPct(void) const
     {
      return 1.0;
     }
  };

#endif
