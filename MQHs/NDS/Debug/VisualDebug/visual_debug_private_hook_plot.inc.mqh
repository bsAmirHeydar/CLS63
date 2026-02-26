      {
      if(!hook.is_valid)
         return;
      int hook_m = MathMax(MathMax(hook.hook_seq_max,hook.primary_max_len),hook.secondary_max_len);
      if(hook_m > 4)
         return;
      if(hook.start_anchor.bar_time <= 0)
         return;

      color c = hook.direction == NDS_DIR_BULL ? clrPaleGreen : clrLightSalmon;
      DrawHookSemicircle(key_prefix,hook,c);
      const bool show_raw_hook_truth_overlay = false; // enable only when auditing hook engine geometry
      if(show_raw_hook_truth_overlay)
         DrawHookTruthOverlay(key_prefix + "_raw",hook,c);
      }

   void              DrawHookTruthOverlay(const string key_prefix,const NdsHookState &hook,const color c) const
      {
      if(!hook.is_valid)
         return;

      color pc = c;
      color ac = clrWhite;
      double off = (double)MathMax(8,m_cfg.node_label_offset_points) * _Point;
      double y_up = off * 1.5;
      double y_dn = off * 1.5;

      // Exact hook nodes from engine (the "truth" behind semicircle rendering).
      if(hook.start_anchor.bar_time > 0 && hook.start_anchor.price > 0.0)
        {
         DrawExactPoint(Key(key_prefix + "_A_pt"),hook.start_anchor.bar_time,hook.start_anchor.price,ac);
         double ay = hook.direction == NDS_DIR_BULL ? hook.start_anchor.price - y_dn : hook.start_anchor.price + y_up;
         DrawLabel(Key(key_prefix + "_A_lb"),hook.start_anchor.bar_time,ay,"A",ac,8);
        }

      if(hook.n1.bar_time > 0 && hook.n1.price > 0.0)
        {
         DrawExactPoint(Key(key_prefix + "_1_pt"),hook.n1.bar_time,hook.n1.price,pc);
         double y1 = (hook.direction == NDS_DIR_BULL ? hook.n1.price + y_up : hook.n1.price - y_dn);
         DrawLabel(Key(key_prefix + "_1_lb"),hook.n1.bar_time,y1,"1",pc,8);
        }
      if(hook.n2.bar_time > 0 && hook.n2.price > 0.0)
        {
         DrawExactPoint(Key(key_prefix + "_2_pt"),hook.n2.bar_time,hook.n2.price,pc);
         double y2 = (hook.direction == NDS_DIR_BULL ? hook.n2.price + y_up : hook.n2.price - y_dn);
         DrawLabel(Key(key_prefix + "_2_lb"),hook.n2.bar_time,y2,"2",pc,8);
        }
      if(hook.n3.bar_time > 0 && hook.n3.price > 0.0)
        {
         DrawExactPoint(Key(key_prefix + "_3_pt"),hook.n3.bar_time,hook.n3.price,pc);
         double y3 = (hook.direction == NDS_DIR_BULL ? hook.n3.price + y_up : hook.n3.price - y_dn);
         DrawLabel(Key(key_prefix + "_3_lb"),hook.n3.bar_time,y3,"3",pc,8);
        }
      if(hook.z.bar_time > 0 && hook.z.price > 0.0)
        {
         DrawExactPoint(Key(key_prefix + "_Z_pt"),hook.z.bar_time,hook.z.price,clrYellow);
         double yz = (hook.direction == NDS_DIR_BULL ? hook.z.price - y_dn : hook.z.price + y_up);
         DrawLabel(Key(key_prefix + "_Z_lb"),hook.z.bar_time,yz,"Z",clrYellow,8);
        }

      // Thin raw skeleton to expose actual engine geometry (not the semicircle abstraction).
      if(hook.start_anchor.bar_time > 0 && hook.n1.bar_time > 0)
         DrawTrend(Key(key_prefix + "_A1"),hook.start_anchor.bar_time,hook.start_anchor.price,hook.n1.bar_time,hook.n1.price,ac,1,STYLE_DOT);
      if(hook.n1.bar_time > 0 && hook.n2.bar_time > 0)
         DrawTrend(Key(key_prefix + "_12"),hook.n1.bar_time,hook.n1.price,hook.n2.bar_time,hook.n2.price,pc,1,STYLE_DOT);
      if(hook.n2.bar_time > 0 && hook.n3.bar_time > 0)
         DrawTrend(Key(key_prefix + "_23"),hook.n2.bar_time,hook.n2.price,hook.n3.bar_time,hook.n3.price,pc,1,STYLE_DOT);
      if(hook.n3.bar_time > 0 && hook.z.bar_time > 0)
         DrawTrend(Key(key_prefix + "_3Z"),hook.n3.bar_time,hook.n3.price,hook.z.bar_time,hook.z.price,clrYellow,1,STYLE_DOT);

      // Meta for debugging ownership TF logic on the actual hook geometry.
      if(hook.z.bar_time > 0)
        {
         string meta = TfShort(hook.seed_tf) + "->" + TfShort(hook.scan_tf) +
                       " M=" + IntegerToString(MathMax(MathMax(hook.hook_seq_max,hook.primary_max_len),hook.secondary_max_len)) +
                       " P=" + IntegerToString(hook.ownership_promotions);
         double ym = (hook.direction == NDS_DIR_BULL ? hook.z.price - (y_dn * 2.4) : hook.z.price + (y_up * 2.4));
         DrawLabel(Key(key_prefix + "_meta"),hook.z.bar_time,ym,meta,clrSilver,8);
        }
      }

   int               DrawHookHistory(const NdsSnapshot &s) const
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

      // Clip drawing to visible chart window so off-screen hooks don't appear as long noisy lines.
      datetime vis_left_t = 0;
      datetime vis_right_t = 0;
      long first_visible = ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR,0);
      long visible_bars = ChartGetInteger(0,CHART_VISIBLE_BARS,0);
      if(first_visible >= 0)
         vis_left_t = iTime(_Symbol,_Period,(int)first_visible);
      if(visible_bars > 0)
         vis_right_t = iTime(_Symbol,_Period,0);
      if(vis_left_t > 0 && vis_right_t > 0 && vis_left_t > vis_right_t)
        {
         datetime tmp_t = vis_left_t;
         vis_left_t = vis_right_t;
         vis_right_t = tmp_t;
        }

      double u_min = 0.0;
      double u_max = 1.0;
      if(vis_left_t > 0 && vis_right_t > 0 && t_end > t_start)
        {
         double span = (double)(t_end - t_start);
         double a = ((double)vis_left_t - (double)t_start) / span;
         double b = ((double)vis_right_t - (double)t_start) / span;
         u_min = MathMax(0.0,MathMin(1.0,a));
         u_max = MathMax(0.0,MathMin(1.0,b));
         if(u_min > u_max)
           {
            double tu = u_min;
            u_min = u_max;
            u_max = tu;
           }
        }

      if(u_max - u_min <= 0.0001)
         return;

      const int seg = 24;
      int drawn_seg = 0;
      double u0 = u_min;
      long tx0 = (long)MathRound((double)t_start + ((double)(t_end - t_start)) * u0);
      datetime prev_t = (datetime)tx0;
      double prev_p = base + (double)sgn * amp * MathSin(PI * u0);
      for(int i = 1; i <= seg; i++)
        {
         double u = u_min + (u_max - u_min) * ((double)i / (double)seg);
         long tx = (long)MathRound((double)t_start + ((double)(t_end - t_start)) * u);
         double py = base + (double)sgn * amp * MathSin(PI * u);
         datetime cur_t = (datetime)tx;
         // Time quantization on lower chart TF can collapse many arc samples onto the same timestamp.
         // Drawing those creates vertical/noisy artifacts. Keep only strictly forward-in-time segments.
         if(cur_t <= prev_t)
           {
            prev_p = py; // keep latest y for the same x; wait for the next forward timestamp
            continue;
           }

         DrawTrend(Key(key_prefix + "_semi_" + IntegerToString(i)),prev_t,prev_p,cur_t,py,c,1,STYLE_DOT);
         drawn_seg++;
         prev_t = cur_t;
         prev_p = py;
        }

      if(drawn_seg <= 0)
         return;

      // Single TF label on the arc (not duplicated above/below).
      double u_lab = 0.5;
      if(u_min > 0.0 || u_max < 1.0)
         u_lab = (u_min + u_max) * 0.5;
      long tx_lab = (long)MathRound((double)t_start + ((double)(t_end - t_start)) * u_lab);
      datetime t_lab = (datetime)tx_lab;
      double y_lab = base + (double)sgn * amp * MathSin(PI * u_lab);
      y_lab += (hook.direction == NDS_DIR_BULL ? 1.6 * off : -1.6 * off);
      string tf_txt = EnumToString(HookLabelTf(hook));
      DrawLabel(Key(key_prefix + "_tf"),t_lab,y_lab,tf_txt,clrAqua,10);
      }

   void              DrawNodeDots(const string symbol,const ENUM_TIMEFRAMES tf,const bool draw_points,const bool draw_layers,int &peak_count,int &valley_count) const
