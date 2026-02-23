#ifndef __NDS_STOP_TARGET_MANAGER_MQH__
#define __NDS_STOP_TARGET_MANAGER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsStopTargetManager
  {
public:
   int               TrailDirection(const NdsSnapshot &shot,double &new_sl) const
     {
      new_sl = 0.0;
      if(!shot.hook.is_valid)
         return 0;
      if(shot.hook.direction == NDS_DIR_BULL)
        {
         new_sl = shot.hook.n2.price;
         return 1;
        }
      if(shot.hook.direction == NDS_DIR_BEAR)
        {
         new_sl = shot.hook.n2.price;
         return -1;
        }
      return 0;
     }
  };

#endif
