#ifndef __NDS_RALLY_DETECTOR_MQH__
#define __NDS_RALLY_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"

class NdsRallyDetector
  {
private:
   string            m_symbol;

   NdsNode           EmptyNode(const int kind) const
     {
      NdsNode nd;
      nd.kind = kind;
      nd.seq_no = 0;
      nd.bar_index = -1;
      nd.bar_time = 0;
      nd.price = 0.0;
      nd.is_open = false;
      return nd;
     }
public:
   void              Configure(const string symbol)
     {
      m_symbol = symbol;
     }
   NdsRallyState     Detect(const ENUM_TIMEFRAMES tf,const NdsHookState &hook) const
     {
      NdsRallyState rally;
      rally.is_valid = false;
      rally.direction = NDS_DIR_NONE;
      rally.start = EmptyNode(NDS_NODE_NONE);
      rally.end = EmptyNode(NDS_NODE_NONE);
      rally.length = 0.0;

      if(!hook.is_valid || !hook.is_closed)
         return rally;

      int start_shift = hook.z.bar_index;
      if(start_shift < 2)
         return rally;

      if(hook.direction == NDS_DIR_BULL)
        {
         int count = start_shift;
         int hh_shift = iHighest(m_symbol,tf,MODE_HIGH,count,1);
         if(hh_shift < 0)
            return rally;

         double hh = iHigh(m_symbol,tf,hh_shift);
         if(hh <= hook.n3.price)
            return rally;

         rally.is_valid = true;
         rally.direction = NDS_DIR_BULL;
         rally.start = hook.z;
         rally.end.kind = NDS_NODE_PEAK;
         rally.end.seq_no = 1;
         rally.end.bar_index = hh_shift;
         rally.end.bar_time = iTime(m_symbol,tf,hh_shift);
         rally.end.price = hh;
         rally.end.is_open = false;
         rally.length = MathAbs(rally.end.price - rally.start.price);
        }
      else
         if(hook.direction == NDS_DIR_BEAR)
           {
            int count = start_shift;
            int ll_shift = iLowest(m_symbol,tf,MODE_LOW,count,1);
            if(ll_shift < 0)
               return rally;

            double ll = iLow(m_symbol,tf,ll_shift);
            if(ll >= hook.n3.price)
               return rally;

            rally.is_valid = true;
            rally.direction = NDS_DIR_BEAR;
            rally.start = hook.z;
            rally.end.kind = NDS_NODE_VALLEY;
            rally.end.seq_no = 1;
            rally.end.bar_index = ll_shift;
            rally.end.bar_time = iTime(m_symbol,tf,ll_shift);
            rally.end.price = ll;
            rally.end.is_open = false;
            rally.length = MathAbs(rally.start.price - rally.end.price);
           }

      return rally;
     }
  };

#endif
