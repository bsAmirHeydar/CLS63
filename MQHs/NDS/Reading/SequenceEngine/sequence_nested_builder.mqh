#ifndef __NDS_SEQUENCE_NESTED_BUILDER_MQH__
#define __NDS_SEQUENCE_NESTED_BUILDER_MQH__

#include "..\\..\\Core\\nds_entities.mqh"
#include "..\\Common\\nds_node_array_ops.mqh"

class NdsSequenceNestedBuilder
  {
private:
   NdsNodeArrayOps   m_nodes;

   void              ClearTailForNested(const bool valley_mode,const double new_price,NdsNode &arr[]) const
      {
      // valley_mode=true  => in reverse scan (newest->oldest), valleys stay non-decreasing
      // valley_mode=false => in reverse scan (newest->oldest), peaks stay non-increasing
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

public:
   int               BuildNestedFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,
                                        NdsNode &out_old_to_new[],int &out_nested_max) const
      {
      ArrayResize(out_old_to_new,0);
      out_nested_max = 0;

      int n = ArraySize(src_old_to_new);
      if(n <= 0)
         return 0;

      NdsNode rev_new_to_old[];
      m_nodes.ReverseNodes(src_old_to_new,rev_new_to_old);

      NdsNode current_rev[];
      m_nodes.PushNode(rev_new_to_old[0],current_rev);
      out_nested_max = 1;

      for(int i = 1; i < n; i++)
        {
         NdsNode nd = rev_new_to_old[i];
         NdsNode prev = rev_new_to_old[i - 1];

         bool continue_same = valley_mode ? (nd.price > prev.price) : (nd.price < prev.price);
         if(continue_same)
           {
            m_nodes.PushNode(nd,current_rev);
           }
         else
           {
            NdsNode next_rev[];
            m_nodes.CopyNodes(current_rev,next_rev);
            ClearTailForNested(valley_mode,nd.price,next_rev);
            m_nodes.PushNode(nd,next_rev);
            m_nodes.CopyNodes(next_rev,current_rev);
           }

         int m = ArraySize(current_rev);
         if(m > out_nested_max)
            out_nested_max = m;
        }

      m_nodes.ReverseNodes(current_rev,out_old_to_new);
      int count = ArraySize(out_old_to_new);
      for(int k = 0; k < count; k++)
         out_old_to_new[k].seq_no = k + 1;

      return count;
      }
  };

#endif
