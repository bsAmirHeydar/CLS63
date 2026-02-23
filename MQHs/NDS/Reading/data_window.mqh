#ifndef __NDS_DATA_WINDOW_MQH__
#define __NDS_DATA_WINDOW_MQH__

class NdsDataWindow
  {
private:
   string            m_symbol;
public:
                     NdsDataWindow(void)
     {
      m_symbol = _Symbol;
     }
                     NdsDataWindow(const string symbol)
     {
      m_symbol = symbol;
     }
   bool              IsReady(const ENUM_TIMEFRAMES tf,const int min_bars) const
     {
      return Bars(m_symbol,tf) >= min_bars;
     }
   double            High(const ENUM_TIMEFRAMES tf,const int shift) const
     {
      return iHigh(m_symbol,tf,shift);
     }
   double            Low(const ENUM_TIMEFRAMES tf,const int shift) const
     {
      return iLow(m_symbol,tf,shift);
     }
   double            Close(const ENUM_TIMEFRAMES tf,const int shift) const
     {
      return iClose(m_symbol,tf,shift);
     }
   datetime          Time(const ENUM_TIMEFRAMES tf,const int shift) const
     {
      return iTime(m_symbol,tf,shift);
     }
   int               CountBars(const ENUM_TIMEFRAMES tf) const
     {
      return Bars(m_symbol,tf);
     }
  };

#endif
