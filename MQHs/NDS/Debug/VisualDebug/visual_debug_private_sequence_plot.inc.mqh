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
      int start = 0;

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

