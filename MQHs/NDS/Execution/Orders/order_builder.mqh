#ifndef __NDS_ORDER_BUILDER_MQH__
#define __NDS_ORDER_BUILDER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\..\\Strategy\\Contracts\\i_strategy_profile.mqh"

class NdsOrderBuilder
  {
public:
   NdsExecutionPlan  Build(const NdsTradeIntent &intent,const INdsStrategyProfile &profile) const
     {
      NdsExecutionPlan plan;
      plan.can_execute = false;
      plan.direction = intent.direction;
      plan.order_type = "market";
      plan.entry = intent.entry;
      plan.sl = intent.sl;
      plan.tp = intent.tp2 != 0.0 ? intent.tp2 : intent.tp1;
      plan.risk_pct = profile.RiskPct();

      if(!intent.can_trade)
         return plan;

      plan.can_execute = true;
      if(profile.OrderMode() == NDS_ORDER_LIMIT)
         plan.order_type = "limit";
      else
         if(profile.OrderMode() == NDS_ORDER_STOP)
            plan.order_type = "stop";
         else
            plan.order_type = "market";

      return plan;
     }
  };

#endif
