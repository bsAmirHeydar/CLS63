#ifndef __NDS_VISUAL_DEBUG_MQH__
#define __NDS_VISUAL_DEBUG_MQH__

#include "..\\Core\\nds_config.mqh"
#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_result.mqh"
#include "..\\Infrastructure\\diagnostics.mqh"
#include "..\\Reading\\node_detector.mqh"
#include "..\\Reading\\hook_engine.mqh"

struct NdsDebugNodeLayer
  {
   NdsNode           nodes[]; // stored as newest -> oldest
  };

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

   void              DrawExactPoint(const string name,const datetime t,const double p,const color c) const
      {
      if(t <= 0 || p <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_TEXT,0,t,p);
      ObjectSetString(0,name,OBJPROP_TEXT,"o");
      ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
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

   color             SequenceLayerColor(const int layer_no,const bool valley_mode) const
      {
      int k = (layer_no - 1) % 10;
      if(valley_mode)
        {
         if(k == 0) return clrDodgerBlue;
         if(k == 1) return clrGold;
         if(k == 2) return clrOrchid;
         if(k == 3) return clrMediumSeaGreen;
         if(k == 4) return clrDarkOrange;
         if(k == 5) return clrIndianRed;
         if(k == 6) return clrRoyalBlue;
         if(k == 7) return clrKhaki;
         if(k == 8) return clrViolet;
         return clrSpringGreen;
        }

      if(k == 0) return clrAqua;
      if(k == 1) return clrYellow;
      if(k == 2) return clrMagenta;
      if(k == 3) return clrLime;
      if(k == 4) return clrOrange;
      if(k == 5) return clrTomato;
      if(k == 6) return clrDeepSkyBlue;
      if(k == 7) return clrPlum;
      if(k == 8) return clrLightSalmon;
      return clrTurquoise;
      }

   void              CopyLayer(const NdsDebugNodeLayer &src,NdsDebugNodeLayer &dst) const
      {
      CopyNodes(src.nodes,dst.nodes);
      }

   void              BuildNestedLayersFromEnd(const NdsNode &src_old_to_new[],const bool valley_mode,NdsDebugNodeLayer &layers[]) const
      {
      ArrayResize(layers,0);
      int n = ArraySize(src_old_to_new);
      if(n <= 0)
         return;

      NdsNode rev_new_to_old[];
      ReverseNodes(src_old_to_new,rev_new_to_old);

      ArrayResize(layers,1);
      ArrayResize(layers[0].nodes,0);
      PushNode(rev_new_to_old[0],layers[0].nodes);

      for(int i = 1; i < n; i++)
        {
         NdsNode nd = rev_new_to_old[i];
         NdsNode prev = rev_new_to_old[i - 1];
         int last = ArraySize(layers) - 1;

         bool continue_same = valley_mode ? (nd.price > prev.price) : (nd.price < prev.price);
         if(continue_same)
           {
            PushNode(nd,layers[last].nodes);
           }
         else
           {
            int next_index = last + 1;
            ArrayResize(layers,next_index + 1);
            CopyLayer(layers[last],layers[next_index]);
            ClearTailForNested(valley_mode,nd.price,layers[next_index].nodes);
            PushNode(nd,layers[next_index].nodes);
           }
        }
      }

   void              DrawLayerLabels(const string family,const NdsDebugNodeLayer &layer,const bool valley_mode,const int layer_no,const color c) const
      {
      int n = ArraySize(layer.nodes);
      if(n <= 0)
         return;

      NdsNode ord_old_to_new[];
      ReverseNodes(layer.nodes,ord_old_to_new); // numbering from start to end

      double layer_step = (double)MathMax(12,m_cfg.node_label_offset_points * 2) * _Point;
      int start = 0; // draw all nodes in each sequence layer

      for(int i = start; i < n; i++)
        {
         NdsNode nd = ord_old_to_new[i];
         int node_no = i + 1;
         double y = valley_mode ? nd.price - layer_step * layer_no : nd.price + layer_step * layer_no;
         string text = IntegerToString(layer_no) + "." + IntegerToString(node_no);
         string key = "seq_" + family + "_" + IntegerToString(layer_no) + "_" + IntegerToString(i);
         DrawLabel(Key(key),nd.bar_time,y,text,c,10);
        }
      }

   void              DrawLabel(const string name,const datetime t,const double p,const string text,const color c,const int font_size = 8) const
     {
      if(t <= 0 || p <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_TEXT,0,t,p);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
     }

   void              DrawTrend(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color c,const int width = 1,const int style = STYLE_SOLID) const
      {
      if(t1 <= 0 || t2 <= 0 || p1 <= 0.0 || p2 <= 0.0)
         return;
      ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
      ObjectSetInteger(0,name,OBJPROP_COLOR,c);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
      ObjectSetInteger(0,name,OBJPROP_STYLE,style);
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

   string            TfShort(const ENUM_TIMEFRAMES tf) const
      {
      string s = EnumToString(tf);
      StringReplace(s,"PERIOD_","");
      return s;
      }

   bool              IsSameHook(const NdsHookState &a,const NdsHookState &b) const
      {
      return (a.direction == b.direction &&
              a.scan_tf == b.scan_tf &&
              a.n1.bar_time == b.n1.bar_time &&
              a.n2.bar_time == b.n2.bar_time &&
              a.n3.bar_time == b.n3.bar_time &&
              a.z.bar_time == b.z.bar_time);
      }

   bool              IsCurrentHook(const NdsSnapshot &s,const NdsHookState &h) const
      {
      if(s.hook.is_valid && IsSameHook(s.hook,h))
         return true;
      if(s.cycle.hook1.is_valid && IsSameHook(s.cycle.hook1,h))
         return true;
      if(s.cycle.hook2.is_valid && IsSameHook(s.cycle.hook2,h))
         return true;
      return false;
      }

   ENUM_TIMEFRAMES   ResolveActiveHookTf(const NdsSnapshot &s) const
      {
      if(s.hook.is_valid && s.hook.scan_tf != PERIOD_CURRENT)
         return s.hook.scan_tf;

      NdsHookEngine hook_engine;
      hook_engine.Configure(s.symbol,m_cfg);
      return hook_engine.ResolveScanTf(s.tf_ltf);
      }

   void              DrawHistoryHookShape(const string key_prefix,const NdsHookState &hook) const
      {
      if(!hook.is_valid)
         return;
      if(hook.start_anchor.bar_time <= 0)
         return;

      color c = hook.direction == NDS_DIR_BULL ? clrPaleGreen : clrLightSalmon;
      DrawHookSemicircle(key_prefix,hook,c);
      }

   int               DrawHookHistory(const NdsSnapshot &s,const ENUM_TIMEFRAMES active_tf) const
      {
      if(s.symbol == "")
         return 0;

      NdsHookEngine hook_engine;
      hook_engine.Configure(s.symbol,m_cfg);

      NdsHookState history[];
      int total = hook_engine.GetHistory(history);
      if(total <= 0)
         return 0;

      int drawn_total = 0;
      for(int i = 0; i < total; i++)
        {
         NdsHookState h = history[i];
         if(!h.is_valid)
            continue;
         if(active_tf != PERIOD_CURRENT && h.scan_tf != active_tf)
            continue;
         if(IsCurrentHook(s,h))
            continue;

         string key = "hist_" + TfShort(h.scan_tf) + "_" + IntegerToString(i);
         DrawHistoryHookShape(key,h);
         drawn_total++;
        }

      return drawn_total;
      }

   void              DrawHookSemicircle(const string key_prefix,const NdsHookState &hook,const color c) const
      {
      double off = (double)m_cfg.node_label_offset_points * _Point;
      double eps = MathMax(_Point * 0.1,1e-12);
      const double PI = 3.14159265358979323846;

      datetime ta = hook.start_anchor.bar_time > 0 ? hook.start_anchor.bar_time : hook.n1.bar_time;
      if(ta <= 0)
         return;

      int sh_start = iBarShift(_Symbol,_Period,ta,false);
      if(sh_start < 0)
         return;

      double base = hook.start_anchor.price > 0.0 ? hook.start_anchor.price : hook.n1.price;
      if(base <= 0.0)
         return;

      datetime t_limit = 0;
      if(hook.is_open)
         t_limit = iTime(_Symbol,_Period,0);
      else
        {
         t_limit = hook.z.bar_time;
         if(t_limit <= 0)
            t_limit = hook.n3.bar_time;
        }
      if(t_limit <= 0)
         t_limit = iTime(_Symbol,_Period,0);

      int sh_end = iBarShift(_Symbol,_Period,t_limit,false);
      if(sh_end < 0)
         sh_end = 0;
      if(sh_end > sh_start)
        {
         int tmp = sh_start;
         sh_start = sh_end;
         sh_end = tmp;
        }

      int bars_count = sh_start - sh_end + 1;
      if(bars_count <= 0)
         return;

      int sgn = (hook.direction == NDS_DIR_BEAR) ? -1 : 1;
      datetime t_start = ta;
      datetime t_end = ta;
      double amp = 0.0;

      if(sgn > 0)
        {
         // Bull cycle top = highest high reached after hook start.
         int hi_shift = iHighest(_Symbol,_Period,MODE_HIGH,bars_count,sh_end);
         if(hi_shift >= 0)
           {
            double cycle_high = iHigh(_Symbol,_Period,hi_shift);
            t_end = iTime(_Symbol,_Period,hi_shift);
            amp = cycle_high - base;
           }
        }
      else
        {
         // Bear cycle floor = lowest low reached after hook start.
         int lo_shift = iLowest(_Symbol,_Period,MODE_LOW,bars_count,sh_end);
         if(lo_shift >= 0)
           {
            double cycle_low = iLow(_Symbol,_Period,lo_shift);
            t_end = iTime(_Symbol,_Period,lo_shift);
            amp = base - cycle_low;
           }
        }

      if(t_end <= t_start)
        {
         datetime fallback_t = hook.z.bar_time > ta ? hook.z.bar_time : hook.n3.bar_time;
         if(fallback_t <= ta)
            fallback_t = iTime(_Symbol,_Period,0);
         if(fallback_t <= ta)
            return;
         t_end = fallback_t;
      }

      if(amp < 4.0 * off)
         amp = 4.0 * off;
      if(amp <= eps)
         return;

      const int seg = 24;
      datetime prev_t = t_start;
      double prev_p = base;
      for(int i = 1; i <= seg; i++)
        {
         double u = (double)i / (double)seg;
         long tx = (long)MathRound((double)t_start + ((double)(t_end - t_start)) * u);
         double py = base + (double)sgn * amp * MathSin(PI * u);
         datetime cur_t = (datetime)tx;
         DrawTrend(Key(key_prefix + "_semi_" + IntegerToString(i)),prev_t,prev_p,cur_t,py,c,1,STYLE_DOT);
         prev_t = cur_t;
         prev_p = py;
        }

      datetime mid_t = (datetime)((long)t_start + (long)((t_end - t_start) / 2));
      double top_y = base + amp + 2.0 * off;
      double bot_y = base - amp - 2.0 * off;
      string tf_txt = EnumToString(hook.scan_tf);
      DrawLabel(Key(key_prefix + "_tf_top"),mid_t,top_y,tf_txt,clrAqua,10);
      DrawLabel(Key(key_prefix + "_tf_bot"),mid_t,bot_y,tf_txt,clrAqua,10);
      }

   void              DrawNodeDots(const string symbol,const ENUM_TIMEFRAMES tf,int &peak_count,int &valley_count) const
      {
      peak_count = 0;
      valley_count = 0;
      if(symbol == "")
         return;

      NdsNodeDetector detector;
      detector.Configure(symbol,m_cfg);

      NdsNode peaks[];
      NdsNode valleys[];
      detector.FindRecentNodes(tf,NDS_NODE_PEAK,0,peaks);
      detector.FindRecentNodes(tf,NDS_NODE_VALLEY,0,valleys);

      peak_count = ArraySize(peaks);
      valley_count = ArraySize(valleys);

      for(int i = 0; i < peak_count; i++)
        {
         DrawExactPoint(Key("node_p_" + IntegerToString(i)),peaks[i].bar_time,peaks[i].price,m_cfg.color_bear);
        }

      for(int j = 0; j < valley_count; j++)
        {
         DrawExactPoint(Key("node_v_" + IntegerToString(j)),valleys[j].bar_time,valleys[j].price,m_cfg.color_bull);
        }

      NdsDebugNodeLayer peak_layers[];
      NdsDebugNodeLayer valley_layers[];
      BuildNestedLayersFromEnd(peaks,false,peak_layers);
      BuildNestedLayersFromEnd(valleys,true,valley_layers);

      for(int p = 0; p < ArraySize(peak_layers); p++)
         DrawLayerLabels("P",peak_layers[p],false,p + 1,SequenceLayerColor(p + 1,false));
      for(int v = 0; v < ArraySize(valley_layers); v++)
         DrawLayerLabels("V",valley_layers[v],true,v + 1,SequenceLayerColor(v + 1,true));
      }

   void              DrawHookShape(const string key_prefix,const NdsHookState &hook,const color c) const
      {
      if(!hook.is_valid)
         return;

      // Minimal hook view: only semicircle + TF label.
      // Straight segments (1-2,2-3,3-Z), arrows and helper lines are intentionally hidden.
      DrawHookSemicircle(key_prefix,hook,c);
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

      long chart_sync = SeriesInfoInteger(_Symbol,_Period,SERIES_SYNCHRONIZED);
      if(chart_sync == 0)
        {
         if(m_cfg.draw_text)
            Comment("NDS Hook/Cycle View | waiting for series sync...");
         else
            Comment("");
         return;
        }

      const bool hook_cycle_only_mode = true;
      const bool nodes_only_mode = false;
      const bool draw_hook_view = (m_cfg.draw_hook || hook_cycle_only_mode);
      const bool draw_cycle_view = (m_cfg.draw_cycle || hook_cycle_only_mode);
      ENUM_TIMEFRAMES active_hook_tf = ResolveActiveHookTf(s);
      double off = (double)m_cfg.node_label_offset_points * _Point;
      int drawn_hooks = 0;

      int ltf_peak_count = 0;
      int ltf_valley_count = 0;
      if(m_cfg.draw_nodes && !hook_cycle_only_mode)
         DrawNodeDots(s.symbol,s.tf_ltf,ltf_peak_count,ltf_valley_count);

      if(nodes_only_mode)
        {
         if(m_cfg.draw_text)
           {
            string txt = "NDS Node Debug";
            txt += "\nTF: " + EnumToString(s.tf_ltf);
            txt += "\nPeaks: " + IntegerToString(ltf_peak_count);
            txt += "\nValleys: " + IntegerToString(ltf_valley_count);
            txt += "\nSeq labels: k.j (only sequence layers)";
            txt += "\nLayer color: each k has unique color";
            Comment(txt);
           }
         else
            Comment("");
         return;
        }

      if(!nodes_only_mode && m_cfg.draw_nodes && !hook_cycle_only_mode)
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

      if(m_cfg.draw_sequence && !hook_cycle_only_mode)
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

      if(draw_hook_view && s.hook.is_valid && (active_hook_tf == PERIOD_CURRENT || s.hook.scan_tf == active_hook_tf))
        {
         color hc = s.hook.direction == NDS_DIR_BULL ? m_cfg.color_bull : m_cfg.color_bear;
         DrawHookShape("ltf_hook",s.hook,hc);
         drawn_hooks++;
        }

      if(m_cfg.draw_flag && s.flag.is_valid && !hook_cycle_only_mode)
        {
         color fc = s.flag.direction == NDS_DIR_BULL ? m_cfg.color_bull : m_cfg.color_bear;
         DrawTrend(Key("f12"),s.flag.f1.bar_time,s.flag.f1.price,s.flag.f2.bar_time,s.flag.f2.price,fc,1);
         DrawTrend(Key("f23"),s.flag.f2.bar_time,s.flag.f2.price,s.flag.f3.bar_time,s.flag.f3.price,fc,1);
         DrawTrend(Key("f34"),s.flag.f3.bar_time,s.flag.f3.price,s.flag.f4.bar_time,s.flag.f4.price,fc,1);
         DrawLabel(Key("fl"),s.flag.f3.bar_time,s.flag.f3.price,"FLAG",fc);
        }

      // Rally drawing intentionally disabled: user requested hook-only visualization.

      if(m_cfg.draw_symmetry && s.symmetry.is_valid && !hook_cycle_only_mode)
        {
         DrawHLine(Key("sym_t"),s.symmetry.target_price,m_cfg.color_aux,STYLE_SOLID);
        }

      if(m_cfg.draw_trade_levels && intent.can_trade && !hook_cycle_only_mode)
        {
         DrawHLine(Key("tr_entry"),intent.entry,clrDodgerBlue,STYLE_SOLID);
         DrawHLine(Key("tr_sl"),intent.sl,clrOrangeRed,STYLE_DASH);
         DrawHLine(Key("tr_tp1"),intent.tp1,m_cfg.color_aux,STYLE_DOT);
         DrawHLine(Key("tr_tp2"),intent.tp2,m_cfg.color_aux,STYLE_SOLID);
        }

      if(draw_cycle_view && s.cycle.is_valid)
        {
         if(s.cycle.hook1.is_valid && (active_hook_tf == PERIOD_CURRENT || s.cycle.hook1.scan_tf == active_hook_tf))
           {
            DrawHookShape("htf_hook1",s.cycle.hook1,clrDeepSkyBlue);
            drawn_hooks++;
           }
         if(s.cycle.has_hook2 && (active_hook_tf == PERIOD_CURRENT || s.cycle.hook2.scan_tf == active_hook_tf))
            {
            DrawHookShape("htf_hook2",s.cycle.hook2,clrOrange);
            drawn_hooks++;
            }
         // HTF rally drawing intentionally disabled: user requested hook-only visualization.

        }

      // Always draw historical hooks too (all as semicircles).
      if(draw_hook_view)
         drawn_hooks += DrawHookHistory(s,active_hook_tf);

      if(m_cfg.draw_text)
        {
         if(hook_cycle_only_mode)
           {
            string txt = "NDS Hook/Cycle View | HooksDrawn=" + IntegerToString(drawn_hooks);
            txt += " | ActiveTF=" + TfShort(active_hook_tf);
            if(s.hook.is_valid)
               txt += " | LTF=" + TfShort(s.hook.scan_tf) + " M=" + IntegerToString(s.hook.primary_max_len);
            if(s.cycle.has_hook2)
               txt += " | H2TF=" + TfShort(s.cycle.hook2.scan_tf) + " M2=" + IntegerToString(s.cycle.hook2.primary_max_len);
            Comment(txt);
           }
         else
           {
            NdsDiagnostics diag;
            string txt = diag.BuildSnapshotText(s,intent,report);
            Comment(txt);
           }
        }
      else
         Comment("");
     }
  };

#endif
