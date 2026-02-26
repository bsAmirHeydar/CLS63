#ifndef __NDS_ENTITIES_MQH__
#define __NDS_ENTITIES_MQH__

#include "nds_types.mqh"

struct NdsNode
  {
   int               kind;           // peak/valley
   int               seq_no;         // sequence number 1/2/3...
   int               bar_index;
   datetime          bar_time;
   double            price;
   bool              is_open;        // open 1/2 not closed by 3
  };

struct NdsNodeSet
  {
   ENUM_TIMEFRAMES   tf;
   datetime          sampled_at;
   NdsNode           peaks[];
   NdsNode           valleys[];
  };

struct NdsSequenceState
  {
   NdsNode           last_peak_1;
   NdsNode           last_peak_2;
   NdsNode           last_peak_3;
   NdsNode           last_valley_1;
   NdsNode           last_valley_2;
   NdsNode           last_valley_3;
   bool              has_open_12_up;
   bool              has_open_12_down;
   int               peak_active_len;
   int               valley_active_len;
   int               peak_max_len;
   int               valley_max_len;
   bool              is_valid;
  };

struct NdsHookState
  {
   bool              is_valid;
   int               direction;      // NdsDirection
   int               hook_type;      // NdsHookType
   ENUM_TIMEFRAMES   scan_tf;        // timeframe used for this hook detection
   ENUM_TIMEFRAMES   seed_tf;        // initial timeframe before ownership promotion
   int               ownership_promotions; // number of TF promotions applied
   int               hook_seq_max;   // max(primary_max_len,secondary_max_len) at owned TF
   NdsNode           n1;
   NdsNode           n2;
   NdsNode           n3;
   NdsNode           z;              // closure node after 3 (hook completion)
   NdsNode           start_anchor;   // logical hook start from sequence boundary
   bool              start_unbroken; // anchor has not been violated yet
   int               primary_layers; // related sequence layers in hook direction
   int               secondary_layers;
   int               primary_max_len;
   int               secondary_max_len;
   bool              is_open;        // hook valid but close condition not yet satisfied
   double            level_86;
   bool              is_closed;
  };

struct NdsRallyState
  {
   bool              is_valid;
   int               direction;      // NdsDirection
   NdsNode           start;
   NdsNode           end;
   double            length;
  };

struct NdsFlagState
  {
   bool              is_valid;
   int               direction;      // direction of expected continuation
   NdsNode           f1;
   NdsNode           f2;
   NdsNode           f3;
   NdsNode           f4;
  };

struct NdsSymmetryState
  {
   bool              is_valid;
   double            price_ratio;
   double            time_ratio;
   double            target_price;
   bool              is_near_86;
  };

struct NdsCycleState
  {
   bool              is_valid;
   int               direction;      // NdsDirection
   int               phase;          // NdsCyclePhase
   int               hooks_count;
   int               rallies_count;
   bool              has_flag;
   bool              has_hook2;
   bool              has_rally_after_hook2;
   NdsHookState      hook1;
   NdsHookState      hook2;
   NdsRallyState     rally_after_hook2;
  };

struct NdsSnapshot
  {
   bool              is_valid;
   string            symbol;
   ENUM_TIMEFRAMES   tf_htf;
   ENUM_TIMEFRAMES   tf_ltf;
   datetime          now_time;
   NdsSequenceState  sequence;
   NdsHookState      hook;
   NdsRallyState     rally;
   NdsFlagState      flag;
   NdsSymmetryState  symmetry;
   NdsCycleState     cycle;
  };

struct NdsTradeIntent
  {
   bool              can_trade;
   int               direction;      // NdsDirection
   int               order_mode;     // NdsOrderMode
   string            reason;
   double            entry;
   double            sl;
   double            tp1;
   double            tp2;
   double            confidence;
  };

struct NdsExecutionPlan
  {
   bool              can_execute;
   int               direction;
   string            order_type;     // market/limit/stop
   double            entry;
   double            sl;
   double            tp;
   double            risk_pct;
  };

#endif
