#ifndef __NDS_HOOK_SEED_UPDATE_TRACKER_MQH__
#define __NDS_HOOK_SEED_UPDATE_TRACKER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

string g_nds_hook_seed_stamp_keys[];
datetime g_nds_hook_seed_last_peak_time[];
datetime g_nds_hook_seed_last_valley_time[];
long g_nds_hook_seed_peak_sig[];
long g_nds_hook_seed_valley_sig[];
datetime g_nds_hook_seed_bar0_time[];
double g_nds_hook_seed_bar0_high[];
double g_nds_hook_seed_bar0_low[];

class NdsHookSeedUpdateTracker
  {
private:
   string            m_symbol;

   string            SeedStampKey(const ENUM_TIMEFRAMES seed_tf) const
      {
      return m_symbol + "|" + IntegerToString((int)seed_tf);
      }

   int               FindSeedStampIndex(const ENUM_TIMEFRAMES seed_tf) const
      {
      string key = SeedStampKey(seed_tf);
      for(int i = 0; i < ArraySize(g_nds_hook_seed_stamp_keys); i++)
        {
         if(g_nds_hook_seed_stamp_keys[i] == key)
            return i;
        }
      return -1;
      }

   int               EnsureSeedStampIndex(const ENUM_TIMEFRAMES seed_tf) const
      {
      int idx = FindSeedStampIndex(seed_tf);
      if(idx >= 0)
         return idx;

      int n = ArraySize(g_nds_hook_seed_stamp_keys);
      ArrayResize(g_nds_hook_seed_stamp_keys,n + 1);
      ArrayResize(g_nds_hook_seed_last_peak_time,n + 1);
      ArrayResize(g_nds_hook_seed_last_valley_time,n + 1);
      ArrayResize(g_nds_hook_seed_peak_sig,n + 1);
      ArrayResize(g_nds_hook_seed_valley_sig,n + 1);
      ArrayResize(g_nds_hook_seed_bar0_time,n + 1);
      ArrayResize(g_nds_hook_seed_bar0_high,n + 1);
      ArrayResize(g_nds_hook_seed_bar0_low,n + 1);
      g_nds_hook_seed_stamp_keys[n] = SeedStampKey(seed_tf);
      g_nds_hook_seed_last_peak_time[n] = 0;
      g_nds_hook_seed_last_valley_time[n] = 0;
      g_nds_hook_seed_peak_sig[n] = 0;
      g_nds_hook_seed_valley_sig[n] = 0;
      g_nds_hook_seed_bar0_time[n] = 0;
      g_nds_hook_seed_bar0_high[n] = 0.0;
      g_nds_hook_seed_bar0_low[n] = 0.0;
      return n;
      }

   datetime          LatestNodeTime(const NdsNode &nodes[]) const
      {
      int n = ArraySize(nodes);
      if(n <= 0)
         return 0;
      return nodes[n - 1].bar_time;
      }

   long              NodeArraySignature(const NdsNode &nodes[]) const
      {
      int n = ArraySize(nodes);
      long sig = (long)n * 1469598103934665603;
      for(int i = 0; i < n; i++)
        {
         long t = (long)nodes[i].bar_time;
         long p = (long)MathRound(nodes[i].price / _Point);
         long k = (long)nodes[i].kind * 1315423911 + (long)nodes[i].seq_no * 2654435761;
         sig ^= (t + 0x9e3779b97f4a7c15);
         sig *= 1099511628211;
         sig ^= (p + (k << 1));
         sig *= 1099511628211;
        }
      return sig;
      }

   bool              DiffPrice(const double a,const double b) const
      {
      double eps = MathMax(_Point * 0.1,1e-12);
      return (MathAbs(a - b) > eps);
      }

public:
   void              Configure(const string symbol)
      {
      m_symbol = symbol;
      }

   void              EvalAndCommit(const ENUM_TIMEFRAMES scan_tf,const NdsNode &peaks_raw[],const NdsNode &valleys_raw[],
                                   bool &bull_update,bool &bear_update) const
      {
      bull_update = false;
      bear_update = false;

      datetime latest_peak_t = LatestNodeTime(peaks_raw);
      datetime latest_valley_t = LatestNodeTime(valleys_raw);
      long peak_sig = NodeArraySignature(peaks_raw);
      long valley_sig = NodeArraySignature(valleys_raw);

      int stamp_idx = EnsureSeedStampIndex(scan_tf);

      datetime bar0_t = iTime(m_symbol,scan_tf,0);
      double bar0_hi = iHigh(m_symbol,scan_tf,0);
      double bar0_lo = iLow(m_symbol,scan_tf,0);
      bool bar0_time_changed = (g_nds_hook_seed_bar0_time[stamp_idx] != bar0_t);
      bool bar0_high_changed = bar0_time_changed || DiffPrice(g_nds_hook_seed_bar0_high[stamp_idx],bar0_hi);
      bool bar0_low_changed = bar0_time_changed || DiffPrice(g_nds_hook_seed_bar0_low[stamp_idx],bar0_lo);

      bool peak_changed = (g_nds_hook_seed_last_peak_time[stamp_idx] != latest_peak_t) ||
                          (g_nds_hook_seed_peak_sig[stamp_idx] != peak_sig);
      bool valley_changed = (g_nds_hook_seed_last_valley_time[stamp_idx] != latest_valley_t) ||
                            (g_nds_hook_seed_valley_sig[stamp_idx] != valley_sig);

      bool any_node_changed = (peak_changed || valley_changed);
      bull_update = any_node_changed || bar0_high_changed;
      bear_update = any_node_changed || bar0_low_changed;

      g_nds_hook_seed_last_peak_time[stamp_idx] = latest_peak_t;
      g_nds_hook_seed_last_valley_time[stamp_idx] = latest_valley_t;
      g_nds_hook_seed_peak_sig[stamp_idx] = peak_sig;
      g_nds_hook_seed_valley_sig[stamp_idx] = valley_sig;
      g_nds_hook_seed_bar0_time[stamp_idx] = bar0_t;
      g_nds_hook_seed_bar0_high[stamp_idx] = bar0_hi;
      g_nds_hook_seed_bar0_low[stamp_idx] = bar0_lo;
      }
  };

#endif
