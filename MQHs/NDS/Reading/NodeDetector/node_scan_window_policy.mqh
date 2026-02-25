#ifndef __NDS_NODE_SCAN_WINDOW_POLICY_MQH__
#define __NDS_NODE_SCAN_WINDOW_POLICY_MQH__

class NdsNodeScanWindowPolicy
  {
private:
   int               m_depth;
   int               m_lookback;

public:
   void              Configure(const int depth,const int lookback)
      {
      m_depth = MathMax(1,depth);
      m_lookback = MathMax(50,lookback);
      }

   bool              Resolve(const string symbol,const ENUM_TIMEFRAMES tf,int &out_min_shift,int &out_max_shift,int &out_last_shift) const
      {
      out_min_shift = 0;
      out_max_shift = -1;
      out_last_shift = -1;

      int bars_total = iBars(symbol,tf);
      if(bars_total <= m_depth * 2 + 3)
         return false;

      out_last_shift = bars_total - 1;
      out_min_shift = m_depth + 1; // ignore forming-bar neighborhood
      out_max_shift = MathMin(m_lookback,out_last_shift - m_depth);
      return (out_max_shift >= out_min_shift);
      }
  };

#endif
