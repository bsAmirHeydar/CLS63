#ifndef __NDS_INVALIDATION_PLANNER_MQH__
#define __NDS_INVALIDATION_PLANNER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsInvalidationPlanner
  {
public:
   int               Direction(const NdsSnapshot &shot) const
     {
      // Structural invalidation direction used for cancel/remove operations
      if(!shot.hook.is_valid)
         return 0;
      if(shot.hook.direction == NDS_DIR_BULL && shot.sequence.has_open_12_down)
         return 1;
      if(shot.hook.direction == NDS_DIR_BEAR && shot.sequence.has_open_12_up)
         return -1;
      return 0;
     }
  };

#endif
