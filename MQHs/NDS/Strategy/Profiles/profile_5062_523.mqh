#ifndef __NDS_PROFILE_5062_523_MQH__
#define __NDS_PROFILE_5062_523_MQH__

#include "..\\Contracts\\i_strategy_profile.mqh"

class NdsProfile5062523 : public INdsStrategyProfile
  {
public:
   virtual string    Name(void) const
     {
      return "5062-523";
     }
   virtual bool      NeedHtfTrend(void) const
     {
      return false;
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
      return true;
     }
   virtual int       OrderMode(void) const
     {
      return NDS_ORDER_LIMIT;
     }
   virtual double    MinConfidence(void) const
     {
      return 2.2;
     }
   virtual double    RiskPct(void) const
     {
      return 0.75;
     }
  };

#endif
