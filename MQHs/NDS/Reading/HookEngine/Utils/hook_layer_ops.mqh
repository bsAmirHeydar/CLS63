#ifndef __NDS_HOOK_LAYER_OPS_MQH__
#define __NDS_HOOK_LAYER_OPS_MQH__

#include "..\\Types\\hook_seq_layer.mqh"
#include "hook_node_ops.mqh"

class NdsHookLayerOps
  {
private:
   NdsHookNodeOps    m_node_ops;

   void              ClearTailForNested(const bool valley_mode,const double new_price,NdsNode &arr[]) const
      {
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

   void              CopyLayer(const NdsHookSeqLayer &src,NdsHookSeqLayer &dst) const
      {
      m_node_ops.CopyNodes(src.nodes,dst.nodes);
      }

public:
   void              BuildNestedLayersFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,NdsHookSeqLayer &layers[]) const
      {
      ArrayResize(layers,0);
      int n = ArraySize(src_old_to_new);
      if(n <= 0)
         return;

      NdsNode rev_new_to_old[];
      m_node_ops.ReverseNodes(src_old_to_new,rev_new_to_old);

      ArrayResize(layers,1);
      ArrayResize(layers[0].nodes,0);
      m_node_ops.PushNode(rev_new_to_old[0],layers[0].nodes);

      for(int i = 1; i < n; i++)
        {
         NdsNode nd = rev_new_to_old[i];
         NdsNode prev = rev_new_to_old[i - 1];
         int last = ArraySize(layers) - 1;

         bool continue_same = valley_mode ? (nd.price > prev.price) : (nd.price < prev.price);
         if(continue_same)
           {
            m_node_ops.PushNode(nd,layers[last].nodes);
           }
         else
           {
            int next_index = last + 1;
            ArrayResize(layers,next_index + 1);
            CopyLayer(layers[last],layers[next_index]);
            ClearTailForNested(valley_mode,nd.price,layers[next_index].nodes);
            m_node_ops.PushNode(nd,layers[next_index].nodes);
           }
        }
      }

   void              CollectLayerStatsAndRepresentative(const NdsHookSeqLayer &layers[],const datetime from_t,const datetime to_t,
                                                        int &out_layers,int &out_max_len,NdsNode &out_rep_old_to_new[]) const
      {
      out_layers = 0;
      out_max_len = 0;
      ArrayResize(out_rep_old_to_new,0);

      datetime rep_last_time = 0;
      int n = ArraySize(layers);
      for(int i = 0; i < n; i++)
        {
         NdsNode ord_old_to_new[];
         m_node_ops.ReverseNodes(layers[i].nodes,ord_old_to_new);

         NdsNode window_nodes[];
         int len = m_node_ops.SliceNodesByTime(ord_old_to_new,from_t,to_t,window_nodes);
         if(len <= 0)
            continue;

         out_layers++;
         datetime last_t = window_nodes[len - 1].bar_time;
         bool better = (len > out_max_len) || (len == out_max_len && last_t > rep_last_time);
         if(better)
           {
            out_max_len = len;
            rep_last_time = last_t;
            m_node_ops.CopyNodes(window_nodes,out_rep_old_to_new);
           }
        }
      }
  };

#endif
