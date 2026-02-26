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
                                        int &out_newest_shift,int &out_oldest_shift,double &out_price,
                                        const int newer_floor_shift = 0) const
      {
      out_price = PivotPrice(tf,kind,shift);
      out_newest_shift = shift;
      out_oldest_shift = shift;

      // Expand toward newer bars (smaller shift)
      while(out_newest_shift - 1 >= newer_floor_shift)
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
      if(newest_shift - m_depth < 0)
         return false;
      if(oldest_shift + m_depth > last_shift)
         return false;
      return true;
      }

   bool              HasLeftDepthForOpenPlateau(const int oldest_shift,const int last_shift) const
      {
      if(oldest_shift + m_depth > last_shift)
         return false;
      return true;
      }

   bool              IsOpenZoneShift(const int shift) const
      {
      // Right-edge temporary zone: pivots that are still inside the "unconfirmed neighborhood"
      // and may change before enough right-side depth is formed.
      return (shift >= 0 && shift < m_depth);
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
      // For confirmed pivots, do not let temporary/open-zone equal candles steal/move an already confirmed node.
      ExpandEqualPlateau(tf,NDS_NODE_PEAK,shift,last_shift,plateau_newest,plateau_oldest,top,m_depth);

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
      ExpandEqualPlateau(tf,NDS_NODE_VALLEY,shift,last_shift,plateau_newest,plateau_oldest,bottom,m_depth);

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

   bool              IsCurrentOpenPeakPivot(const ENUM_TIMEFRAMES tf,const int last_shift) const
      {
      return IsOpenPeakPivot(tf,0,last_shift);
      }

   bool              IsCurrentOpenValleyPivot(const ENUM_TIMEFRAMES tf,const int last_shift) const
      {
      return IsOpenValleyPivot(tf,0,last_shift);
      }

   bool              IsOpenPeakPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      if(last_shift < 1 || shift < 0 || shift > last_shift)
         return false;
      if(!IsOpenZoneShift(shift))
         return false;

      int plateau_newest = shift;
      int plateau_oldest = shift;
      double top = 0.0;
      ExpandEqualPlateau(tf,NDS_NODE_PEAK,shift,last_shift,plateau_newest,plateau_oldest,top,0);

      // Keep one representative for equal-high plateau: newest candle of plateau.
      if(shift != plateau_newest)
         return false;
      // Still inside open/right-edge zone, otherwise it belongs to confirmed scan.
      if(!IsOpenZoneShift(plateau_newest))
         return false;
      if(!HasLeftDepthForOpenPlateau(plateau_oldest,last_shift))
         return false;

      double eps = PriceEps();
      // Check all available newer bars (may be fewer than depth while still temporary).
      for(int k = 1; k <= plateau_newest; k++)
        {
         double right = iHigh(m_symbol,tf,plateau_newest - k);
         if(right >= top - eps)
            return false;
        }
      // Check full left depth.
      for(int k = 1; k <= m_depth; k++)
        {
         double left = iHigh(m_symbol,tf,plateau_oldest + k);
         if(left >= top - eps)
            return false;
        }
      return true;
      }

   bool              IsOpenValleyPivot(const ENUM_TIMEFRAMES tf,const int shift,const int last_shift) const
      {
      if(last_shift < 1 || shift < 0 || shift > last_shift)
         return false;
      if(!IsOpenZoneShift(shift))
         return false;

      int plateau_newest = shift;
      int plateau_oldest = shift;
      double bottom = 0.0;
      ExpandEqualPlateau(tf,NDS_NODE_VALLEY,shift,last_shift,plateau_newest,plateau_oldest,bottom,0);

      if(shift != plateau_newest)
         return false;
      if(!IsOpenZoneShift(plateau_newest))
         return false;
      if(!HasLeftDepthForOpenPlateau(plateau_oldest,last_shift))
         return false;

      double eps = PriceEps();
      for(int k = 1; k <= plateau_newest; k++)
        {
         double right = iLow(m_symbol,tf,plateau_newest - k);
         if(right <= bottom + eps)
            return false;
        }
      for(int k = 1; k <= m_depth; k++)
        {
         double left = iLow(m_symbol,tf,plateau_oldest + k);
         if(left <= bottom + eps)
            return false;
        }
      return true;
      }

   bool              IsCurrentOpenPivot(const ENUM_TIMEFRAMES tf,const int kind,const int last_shift) const
      {
      if(kind == NDS_NODE_PEAK)
         return IsCurrentOpenPeakPivot(tf,last_shift);
      if(kind == NDS_NODE_VALLEY)
         return IsCurrentOpenValleyPivot(tf,last_shift);
      return false;
      }

   bool              IsOpenPivot(const ENUM_TIMEFRAMES tf,const int kind,const int shift,const int last_shift) const
      {
      if(kind == NDS_NODE_PEAK)
         return IsOpenPeakPivot(tf,shift,last_shift);
      if(kind == NDS_NODE_VALLEY)
         return IsOpenValleyPivot(tf,shift,last_shift);
      return false;
      }
  };

#endif
