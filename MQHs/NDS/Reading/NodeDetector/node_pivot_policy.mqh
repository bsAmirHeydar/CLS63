#ifndef __NDS_NODE_PIVOT_POLICY_MQH__
#define __NDS_NODE_PIVOT_POLICY_MQH__

class NdsNodePivotPolicy
  {
private:
   string            m_symbol;
   int               m_depth;

   double            PriceEps(void) const
      {
      return MathMax(_Point * 0.1,1e-12);
      }

   bool              NearlyEqual(const double a,const double b) const
      {
      return (MathAbs(a - b) <= PriceEps());
      }

   double            PivotPrice(const ENUM_TIMEFRAMES tf,const int kind,const int shift) const
      {
      if(kind == NDS_NODE_PEAK)
         return iHigh(m_symbol,tf,shift);
      return iLow(m_symbol,tf,shift);
      }

   void              ExpandEqualPlateau(const ENUM_TIMEFRAMES tf,const int kind,const int shift,const int last_shift,
                                        int &out_newest_shift,int &out_oldest_shift,double &out_price) const
      {
      out_price = PivotPrice(tf,kind,shift);
      out_newest_shift = shift;
      out_oldest_shift = shift;

      // Expand toward newer bars (smaller shift)
      while(out_newest_shift - 1 >= 1)
        {
         double p = PivotPrice(tf,kind,out_newest_shift - 1);
         if(!NearlyEqual(p,out_price))
            break;
         out_newest_shift--;
        }

      // Expand toward older bars (larger shift)
      while(out_oldest_shift + 1 <= last_shift)
        {
         double p = PivotPrice(tf,kind,out_oldest_shift + 1);
         if(!NearlyEqual(p,out_price))
            break;
         out_oldest_shift++;
        }
      }

   bool              HasDepthAroundPlateau(const int newest_shift,const int oldest_shift,const int last_shift) const
      {
      if(newest_shift - m_depth < 1)
         return false;
      if(oldest_shift + m_depth > last_shift)
         return false;
      return true;
      }

public:
   void              Configure(const string symbol,const int depth)
      {
      m_symbol = symbol;
      m_depth = MathMax(1,depth);
      }

   int               Depth(void) const
      {
      return m_depth;
      }

   bool              IsPeakPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      int plateau_newest = shift;
      int plateau_oldest = shift;
      double top = 0.0;
      ExpandEqualPlateau(tf,NDS_NODE_PEAK,shift,last_shift,plateau_newest,plateau_oldest,top);

      // Treat adjacent equal highs as one pivot. Keep only one representative (newest candle of plateau).
      if(shift != plateau_newest)
         return false;

      if(!HasDepthAroundPlateau(plateau_newest,plateau_oldest,last_shift))
         return false;

      double eps = PriceEps();
      for(int k = 1; k <= m_depth; k++)
        {
         double right = iHigh(m_symbol,tf,plateau_newest - k); // newer side outside plateau
         double left = iHigh(m_symbol,tf,plateau_oldest + k);  // older side outside plateau
         if(right >= top - eps)
            return false;
         if(left >= top - eps)
            return false;
        }
      return true;
      }

   bool              IsValleyPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      int plateau_newest = shift;
      int plateau_oldest = shift;
      double bottom = 0.0;
      ExpandEqualPlateau(tf,NDS_NODE_VALLEY,shift,last_shift,plateau_newest,plateau_oldest,bottom);

      // Treat adjacent equal lows as one pivot. Keep only one representative (newest candle of plateau).
      if(shift != plateau_newest)
         return false;

      if(!HasDepthAroundPlateau(plateau_newest,plateau_oldest,last_shift))
         return false;

      double eps = PriceEps();
      for(int k = 1; k <= m_depth; k++)
        {
         double right = iLow(m_symbol,tf,plateau_newest - k); // newer side outside plateau
         double left = iLow(m_symbol,tf,plateau_oldest + k);  // older side outside plateau
         if(right <= bottom + eps)
            return false;
         if(left <= bottom + eps)
            return false;
        }
      return true;
      }

   bool              IsPivot(const ENUM_TIMEFRAMES tf,const int kind,const int shift,const int last_shift) const
      {
      if(kind == NDS_NODE_PEAK)
         return IsPeakPivot(tf,shift,last_shift);
      if(kind == NDS_NODE_VALLEY)
         return IsValleyPivot(tf,shift,last_shift);
      return false;
      }
  };

#endif
