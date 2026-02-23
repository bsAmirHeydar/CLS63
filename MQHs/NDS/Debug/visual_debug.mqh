#ifndef __NDS_VISUAL_DEBUG_MQH__
#define __NDS_VISUAL_DEBUG_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"
#include "..\\Infrastructure\\diagnostics.mqh"

class NdsVisualDebug
  {
private:
   string            m_prefix;
   NdsConfig         m_cfg;

   string            Key(const string suffix) const
     {
      return m_prefix + "_" + suffix;
     }

   void              DrawArrow(const string name,const datetime t,const double p,const color c,const int code) const
     {
      if(t <= 0 || p <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_ARROW,0,t,p);
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,code);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
     }

   void              DrawLabel(const string name,const datetime t,const double p,const string text,const color c) const
     {
      if(t <= 0 || p <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_TEXT,0,t,p);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
     }

   void              DrawTrend(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color c,const int width = 1) const
     {
      if(t1 <= 0 || t2 <= 0 || p1 <= 0.0 || p2 <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
      ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
     }

   void              DrawHLine(const string name,const double price,const color c,const int style = STYLE_DOT) const
     {
      if(price <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_HLINE,0,0,price);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_STYLE,style);
     }

   string            PhaseName(const int phase) const
     {
      if(phase == NDS_PHASE_HOOK_1) return "HOOK_1";
      if(phase == NDS_PHASE_HOOK_2) return "HOOK_2";
      if(phase == NDS_PHASE_RALLY_1) return "RALLY_1";
      if(phase == NDS_PHASE_RALLY_2) return "RALLY_2";
      if(phase == NDS_PHASE_FLAG) return "FLAG";
      if(phase == NDS_PHASE_CLOSE) return "CLOSE";
      return "UNKNOWN";
     }
public:
                     NdsVisualDebug(void)
     {
      m_prefix = "NDS";
     }
   void              Configure(const string prefix,const NdsConfig &cfg)
     {
      m_prefix = prefix;
      m_cfg = cfg;
     }
   void              Clear(void) const
     {
      for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
        {
         string n = ObjectName(0,i);
         if(StringFind(n,m_prefix + "_") == 0)
            ObjectDelete(0,n);
        }
     }

   void              Render(const NdsSnapshot &s,const NdsTradeIntent &intent,const NdsRuleReport &report) const
     {
      Clear();
      double off = (double)m_cfg.node_label_offset_points * _Point;

      if(m_cfg.draw_nodes)
        {
         DrawArrow(Key("p1"),s.sequence.last_peak_1.bar_time,s.sequence.last_peak_1.price,m_cfg.color_bear,234);
         DrawArrow(Key("p2"),s.sequence.last_peak_2.bar_time,s.sequence.last_peak_2.price,m_cfg.color_bear,234);
         DrawArrow(Key("p3"),s.sequence.last_peak_3.bar_time,s.sequence.last_peak_3.price,m_cfg.color_bear,234);
         DrawArrow(Key("v1"),s.sequence.last_valley_1.bar_time,s.sequence.last_valley_1.price,m_cfg.color_bull,233);
         DrawArrow(Key("v2"),s.sequence.last_valley_2.bar_time,s.sequence.last_valley_2.price,m_cfg.color_bull,233);
         DrawArrow(Key("v3"),s.sequence.last_valley_3.bar_time,s.sequence.last_valley_3.price,m_cfg.color_bull,233);

         DrawLabel(Key("p1l"),s.sequence.last_peak_1.bar_time,s.sequence.last_peak_1.price + off,"P1",m_cfg.color_bear);
         DrawLabel(Key("p2l"),s.sequence.last_peak_2.bar_time,s.sequence.last_peak_2.price + off,"P2",m_cfg.color_bear);
         DrawLabel(Key("p3l"),s.sequence.last_peak_3.bar_time,s.sequence.last_peak_3.price + off,"P3",m_cfg.color_bear);
         DrawLabel(Key("v1l"),s.sequence.last_valley_1.bar_time,s.sequence.last_valley_1.price - off,"V1",m_cfg.color_bull);
         DrawLabel(Key("v2l"),s.sequence.last_valley_2.bar_time,s.sequence.last_valley_2.price - off,"V2",m_cfg.color_bull);
         DrawLabel(Key("v3l"),s.sequence.last_valley_3.bar_time,s.sequence.last_valley_3.price - off,"V3",m_cfg.color_bull);
        }

      if(m_cfg.draw_sequence)
        {
         DrawTrend(Key("seq_p12"),s.sequence.last_peak_1.bar_time,s.sequence.last_peak_1.price,
                   s.sequence.last_peak_2.bar_time,s.sequence.last_peak_2.price,m_cfg.color_bear,1);
         DrawTrend(Key("seq_p23"),s.sequence.last_peak_2.bar_time,s.sequence.last_peak_2.price,
                   s.sequence.last_peak_3.bar_time,s.sequence.last_peak_3.price,m_cfg.color_bear,1);
         DrawTrend(Key("seq_v12"),s.sequence.last_valley_1.bar_time,s.sequence.last_valley_1.price,
                   s.sequence.last_valley_2.bar_time,s.sequence.last_valley_2.price,m_cfg.color_bull,1);
         DrawTrend(Key("seq_v23"),s.sequence.last_valley_2.bar_time,s.sequence.last_valley_2.price,
                   s.sequence.last_valley_3.bar_time,s.sequence.last_valley_3.price,m_cfg.color_bull,1);
        }

      if(m_cfg.draw_hook && s.hook.is_valid)
        {
         color hc = s.hook.direction == NDS_DIR_BULL ? m_cfg.color_bull : m_cfg.color_bear;
         DrawTrend(Key("h12"),s.hook.n1.bar_time,s.hook.n1.price,s.hook.n2.bar_time,s.hook.n2.price,hc,2);
         DrawTrend(Key("h23"),s.hook.n2.bar_time,s.hook.n2.price,s.hook.n3.bar_time,s.hook.n3.price,hc,2);
         DrawHLine(Key("h86"),s.hook.level_86,m_cfg.color_aux,STYLE_DASH);
         DrawLabel(Key("ht"),s.hook.n2.bar_time,s.hook.n2.price,"Hook " + IntegerToString(s.hook.hook_type),hc);
        }

      if(m_cfg.draw_flag && s.flag.is_valid)
        {
         color fc = s.flag.direction == NDS_DIR_BULL ? m_cfg.color_bull : m_cfg.color_bear;
         DrawTrend(Key("f12"),s.flag.f1.bar_time,s.flag.f1.price,s.flag.f2.bar_time,s.flag.f2.price,fc,1);
         DrawTrend(Key("f23"),s.flag.f2.bar_time,s.flag.f2.price,s.flag.f3.bar_time,s.flag.f3.price,fc,1);
         DrawTrend(Key("f34"),s.flag.f3.bar_time,s.flag.f3.price,s.flag.f4.bar_time,s.flag.f4.price,fc,1);
         DrawLabel(Key("fl"),s.flag.f3.bar_time,s.flag.f3.price,"FLAG",fc);
        }

      if(m_cfg.draw_rally && s.rally.is_valid)
        {
         color rc = s.rally.direction == NDS_DIR_BULL ? m_cfg.color_bull : m_cfg.color_bear;
         DrawTrend(Key("rally"),s.rally.start.bar_time,s.rally.start.price,s.rally.end.bar_time,s.rally.end.price,rc,2);
         DrawLabel(Key("rally_l"),s.rally.end.bar_time,s.rally.end.price,"RALLY",rc);
        }

      if(m_cfg.draw_symmetry && s.symmetry.is_valid)
        {
         DrawHLine(Key("sym_t"),s.symmetry.target_price,m_cfg.color_aux,STYLE_SOLID);
        }

      if(m_cfg.draw_trade_levels && intent.can_trade)
        {
         DrawHLine(Key("tr_entry"),intent.entry,clrDodgerBlue,STYLE_SOLID);
         DrawHLine(Key("tr_sl"),intent.sl,clrOrangeRed,STYLE_DASH);
         DrawHLine(Key("tr_tp1"),intent.tp1,m_cfg.color_aux,STYLE_DOT);
         DrawHLine(Key("tr_tp2"),intent.tp2,m_cfg.color_aux,STYLE_SOLID);
        }

      if(m_cfg.draw_cycle && s.cycle.is_valid)
        {
         datetime t0 = iTime(_Symbol,_Period,0);
         double p0 = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         DrawLabel(Key("phase"),t0,p0 + 25 * _Point,
                   "Phase=" + PhaseName(s.cycle.phase) + " H=" + IntegerToString(s.cycle.hooks_count) +
                   " R=" + IntegerToString(s.cycle.rallies_count),m_cfg.color_aux);
        }

      if(m_cfg.draw_text)
        {
         NdsDiagnostics diag;
         string txt = diag.BuildSnapshotText(s,intent,report);
         Comment(txt);
        }
      else
         Comment("");
     }
  };

#endif
