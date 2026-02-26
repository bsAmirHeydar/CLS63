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
      ObjectSetString(0,name,OBJPROP_TEXT,"*");
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

   ENUM_TIMEFRAMES   HookLabelTf(const NdsHookState &hook) const
      {
      if(hook.scan_tf != PERIOD_CURRENT)
         return hook.scan_tf;
      if(hook.seed_tf != PERIOD_CURRENT)
         return hook.seed_tf;
      return (ENUM_TIMEFRAMES)_Period;
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

   void              DrawHistoryHookShape(const string key_prefix,const NdsHookState &hook) const
