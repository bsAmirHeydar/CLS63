//+------------------------------------------------------------------+
//|                                                        order.mqh |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      "https://www.mql5.com"

input double risk = 100.0;              // Fixed risk amount per trade (account currency)
input int MagicNumber = 0;              // Strategy magic number
input double commissionPerLot = 3.0;    // Estimated commission per lot
input int point_scale = 1;              // Optional symbol point multiplier
input int maxOrder = 1;                 // Max active orders per direction (positions + pendings)
input int slippage = 10;                // Allowed slippage in points

int VolumeDigits(const double step)
  {
   if(step <= 0.0)
      return 2;

   int digits = 0;
   double scaled = step;
   while(digits < 8 && MathAbs(scaled - MathRound(scaled)) > 1e-8)
     {
      scaled *= 10.0;
      digits++;
     }
   return digits;
  }

bool IsDirectionValid(const int dir)
  {
   return (dir == 1 || dir == -1);
  }

bool IsPendingTypeOfDirection(const int order_type,const int dir)
  {
   if(dir == 1)
      return (order_type == ORDER_TYPE_BUY_LIMIT ||
              order_type == ORDER_TYPE_BUY_STOP ||
              order_type == ORDER_TYPE_BUY_STOP_LIMIT);

   if(dir == -1)
      return (order_type == ORDER_TYPE_SELL_LIMIT ||
              order_type == ORDER_TYPE_SELL_STOP ||
              order_type == ORDER_TYPE_SELL_STOP_LIMIT);

   return false;
  }

bool IsSelectedPositionMine(const int dir)
  {
   if(PositionGetString(POSITION_SYMBOL) != _Symbol)
      return false;
   if((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
      return false;

   long type = PositionGetInteger(POSITION_TYPE);
   if(dir == 1 && type != POSITION_TYPE_BUY)
      return false;
   if(dir == -1 && type != POSITION_TYPE_SELL)
      return false;

   return true;
  }

bool IsSelectedOrderMine(const int dir)
  {
   if(OrderGetString(ORDER_SYMBOL) != _Symbol)
      return false;
   if((int)OrderGetInteger(ORDER_MAGIC) != MagicNumber)
      return false;

   int type = (int)OrderGetInteger(ORDER_TYPE);
   return IsPendingTypeOfDirection(type,dir);
  }

ENUM_ORDER_TYPE_FILLING ResolveDealFilling()
  {
   long filling_mask = SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   if((filling_mask & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   if((filling_mask & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
  }

double CalculatePointValue()
  {
   double tick_value = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);

   if(tick_value <= 0.0 || tick_size <= 0.0 || point <= 0.0)
      return 0.0;

   return tick_value * (point / tick_size) * (double)point_scale;
  }

double LossPerLotAtSL(const int dir,const double open_price,const double sl_price)
  {
   if(!(dir == 1 || dir == -1))
      return 0.0;
   if(open_price <= 0.0 || sl_price <= 0.0)
      return 0.0;

   ENUM_ORDER_TYPE order_type = (dir == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double profit = 0.0;
   if(!OrderCalcProfit(order_type,_Symbol,1.0,open_price,sl_price,profit))
      return 0.0;

   return MathAbs(profit);
  }

double NormalizeVolumeStep(const double lots,const double step,const int digits)
  {
   if(step <= 0.0)
      return NormalizeDouble(lots,digits);
   double scaled = lots / step;
   return NormalizeDouble(MathRound(scaled) * step,digits);
  }

double volume(const int dir,const double open_price,const double sl_price)
  {
   if(risk <= 0.0)
      return 0.0;

   double risk_per_lot = LossPerLotAtSL(dir,open_price,sl_price);
   if(risk_per_lot <= 0.0)
      return 0.0;

   double lots = risk / risk_per_lot;

   double min_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step_lot <= 0.0)
      step_lot = 0.01;

   int vol_digits = VolumeDigits(step_lot);

   double nearest = NormalizeVolumeStep(lots,step_lot,vol_digits);
   double floor_lot = NormalizeDouble(MathFloor(lots / step_lot) * step_lot,vol_digits);
   double ceil_lot = NormalizeDouble(MathCeil(lots / step_lot) * step_lot,vol_digits);

   if(floor_lot < min_lot)
      floor_lot = 0.0;
   if(ceil_lot > max_lot)
      ceil_lot = 0.0;

   // Prefer no-overrisk, then nearest valid step as fallback.
   double best = floor_lot;
   if(best <= 0.0)
      best = nearest;
   if(best <= 0.0 && ceil_lot > 0.0)
      best = ceil_lot;

   lots = best;
   lots = NormalizeDouble(lots,vol_digits);

   if(lots < min_lot)
      return 0.0;

   if(lots > max_lot)
     {
      lots = MathFloor(max_lot / step_lot) * step_lot;
      lots = NormalizeDouble(lots,vol_digits);
     }

   return lots;
  }

int countOrders(const int dir)
  {
   if(!IsDirectionValid(dir))
      return 0;

   int cnt = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(IsSelectedPositionMine(dir))
         cnt++;
     }

   for(int j = OrdersTotal() - 1; j >= 0; j--)
     {
      ulong ticket = OrderGetTicket(j);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(IsSelectedOrderMine(dir))
         cnt++;
     }

   return cnt;
  }

int countPositions(const int dir)
  {
   if(!IsDirectionValid(dir))
      return 0;

   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(IsSelectedPositionMine(dir))
         cnt++;
     }
   return cnt;
  }

int countPendings(const int dir)
  {
   if(!IsDirectionValid(dir))
      return 0;

   int cnt = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(IsSelectedOrderMine(dir))
         cnt++;
     }
   return cnt;
  }

bool SendRequest(const string tag,MqlTradeRequest &req)
  {
   MqlTradeResult res;
   ZeroMemory(res);

   bool ok = OrderSend(req,res);
   bool accepted = (res.retcode == TRADE_RETCODE_DONE ||
                    res.retcode == TRADE_RETCODE_PLACED ||
                    res.retcode == TRADE_RETCODE_DONE_PARTIAL);

   if(!ok || !accepted)
     {
      Print(tag,
            " failed. ok=",ok,
            " ret=",res.retcode,
            " err=",GetLastError(),
            " vol=",DoubleToString(req.volume,2),
            " price=",DoubleToString(req.price,_Digits),
            " sl=",DoubleToString(req.sl,_Digits),
            " tp=",DoubleToString(req.tp,_Digits));
      return false;
     }

   return true;
  }

bool BuildEntryRequest(const int dir,const string orderType,const double entry,const double sl,const double tp,MqlTradeRequest &req)
  {
   ZeroMemory(req);

   double market_price = (dir == 1) ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ref_price = market_price;

   if(orderType == "limit" || orderType == "stop")
      ref_price = entry;

   if(dir == 1)
     {
      if(sl >= ref_price || tp <= ref_price)
        {
         Print("Order blocked: invalid BUY levels. entry=",DoubleToString(ref_price,_Digits),
               " sl=",DoubleToString(sl,_Digits),
               " tp=",DoubleToString(tp,_Digits));
         return false;
        }
     }
   else
     {
      if(sl <= ref_price || tp >= ref_price)
        {
         Print("Order blocked: invalid SELL levels. entry=",DoubleToString(ref_price,_Digits),
               " sl=",DoubleToString(sl,_Digits),
               " tp=",DoubleToString(tp,_Digits));
         return false;
        }
     }

   if(orderType == "limit")
     {
      if((dir == 1 && entry > market_price) || (dir == -1 && entry < market_price))
        {
         Print("Order blocked: invalid LIMIT entry side. entry=",DoubleToString(entry,_Digits),
               " market=",DoubleToString(market_price,_Digits));
         return false;
        }
     }

   if(orderType == "stop")
      {
      if((dir == 1 && entry < market_price) || (dir == -1 && entry > market_price))
        {
         Print("Order blocked: invalid STOP entry side. entry=",DoubleToString(entry,_Digits),
               " market=",DoubleToString(market_price,_Digits));
         return false;
        }
      }

   double lots = volume(dir,ref_price,sl);
   if(lots <= 0.0)
      {
      Print("Order blocked: computed lot is zero. risk=",risk,
            " open=",DoubleToString(ref_price,_Digits),
            " sl=",DoubleToString(sl,_Digits));
      return false;
      }

   req.symbol = _Symbol;
   req.magic = MagicNumber;
   req.volume = lots;
   req.deviation = slippage;
   req.sl = NormalizeDouble(sl,_Digits);
   req.tp = NormalizeDouble(tp,_Digits);
   req.type_time = ORDER_TIME_GTC;

   if(orderType == "market")
     {
      req.action = TRADE_ACTION_DEAL;
      req.type_filling = ResolveDealFilling();
      req.type = (dir == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      req.price = NormalizeDouble(market_price,_Digits);
      return true;
     }

   if(orderType == "limit")
     {
      req.action = TRADE_ACTION_PENDING;
      req.type_filling = ORDER_FILLING_RETURN;
      req.type = (dir == 1) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
      req.price = NormalizeDouble(entry,_Digits);
      return true;
     }

   if(orderType == "stop")
     {
      req.action = TRADE_ACTION_PENDING;
      req.type_filling = ORDER_FILLING_RETURN;
      req.type = (dir == 1) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP;
      req.price = NormalizeDouble(entry,_Digits);
      return true;
     }

   Print("Invalid orderType: ",orderType);
   return false;
  }

bool buy(const string orderType,const double entry,const double sl,const double tp)
  {
   int active_positions = countPositions(1);
   if(active_positions >= maxOrder)
     {
      Print("BUY blocked: maxOrder reached by positions. active=",active_positions," maxOrder=",maxOrder);
      return false;
     }

   if(countPendings(1) > 0)
      deleteAll(1);

   int active = countOrders(1);
   if(active >= maxOrder)
     {
      Print("BUY blocked: maxOrder reached after pending refresh. active=",active," maxOrder=",maxOrder);
      return false;
     }

   MqlTradeRequest req;
   if(!BuildEntryRequest(1,orderType,entry,sl,tp,req))
      return false;

   return SendRequest("BUY " + orderType,req);
  }

bool sell(const string orderType,const double entry,const double sl,const double tp)
  {
   int active_positions = countPositions(-1);
   if(active_positions >= maxOrder)
     {
      Print("SELL blocked: maxOrder reached by positions. active=",active_positions," maxOrder=",maxOrder);
      return false;
     }

   if(countPendings(-1) > 0)
      deleteAll(-1);

   int active = countOrders(-1);
   if(active >= maxOrder)
     {
      Print("SELL blocked: maxOrder reached after pending refresh. active=",active," maxOrder=",maxOrder);
      return false;
     }

   MqlTradeRequest req;
   if(!BuildEntryRequest(-1,orderType,entry,sl,tp,req))
      return false;

   return SendRequest("SELL " + orderType,req);
  }

bool SendCloseWithFallback(MqlTradeRequest &req,MqlTradeResult &res)
  {
   ENUM_ORDER_TYPE_FILLING fillings[3] = { ORDER_FILLING_IOC, ORDER_FILLING_FOK, ORDER_FILLING_RETURN };

   for(int i = 0; i < 3; i++)
     {
      req.type_filling = fillings[i];
      ZeroMemory(res);
      if(OrderSend(req,res))
        {
         if(res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_DONE_PARTIAL)
            return true;
        }
     }
   return false;
  }

void closeAll(const int dir)
  {
   if(!IsDirectionValid(dir))
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!IsSelectedPositionMine(dir))
         continue;

      long ptype = PositionGetInteger(POSITION_TYPE);
      string symbol = PositionGetString(POSITION_SYMBOL);

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req);
      ZeroMemory(res);

      req.action = TRADE_ACTION_DEAL;
      req.symbol = symbol;
      req.magic = MagicNumber;
      req.volume = PositionGetDouble(POSITION_VOLUME);
      req.position = ticket;
      req.deviation = slippage;

      if(ptype == POSITION_TYPE_BUY)
        {
         req.type = ORDER_TYPE_SELL;
         req.price = SymbolInfoDouble(symbol,SYMBOL_BID);
        }
      else
        {
         req.type = ORDER_TYPE_BUY;
         req.price = SymbolInfoDouble(symbol,SYMBOL_ASK);
        }

      if(!SendCloseWithFallback(req,res))
         Print("Close failed. ret=",res.retcode," ticket=",ticket," symbol=",symbol);
     }
  }

void deleteAll(const int dir)
  {
   if(!IsDirectionValid(dir))
      return;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket))
         continue;
      if(!IsSelectedOrderMine(dir))
         continue;

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req);
      ZeroMemory(res);

      req.action = TRADE_ACTION_REMOVE;
      req.order = ticket;
      req.symbol = _Symbol;
      req.magic = MagicNumber;

      if(!OrderSend(req,res))
         Print("Delete failed. ticket=",ticket," err=",GetLastError()," ret=",res.retcode);
     }
  }

//+------------------------------------------------------------------+
