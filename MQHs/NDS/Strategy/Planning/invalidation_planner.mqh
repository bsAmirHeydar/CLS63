#ifndef __NDS_INVALIDATION_PLANNER_MQH__
#define __NDS_INVALIDATION_PLANNER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsInvalidationPlanner
  {
public:
   int               Direction(const NdsSnapshot &shot) const
     {
      if(!shot.cycle.has_hook2)
         return 0;

      double bid = SymbolInfoDouble(shot.symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(shot.symbol,SYMBOL_ASK);

      if(shot.cycle.direction == NDS_DIR_BULL && bid <= shot.cycle.hook2.z.price)
         return 1;
      if(shot.cycle.direction == NDS_DIR_BEAR && ask >= shot.cycle.hook2.z.price)
         return -1;
      return 0;
      }
  };

#endif
