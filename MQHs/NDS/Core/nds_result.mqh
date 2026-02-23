#ifndef __NDS_RESULT_MQH__
#define __NDS_RESULT_MQH__

#include "nds_types.mqh"

struct NdsRuleCheck
  {
   string            name;
   int               status;       // NdsRuleStatus
   double            score;
   string            note;
  };

class NdsRuleReport
  {
private:
   NdsRuleCheck      m_checks[];
public:
   void              Clear(void)
     {
      ArrayResize(m_checks,0);
     }
   void              Add(const string name,const int status,const double score,const string note)
     {
      NdsRuleCheck c;
      c.name = name;
      c.status = status;
      c.score = score;
      c.note = note;
      int n = ArraySize(m_checks);
      ArrayResize(m_checks,n + 1);
      m_checks[n] = c;
     }
   int               Count(void) const
     {
      return ArraySize(m_checks);
     }
   NdsRuleCheck      Get(const int index) const
     {
      if(index < 0 || index >= ArraySize(m_checks))
        {
         NdsRuleCheck empty;
         empty.name = "";
         empty.status = NDS_RULE_SKIP;
         empty.score = 0.0;
         empty.note = "";
         return empty;
        }
      return m_checks[index];
     }
   double            TotalScore(void) const
     {
      double sum = 0.0;
      for(int i = 0; i < ArraySize(m_checks); i++)
         sum += m_checks[i].score;
      return sum;
     }
   bool              AllPass(void) const
     {
      for(int i = 0; i < ArraySize(m_checks); i++)
        {
         if(m_checks[i].status == NDS_RULE_FAIL)
            return false;
        }
      return true;
     }
  };

#endif
