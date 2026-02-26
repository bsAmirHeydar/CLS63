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
