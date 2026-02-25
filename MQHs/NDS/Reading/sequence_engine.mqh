#ifndef __NDS_SEQUENCE_ENGINE_MQH__
#define __NDS_SEQUENCE_ENGINE_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "node_detector.mqh"

class NdsSequenceEngine
  {
private:
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

   void              CopyNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      int n = ArraySize(src);
      ArrayResize(dst,n);
      for(int i = 0; i < n; i++)
         dst[i] = src[i];
      }

   void              ReverseNodes(const NdsNode &src[],NdsNode &dst[]) const
      {
      int n = ArraySize(src);
      ArrayResize(dst,n);
      for(int i = 0; i < n; i++)
         dst[i] = src[n - 1 - i];
      }

   void              PushNode(const NdsNode &nd,NdsNode &arr[]) const
      {
      int n = ArraySize(arr);
      ArrayResize(arr,n + 1);
      arr[n] = nd;
      }

   void              ClearTailForNested(const bool valley_mode,const double new_price,NdsNode &arr[]) const
      {
      // valley_mode=true: keep non-decreasing prices in reverse scan (newest->oldest)
      // valley_mode=false: keep non-increasing prices in reverse scan (newest->oldest)
      while(ArraySize(arr) > 0)
        {
         int last = ArraySize(arr) - 1;
         double p = arr[last].price;
         bool conflict = valley_mode ? (p > new_price) : (p < new_price);
         if(!conflict)
            break;
         ArrayResize(arr,last);
        }
      }

   int               BuildNestedFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,NdsNode &out_old_to_new[],int &out_nested_max) const
      {
      ArrayResize(out_old_to_new,0);
      out_nested_max = 0;

      int n = ArraySize(src_old_to_new);
      if(n <= 0)
         return 0;

      // Scan from end to start (newest -> oldest), as requested.
      NdsNode rev_new_to_old[];
      ReverseNodes(src_old_to_new,rev_new_to_old);

      NdsNode current_rev[];
      PushNode(rev_new_to_old[0],current_rev);
      out_nested_max = 1;

      for(int i = 1; i < n; i++)
        {
         NdsNode nd = rev_new_to_old[i];
         NdsNode prev = rev_new_to_old[i - 1];

         bool continue_same = valley_mode ? (nd.price > prev.price) : (nd.price < prev.price);
         if(continue_same)
           {
            PushNode(nd,current_rev);
           }
         else
           {
            NdsNode next_rev[];
            CopyNodes(current_rev,next_rev);
            ClearTailForNested(valley_mode,nd.price,next_rev);
            PushNode(nd,next_rev);
            CopyNodes(next_rev,current_rev);
           }

         int m = ArraySize(current_rev);
         if(m > out_nested_max)
            out_nested_max = m;
        }

      // Numbering must be from start to end (oldest -> newest).
      ReverseNodes(current_rev,out_old_to_new);
      int count = ArraySize(out_old_to_new);
      for(int k = 0; k < count; k++)
         out_old_to_new[k].seq_no = k + 1;

      return count;
      }

public:
   NdsSequenceState  Build(const ENUM_TIMEFRAMES tf,const NdsNodeDetector &detector) const
      {
      NdsSequenceState seq;
      seq.last_peak_1 = EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_2 = EmptyNode(NDS_NODE_PEAK);
      seq.last_peak_3 = EmptyNode(NDS_NODE_PEAK);
      seq.last_valley_1 = EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_2 = EmptyNode(NDS_NODE_VALLEY);
      seq.last_valley_3 = EmptyNode(NDS_NODE_VALLEY);
      seq.has_open_12_up = false;
      seq.has_open_12_down = false;
      seq.peak_active_len = 0;
      seq.valley_active_len = 0;
      seq.peak_max_len = 0;
      seq.valley_max_len = 0;
      seq.is_valid = false;

      NdsNode peaks_raw[];
      NdsNode valleys_raw[];
      detector.FindRecentNodes(tf,NDS_NODE_PEAK,0,peaks_raw);     // oldest -> newest
      detector.FindRecentNodes(tf,NDS_NODE_VALLEY,0,valleys_raw); // oldest -> newest

      NdsNode peaks_seq[];
      NdsNode valleys_seq[];
      int peaks_nested_max = 0;
      int valleys_nested_max = 0;
      int peak_count = BuildNestedFromEnd(peaks_raw,false,peaks_seq,peaks_nested_max);      // peaks: reverse-trend inside sequence
      int valley_count = BuildNestedFromEnd(valleys_raw,true,valleys_seq,valleys_nested_max); // valleys: reverse-trend inside sequence
      seq.peak_active_len = peak_count;
      seq.valley_active_len = valley_count;
      seq.peak_max_len = peaks_nested_max;
      seq.valley_max_len = valleys_nested_max;

      if(peak_count >= 1)
        {
         seq.last_peak_3 = peaks_seq[peak_count - 1];
         seq.last_peak_3.seq_no = 3;
        }
      if(peak_count >= 2)
        {
         seq.last_peak_2 = peaks_seq[peak_count - 2];
         seq.last_peak_2.seq_no = 2;
        }
      if(peak_count >= 3)
        {
         seq.last_peak_1 = peaks_seq[peak_count - 3];
         seq.last_peak_1.seq_no = 1;
        }

      if(valley_count >= 1)
        {
         seq.last_valley_3 = valleys_seq[valley_count - 1];
         seq.last_valley_3.seq_no = 3;
        }
      if(valley_count >= 2)
        {
         seq.last_valley_2 = valleys_seq[valley_count - 2];
         seq.last_valley_2.seq_no = 2;
        }
      if(valley_count >= 3)
        {
         seq.last_valley_1 = valleys_seq[valley_count - 3];
         seq.last_valley_1.seq_no = 1;
        }

      bool peaks_down = (peak_count >= 3 &&
                         seq.last_peak_1.price > seq.last_peak_2.price &&
                         seq.last_peak_2.price > seq.last_peak_3.price);
      bool valleys_up = (valley_count >= 3 &&
                         seq.last_valley_1.price < seq.last_valley_2.price &&
                         seq.last_valley_2.price < seq.last_valley_3.price);

      seq.has_open_12_up = (valley_count == 2);
      seq.has_open_12_down = (peak_count == 2);
      seq.is_valid = (peaks_down || valleys_up || seq.peak_max_len >= 3 || seq.valley_max_len >= 3);

      return seq;
      }
  };

#endif
