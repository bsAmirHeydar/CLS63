#ifndef __NDS_SEQUENCE_UPDATE_TRACKER_MQH__
#define __NDS_SEQUENCE_UPDATE_TRACKER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

string g_nds_seq_track_keys[];
long   g_nds_seq_track_peak_sig[];
long   g_nds_seq_track_valley_sig[];
datetime g_nds_seq_track_bar0_time[];

class NdsSequenceUpdateTracker
  {
private:
   string            m_symbol;

   string            Key(const ENUM_TIMEFRAMES tf) const
      {
      return m_symbol + "|" + IntegerToString((int)tf);
      }

   int               FindIndex(const ENUM_TIMEFRAMES tf) const
      {
      string key = Key(tf);
      for(int i = 0; i < ArraySize(g_nds_seq_track_keys); i++)
        {
         if(g_nds_seq_track_keys[i] == key)
            return i;
        }
      return -1;
      }

   int               EnsureIndex(const ENUM_TIMEFRAMES tf) const
      {
      int idx = FindIndex(tf);
      if(idx >= 0)
         return idx;

      int n = ArraySize(g_nds_seq_track_keys);
      ArrayResize(g_nds_seq_track_keys,n + 1);
      ArrayResize(g_nds_seq_track_peak_sig,n + 1);
      ArrayResize(g_nds_seq_track_valley_sig,n + 1);
      ArrayResize(g_nds_seq_track_bar0_time,n + 1);
      g_nds_seq_track_keys[n] = Key(tf);
      g_nds_seq_track_peak_sig[n] = 0;
      g_nds_seq_track_valley_sig[n] = 0;
      g_nds_seq_track_bar0_time[n] = 0;
      return n;
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

public:
   void              Configure(const string symbol)
      {
      m_symbol = symbol;
      }

   bool              EvalAndCommit(const ENUM_TIMEFRAMES tf,const NdsNode &peaks_raw[],const NdsNode &valleys_raw[]) const
      {
      int idx = EnsureIndex(tf);
      long peak_sig = NodeArraySignature(peaks_raw);
      long valley_sig = NodeArraySignature(valleys_raw);
      datetime bar0_t = iTime(m_symbol,tf,0);

      bool changed = (g_nds_seq_track_peak_sig[idx] != peak_sig) ||
                     (g_nds_seq_track_valley_sig[idx] != valley_sig) ||
                     (g_nds_seq_track_bar0_time[idx] != bar0_t);

      g_nds_seq_track_peak_sig[idx] = peak_sig;
      g_nds_seq_track_valley_sig[idx] = valley_sig;
      g_nds_seq_track_bar0_time[idx] = bar0_t;
      return changed;
      }
  };

#endif
