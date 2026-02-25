#ifndef __NDS_HOOK_NODE_OPS_MQH__
#define __NDS_HOOK_NODE_OPS_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"
#include "hook_state_factory.mqh"

class NdsHookNodeOps
  {
private:
   NdsHookStateFactory m_factory;

public:
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

   int               FindLastNodeIndexAtOrBeforeTime(const NdsNode &nodes[],const datetime t) const
      {
      int n = ArraySize(nodes);
      if(n <= 0 || t <= 0)
         return -1;

      int idx = -1;
      for(int i = 0; i < n; i++)
        {
         if(nodes[i].bar_time <= t)
            idx = i;
         else
            break;
        }
      return idx;
      }

   int               SliceNodesByTime(const NdsNode &src_old_to_new[],const datetime from_t,const datetime to_t,NdsNode &out_nodes[]) const
      {
      ArrayResize(out_nodes,0);
      int n = ArraySize(src_old_to_new);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = src_old_to_new[i];
         if(nd.bar_time < from_t)
            continue;
         if(to_t > 0 && nd.bar_time > to_t)
            continue;
         PushNode(nd,out_nodes);
        }
      return ArraySize(out_nodes);
      }

   void              SelectLast123FromSequence(const NdsNode &seq_old_to_new[],NdsNode &out_n1,NdsNode &out_n2,NdsNode &out_n3) const
      {
      out_n1 = m_factory.EmptyNode(NDS_NODE_NONE);
      out_n2 = m_factory.EmptyNode(NDS_NODE_NONE);
      out_n3 = m_factory.EmptyNode(NDS_NODE_NONE);

      int n = ArraySize(seq_old_to_new);
      if(n <= 0)
         return;

      int base = (n >= 3 ? n - 3 : 0);
      out_n1 = seq_old_to_new[base];
      out_n2 = seq_old_to_new[MathMin(base + 1,n - 1)];
      out_n3 = seq_old_to_new[MathMin(base + 2,n - 1)];
      }
  };

#endif
