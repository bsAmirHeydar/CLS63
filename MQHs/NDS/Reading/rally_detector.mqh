#ifndef __NDS_RALLY_DETECTOR_MQH__
#define __NDS_RALLY_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"

class NdsRallyDetector
  {
private:
   string            m_symbol;
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
      rally.length = 0.0;

      if(!hook.is_valid || !hook.is_closed)
         return rally;

      double bid = SymbolInfoDouble(m_symbol,SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol,SYMBOL_ASK);
      double close1 = iClose(m_symbol,tf,1);

      if(hook.direction == NDS_DIR_BULL)
        {
         if(close1 > hook.n1.price || bid > hook.n2.price)
           {
            rally.is_valid = true;
            rally.direction = NDS_DIR_BULL;
            rally.start = hook.n3;
            rally.end = hook.n2;
            rally.length = MathAbs(bid - hook.n3.price);
           }
        }
      else
         if(hook.direction == NDS_DIR_BEAR)
           {
            if(close1 < hook.n1.price || ask < hook.n2.price)
              {
               rally.is_valid = true;
               rally.direction = NDS_DIR_BEAR;
               rally.start = hook.n3;
               rally.end = hook.n2;
               rally.length = MathAbs(hook.n3.price - ask);
              }
           }

      return rally;
     }
  };

#endif
