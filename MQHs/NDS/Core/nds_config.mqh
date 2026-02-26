#ifndef __NDS_CONFIG_MQH__
#define __NDS_CONFIG_MQH__

struct NdsConfig
  {
   ENUM_TIMEFRAMES   htf;
   ENUM_TIMEFRAMES   ltf;
   int               pivot_depth;
   int               lookback_bars;
   double            tolerance_price_ratio;
   double            tolerance_time_ratio;
   double            near_level86_tolerance;
   double            limit_pullback_ratio;
   double            hook_close_retrace_ratio; // 0..1, required retrace after Z to mark hook closed
   bool              use_symmetry_gate;
   bool              use_86_gate;
   bool              use_flag_gate;
   bool              use_htf_trend_gate;
   ENUM_TIMEFRAMES   node_display_tf;
   bool              draw_node_points;
   bool              draw_node_points_on_chart_tf;
   bool              draw_nodes;
   bool              draw_sequence;
   bool              draw_hook;
   bool              draw_flag;
   bool              draw_symmetry;
   bool              draw_rally;
   bool              draw_cycle;
   bool              draw_trade_levels;
   bool              draw_text;
   int               node_label_offset_points;
   color             color_bull;
   color             color_bear;
   color             color_aux;
   string            profile_name;
  };

#endif
