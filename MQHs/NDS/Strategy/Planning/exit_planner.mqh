#ifndef __NDS_EXIT_PLANNER_MQH__
#define __NDS_EXIT_PLANNER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsExitPlanner
  {
public:
   int               Build(const NdsSnapshot &shot) const
     {
      if(!shot.hook.is_valid)
         return 0;
      // Exit by opposite structural pressure
      if(shot.hook.direction == NDS_DIR_BULL && shot.sequence.has_open_12_down)
         return 1;    // close BUY
      if(shot.hook.direction == NDS_DIR_BEAR && shot.sequence.has_open_12_up)
         return -1;   // close SELL
      return 0;
     }
  };

#endif
