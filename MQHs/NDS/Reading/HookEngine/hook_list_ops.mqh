#ifndef __NDS_HOOK_LIST_OPS_MQH__
#define __NDS_HOOK_LIST_OPS_MQH__

#include "..\\..\\Core\\nds_entities.mqh"

class NdsHookListOps
  {
private:
   void              PushHook(const NdsHookState &hook,NdsHookState &hooks[]) const
      {
      int n = ArraySize(hooks);
      ArrayResize(hooks,n + 1);
      hooks[n] = hook;
      }

public:
   datetime          HookSortTime(const NdsHookState &hook) const
      {
      if(hook.z.bar_time > 0)
         return hook.z.bar_time;
      if(hook.n3.bar_time > 0)
         return hook.n3.bar_time;
      if(hook.n2.bar_time > 0)
         return hook.n2.bar_time;
      return hook.n1.bar_time;
      }

   bool              IsSameHookIdentity(const NdsHookState &a,const NdsHookState &b) const
      {
      if(a.direction != b.direction)
         return false;
      if(a.scan_tf != b.scan_tf)
         return false;
      if(a.n1.bar_time != b.n1.bar_time)
         return false;
      if(a.n2.bar_time != b.n2.bar_time)
         return false;
      if(a.n3.bar_time != b.n3.bar_time)
         return false;
      if(a.z.bar_time != b.z.bar_time)
         return false;
      return true;
      }

   bool              IsSameHookAnchorIdentity(const NdsHookState &a,const NdsHookState &b) const
      {
      if(a.direction != b.direction)
         return false;
      if(a.scan_tf != b.scan_tf)
         return false;
      if(a.start_anchor.kind != b.start_anchor.kind)
         return false;
      if(a.start_anchor.bar_time != b.start_anchor.bar_time)
         return false;
      return true;
      }

   bool              PreferForSameAnchor(const NdsHookState &current,const NdsHookState &candidate) const
      {
      // One anchor = one hook. Keep the more progressed/newer snapshot.
      datetime tc = HookSortTime(current);
      datetime tn = HookSortTime(candidate);
      if(tn > tc)
         return true;
      if(tn < tc)
         return false;

      if(candidate.hook_seq_max > current.hook_seq_max)
         return true;
      if(candidate.hook_seq_max < current.hook_seq_max)
         return false;

      if(candidate.is_closed && !current.is_closed)
         return true;
      if(candidate.is_open && !current.is_open && !candidate.is_closed)
         return true;

      if(candidate.ownership_promotions > current.ownership_promotions)
         return true;
      return false;
      }

   void              SortByCloseTime(NdsHookState &hooks[]) const
      {
      int n = ArraySize(hooks);
      for(int i = 0; i < n - 1; i++)
        {
         for(int j = i + 1; j < n; j++)
           {
            if(HookSortTime(hooks[i]) > HookSortTime(hooks[j]))
              {
               NdsHookState tmp = hooks[i];
               hooks[i] = hooks[j];
               hooks[j] = tmp;
              }
           }
        }
      }

   int               CompactHooksInternal(const NdsHookState &hooks[],NdsHookState &out_hooks[]) const
      {
      ArrayResize(out_hooks,0);
      int n = ArraySize(hooks);
      for(int i = 0; i < n; i++)
        {
         NdsHookState h = hooks[i];
         int m = ArraySize(out_hooks);
         if(m == 0)
           {
            PushHook(h,out_hooks);
            continue;
           }

         NdsHookState last = out_hooks[m - 1];
         if(last.direction != h.direction)
           {
            PushHook(h,out_hooks);
            continue;
           }

         bool non_overlap = (h.n1.bar_time > last.z.bar_time);
         if(non_overlap)
            PushHook(h,out_hooks);
         else
            if(h.z.bar_time > last.z.bar_time)
               out_hooks[m - 1] = h;
        }
      return ArraySize(out_hooks);
      }
  };

#endif
