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

      const bool hook_cycle_only_mode = true;
      const bool nodes_only_mode = false;
      const bool draw_hook_view = (m_cfg.draw_hook || hook_cycle_only_mode);
      const bool draw_cycle_view = (m_cfg.draw_cycle || hook_cycle_only_mode);
      double off = (double)m_cfg.node_label_offset_points * _Point;
      int drawn_hooks = 0;

      int ltf_peak_count = 0;
      int ltf_valley_count = 0;
      // For visual node debugging, always use the chart timeframe so point positions are
      // interpreted against the same candle grid the user is looking at.
      ENUM_TIMEFRAMES node_tf = (ENUM_TIMEFRAMES)_Period;
      if((m_cfg.draw_node_points || m_cfg.draw_nodes) && (!hook_cycle_only_mode || m_cfg.draw_node_points))
         DrawNodeDots(s.symbol,node_tf,m_cfg.draw_node_points,(!hook_cycle_only_mode && m_cfg.draw_nodes),ltf_peak_count,ltf_valley_count);

      if(nodes_only_mode)
        {
         if(m_cfg.draw_text)
           {
            string txt = "NDS Node Debug";
            txt += "\nTF: " + EnumToString(node_tf);
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

      if(draw_hook_view && s.hook.is_valid)
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
         if(s.cycle.hook1.is_valid)
           {
            DrawHookShape("htf_hook1",s.cycle.hook1,clrDeepSkyBlue);
            drawn_hooks++;
           }
         if(s.cycle.has_hook2)
            {
            DrawHookShape("htf_hook2",s.cycle.hook2,clrOrange);
            drawn_hooks++;
            }
         // HTF rally drawing intentionally disabled: user requested hook-only visualization.

        }

      // Always draw historical hooks too (all as semicircles).
      if(draw_hook_view)
         drawn_hooks += DrawHookHistory(s);

      if(m_cfg.draw_text)
        {
         if(hook_cycle_only_mode)
           {
            string txt = "NDS Hook/Cycle View | HooksDrawn=" + IntegerToString(drawn_hooks);
            if(s.hook.is_valid)
               txt += " | LTF=" + TfShort(s.hook.scan_tf) + " M=" + IntegerToString(MathMax(s.hook.hook_seq_max,s.hook.primary_max_len)) + " P=" + IntegerToString(s.hook.ownership_promotions);
            if(s.cycle.has_hook2)
               txt += " | H2TF=" + TfShort(s.cycle.hook2.scan_tf) + " M2=" + IntegerToString(MathMax(s.cycle.hook2.hook_seq_max,s.cycle.hook2.primary_max_len)) + " P2=" + IntegerToString(s.cycle.hook2.ownership_promotions);
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
