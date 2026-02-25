#ifndef __NDS_HOOK_BOUNDARY_OPS_MQH__
#define __NDS_HOOK_BOUNDARY_OPS_MQH__

#include "..\\..\\..\\Core\\nds_entities.mqh"
#include "hook_state_factory.mqh"

class NdsHookBoundaryOps
  {
private:
   NdsHookStateFactory m_factory;

public:
   bool              FindBoundaryFromEnd(const NdsNode &nodes[],const int end_idx,const bool valley_mode,NdsNode &out_boundary) const
      {
      out_boundary = m_factory.EmptyNode(NDS_NODE_NONE);
      int n = ArraySize(nodes);
      if(n <= 0 || end_idx <= 0 || end_idx >= n)
         return false;

      double eps = MathMax(_Point * 0.1,1e-12);
      double ref = nodes[end_idx].price;
      for(int i = end_idx - 1; i >= 0; i--)
        {
         double p = nodes[i].price;
         if(valley_mode)
           {
            if(p > ref + eps)
              {
               ref = p;
               continue;
              }
            if(p < ref - eps)
              {
               out_boundary = nodes[i];
               return true;
              }
           }
         else
           {
            if(p < ref - eps)
              {
               ref = p;
               continue;
              }
            if(p > ref + eps)
              {
               out_boundary = nodes[i];
               return true;
              }
           }
        }
      return false;
      }

   bool              FindZAfterPrimary(const NdsNode &opposite_nodes[],const datetime after_t,const datetime to_t,const int hook_dir,NdsNode &out_z) const
      {
      out_z = m_factory.EmptyNode((hook_dir == NDS_DIR_BULL) ? NDS_NODE_VALLEY : NDS_NODE_PEAK);
      bool found = false;
      double eps = MathMax(_Point * 0.1,1e-12);

      int n = ArraySize(opposite_nodes);
      for(int i = 0; i < n; i++)
        {
         NdsNode nd = opposite_nodes[i];
         if(nd.bar_time <= after_t)
            continue;
         if(to_t > 0 && nd.bar_time > to_t)
            continue;

         if(!found)
           {
            out_z = nd;
            found = true;
            continue;
           }

         if(hook_dir == NDS_DIR_BULL)
           {
            bool better = (nd.price < out_z.price - eps) || (MathAbs(nd.price - out_z.price) <= eps && nd.bar_time > out_z.bar_time);
            if(better)
               out_z = nd;
           }
         else
            if(hook_dir == NDS_DIR_BEAR)
              {
               bool better = (nd.price > out_z.price + eps) || (MathAbs(nd.price - out_z.price) <= eps && nd.bar_time > out_z.bar_time);
               if(better)
                  out_z = nd;
              }
        }
      return found;
      }
  };

#endif
