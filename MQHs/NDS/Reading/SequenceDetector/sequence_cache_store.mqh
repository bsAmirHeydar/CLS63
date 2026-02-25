#ifndef __NDS_SEQUENCE_CACHE_STORE_MQH__
#define __NDS_SEQUENCE_CACHE_STORE_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

string g_nds_seq_cache_keys[];
NdsSequenceState g_nds_seq_cache_vals[];

class NdsSequenceCacheStore
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
      for(int i = 0; i < ArraySize(g_nds_seq_cache_keys); i++)
        {
         if(g_nds_seq_cache_keys[i] == key)
            return i;
        }
      return -1;
      }

public:
   void              Configure(const string symbol)
      {
      m_symbol = symbol;
      }

   bool              TryGet(const ENUM_TIMEFRAMES tf,NdsSequenceState &out_seq) const
      {
      int idx = FindIndex(tf);
      if(idx < 0)
         return false;
      out_seq = g_nds_seq_cache_vals[idx];
      return true;
      }

   void              Put(const ENUM_TIMEFRAMES tf,const NdsSequenceState &seq) const
      {
      int idx = FindIndex(tf);
      if(idx < 0)
        {
         int n = ArraySize(g_nds_seq_cache_keys);
         ArrayResize(g_nds_seq_cache_keys,n + 1);
         ArrayResize(g_nds_seq_cache_vals,n + 1);
         g_nds_seq_cache_keys[n] = Key(tf);
         g_nds_seq_cache_vals[n] = seq;
         return;
        }
      g_nds_seq_cache_vals[idx] = seq;
      }
  };

#endif
