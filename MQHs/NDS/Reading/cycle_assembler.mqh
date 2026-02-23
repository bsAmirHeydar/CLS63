#ifndef __NDS_CYCLE_ASSEMBLER_MQH__
#define __NDS_CYCLE_ASSEMBLER_MQH__

#include "..\\Core\\nds_entities.mqh"

class NdsCycleAssembler
  {
public:
   NdsCycleState     Assemble(const NdsHookState &hook,const NdsRallyState &rally,const NdsFlagState &flag) const
     {
      NdsCycleState cycle;
      cycle.is_valid = false;
      cycle.direction = NDS_DIR_NONE;
      cycle.phase = NDS_PHASE_UNKNOWN;
      cycle.hooks_count = 0;
      cycle.rallies_count = 0;
      cycle.has_flag = false;

      if(!hook.is_valid)
         return cycle;

      cycle.is_valid = true;
      cycle.direction = hook.direction;
      cycle.hooks_count = 1;
      cycle.rallies_count = rally.is_valid ? 1 : 0;
      cycle.has_flag = flag.is_valid;

      if(!hook.is_closed)
         cycle.phase = NDS_PHASE_HOOK_1;
      else
         if(!rally.is_valid)
            cycle.phase = NDS_PHASE_HOOK_2;
         else
            if(!flag.is_valid)
               cycle.phase = NDS_PHASE_RALLY_1;
            else
               cycle.phase = NDS_PHASE_FLAG;

      return cycle;
     }
  };

#endif
