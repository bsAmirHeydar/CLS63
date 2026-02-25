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
      int hook_m = MathMax(MathMax(hook.hook_seq_max,hook.primary_max_len),hook.secondary_max_len);
      if(hook_m > 4)
         return;

      // Minimal hook view: only semicircle + TF label.
      // Straight segments (1-2,2-3,3-Z), arrows and helper lines are intentionally hidden.
      DrawHookSemicircle(key_prefix,hook,c);
      const bool show_raw_hook_truth_overlay = false; // enable only when auditing hook engine geometry
      if(show_raw_hook_truth_overlay)
         DrawHookTruthOverlay(key_prefix + "_raw",hook,c);
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
