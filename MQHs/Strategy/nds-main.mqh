#ifndef __NDS_MAIN_STRATEGY_MQH__
#define __NDS_MAIN_STRATEGY_MQH__

#include "..\\NDS\\Application\\nds_orchestrator.mqh"

input group "NDS Core"
input string nds_profile_name = "03-71";
input ENUM_TIMEFRAMES nds_htf = PERIOD_H4;
input ENUM_TIMEFRAMES nds_ltf = PERIOD_M5;
input int nds_pivot_depth = 2;
input int nds_lookback_bars = 300;

input group "NDS Gates"
input bool nds_gate_htf = true;
input bool nds_gate_flag = true;
input bool nds_gate_symmetry = true;
input bool nds_gate_86 = false;
input double nds_tol_price_ratio = 0.25;
input double nds_tol_time_ratio = 0.40;
input double nds_tol_near_86 = 0.08;
input double nds_limit_pullback_ratio = 0.50;

input group "NDS Visual"
input bool nds_draw_nodes = true;
input bool nds_draw_sequence = true;
input bool nds_draw_hook = true;
input bool nds_draw_flag = true;
input bool nds_draw_symmetry = true;
input bool nds_draw_rally = true;
input bool nds_draw_cycle = true;
input bool nds_draw_trade_levels = true;
input bool nds_draw_text = true;
input int nds_node_label_offset_points = 10;
input color nds_color_bull = clrLime;
input color nds_color_bear = clrTomato;
input color nds_color_aux = clrGold;

NdsConfig NdsBuildConfig()
  {
   NdsConfig cfg;
   cfg.htf = nds_htf;
   cfg.ltf = nds_ltf;
   cfg.pivot_depth = nds_pivot_depth;
   cfg.lookback_bars = nds_lookback_bars;
   cfg.tolerance_price_ratio = nds_tol_price_ratio;
   cfg.tolerance_time_ratio = nds_tol_time_ratio;
   cfg.near_level86_tolerance = nds_tol_near_86;
   cfg.limit_pullback_ratio = nds_limit_pullback_ratio;
   cfg.use_symmetry_gate = nds_gate_symmetry;
   cfg.use_86_gate = nds_gate_86;
   cfg.use_flag_gate = nds_gate_flag;
   cfg.use_htf_trend_gate = nds_gate_htf;
   cfg.draw_nodes = nds_draw_nodes;
   cfg.draw_sequence = nds_draw_sequence;
   cfg.draw_hook = nds_draw_hook;
   cfg.draw_flag = nds_draw_flag;
   cfg.draw_symmetry = nds_draw_symmetry;
   cfg.draw_rally = nds_draw_rally;
   cfg.draw_cycle = nds_draw_cycle;
   cfg.draw_trade_levels = nds_draw_trade_levels;
   cfg.draw_text = nds_draw_text;
   cfg.node_label_offset_points = nds_node_label_offset_points;
   cfg.color_bull = nds_color_bull;
   cfg.color_bear = nds_color_bear;
   cfg.color_aux = nds_color_aux;
   cfg.profile_name = nds_profile_name;
   return cfg;
  }

class strategy
  {
private:
   bool                 m_inited;
   datetime             m_eval_bar_time;
   NdsOrchestrator      m_orch;
   NdsTradeIntent       m_last_intent;
   NdsExecutionPlan     m_last_plan;

   void                 EnsureInit()
     {
      if(m_inited)
         return;
      NdsConfig cfg = NdsBuildConfig();
      m_orch.Configure(_Symbol,cfg);
      m_eval_bar_time = 0;
      m_inited = true;
     }

   void                 RefreshForCurrentBar()
     {
      EnsureInit();
      datetime bar_time = iTime(_Symbol,_Period,0);
      if(bar_time <= 0)
         return;
      if(bar_time == m_eval_bar_time)
         return;

      m_last_intent = m_orch.Evaluate();
      m_last_plan = m_orch.Plan();
      m_eval_bar_time = bar_time;

      if(!m_last_intent.can_trade)
        {
         orderType = "market";
         entry = 0.0;
         sl = 0.0;
         tp = 0.0;
         return;
        }

      orderType = m_last_plan.order_type;
      entry = m_last_intent.entry;
      sl = m_last_intent.sl;
      tp = (m_last_intent.tp2 != 0.0 ? m_last_intent.tp2 : m_last_intent.tp1);
     }

   int                  SignalFromIntent() const
     {
      if(!m_last_intent.can_trade)
         return 0;
      if(m_last_intent.direction == NDS_DIR_BULL)
         return 1;
      if(m_last_intent.direction == NDS_DIR_BEAR)
         return -1;
      return 0;
     }

public:
   string               orderType;
   double               entry;
   double               sl;
   double               tp;

   int                  Entry()
     {
      RefreshForCurrentBar();
      return SignalFromIntent();
     }

   int                  Exit()
     {
      RefreshForCurrentBar();
      return m_orch.ExitDirection();
     }

   int                  Delete()
      {
      RefreshForCurrentBar();
      return m_orch.InvalidationDirection();
      }

                       strategy(void)
      {
      m_inited = false;
      m_eval_bar_time = 0;
      orderType = "market";
      entry = 0.0;
      sl = 0.0;
      tp = 0.0;
     }
                       ~strategy(void) {}
  };

#endif
