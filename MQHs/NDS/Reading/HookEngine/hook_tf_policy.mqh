#ifndef __NDS_HOOK_TF_POLICY_MQH__
#define __NDS_HOOK_TF_POLICY_MQH__

class NdsHookTfPolicy
  {
public:
   int               TfMinutes(const ENUM_TIMEFRAMES tf) const
      {
      int sec = PeriodSeconds(tf);
      if(sec <= 0)
         return 0;
      return sec / 60;
      }

   bool              IsAllowedHookTf(const ENUM_TIMEFRAMES tf) const
      {
      return (tf == PERIOD_M1 ||
              tf == PERIOD_M5 ||
              tf == PERIOD_M15 ||
              tf == PERIOD_H1 ||
              tf == PERIOD_H4 ||
              tf == PERIOD_D1);
      }

   ENUM_TIMEFRAMES   NormalizeHookTf(const ENUM_TIMEFRAMES tf) const
      {
      if(IsAllowedHookTf(tf))
         return tf;

      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      int target = TfMinutes(tf);
      if(target <= 0)
         return PERIOD_M1;

      int best_i = 0;
      int best_diff = 2147483647;
      for(int i = 0; i < 6; i++)
        {
         int d = MathAbs(TfMinutes(allowed[i]) - target);
         if(d < best_diff)
           {
            best_diff = d;
            best_i = i;
           }
        }
      return allowed[best_i];
      }

   ENUM_TIMEFRAMES   NextAllowedHookTf(const ENUM_TIMEFRAMES tf) const
      {
      ENUM_TIMEFRAMES allowed[6] = {PERIOD_M1,PERIOD_M5,PERIOD_M15,PERIOD_H1,PERIOD_H4,PERIOD_D1};
      for(int i = 0; i < 5; i++)
        {
         if(allowed[i] == tf)
            return allowed[i + 1];
        }
      return tf;
      }
  };

#endif
