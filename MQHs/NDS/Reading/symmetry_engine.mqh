#ifndef __NDS_SYMMETRY_ENGINE_MQH__
#define __NDS_SYMMETRY_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"

class NdsSymmetryEngine
  {
public:
   NdsSymmetryState  Evaluate(const NdsConfig &cfg,const NdsHookState &hook) const
     {
      NdsSymmetryState sym;
      sym.is_valid = false;
      sym.price_ratio = 0.0;
      sym.time_ratio = 0.0;
      sym.target_price = 0.0;
      sym.is_near_86 = false;

      if(!hook.is_valid)
         return sym;

      double leg_a = MathAbs(hook.n2.price - hook.n1.price);
      double leg_b = MathAbs(hook.n3.price - hook.n2.price);
      if(leg_a <= 0.0)
         return sym;

      sym.price_ratio = leg_b / leg_a;
      int dt_a = MathAbs(hook.n2.bar_index - hook.n1.bar_index);
      int dt_b = MathAbs(hook.n3.bar_index - hook.n2.bar_index);
      if(dt_a > 0)
         sym.time_ratio = (double)dt_b / (double)dt_a;
      else
         sym.time_ratio = 0.0;

      sym.is_near_86 = (MathAbs(sym.price_ratio - 0.864) <= cfg.near_level86_tolerance);
      sym.is_valid = (MathAbs(1.0 - sym.price_ratio) <= cfg.tolerance_price_ratio ||
                      MathAbs(1.0 - sym.time_ratio) <= cfg.tolerance_time_ratio ||
                      sym.is_near_86);

      if(hook.direction == NDS_DIR_BULL)
         sym.target_price = hook.n3.price + leg_a;
      else
         if(hook.direction == NDS_DIR_BEAR)
            sym.target_price = hook.n3.price - leg_a;

      return sym;
     }
  };

#endif
