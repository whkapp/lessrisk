//+------------------------------------------------------------------+
//| Less Risk No Glory - MT5 semi-auto signal receiver               |
//| Reads MQL5/Files/LRNG_signal.ini and shows chart execution panel |
//+------------------------------------------------------------------+
#property strict
#property version   "1.32"
#property description "LRNG semi-auto receiver with custom execution panel."

#include <Trade/Trade.mqh>

input bool   RequireConfirm     = true;
input bool   ForceDefaultLot    = true;
input double DefaultLot         = 0.5;
input string SignalFile         = "LRNG_signal.ini";
input long   MagicNumber        = 777005;
input int    OrderExpiryMinutes = 120;

CTrade trade;
string last_id = "";

string panelPrefix = "LRNG_PANEL_";
bool   panel_visible = false;
bool   status_visible = false;
bool   pending_use_pending = false;
string pending_id = "";
string pending_symbol = "";
string pending_side = "";
string pending_kind = "";
string pending_entry = "";
string pending_tier = "";
string pending_type = "";
double pending_lot = 0.0;
double pending_sl = 0.0;
double pending_tp1 = 0.0;
double pending_tp2 = 0.0;
double pending_tp3 = 0.0;
double pending_entry_price = 0.0;
double pending_reference_price = 0.0;
double pending_min_distance = 0.0;
int    pending_digits = 2;

string Trim(string s)
{
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
}

void ClearSignalFile()
{
   int handle = FileOpen(SignalFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(handle != INVALID_HANDLE)
      FileClose(handle);
}

string ValueOf(string key)
{
   int handle = FileOpen(SignalFile, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return "";

   string prefix = key + "=";
   string out = "";
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      line = Trim(line);
      if(StringFind(line, prefix) == 0)
      {
         out = StringSubstr(line, StringLen(prefix));
         break;
      }
   }
   FileClose(handle);
   return Trim(out);
}

double NumVal(string key, double fallback = 0.0)
{
   string v = ValueOf(key);
   if(v == "" || v == "-" || v == "null")
      return fallback;
   return StringToDouble(v);
}

string RetcodeHint(uint retcode)
{
   switch(retcode)
   {
      case 10016: return "Stops zijn ongeldig voor deze broker/situatie. Check SL/TP afstand.";
      case 10017: return "Trading staat uit voor dit symbool of deze account.";
      case 10018: return "Markt is gesloten. Test opnieuw tijdens open markturen.";
      case 10019: return "Onvoldoende marge om deze order te openen.";
      case 10020: return "Prijs veranderde te snel. Probeer het opnieuw.";
      case 10021: return "Geen geldige marktprijs ontvangen van de broker.";
      case 10024: return "Te veel requests tegelijk. Wacht even en probeer opnieuw.";
      case 10027: return "AutoTrading staat uit in MT5. Zet AutoTrading aan en probeer opnieuw.";
   }
   return "Order geweigerd door broker of terminal. Check Journal/Experts voor details.";
}

void ShowTradeFailure(string id, string side, string symbol, double lot)
{
   uint retcode = trade.ResultRetcode();
   string text = "Signaal: " + id + "\n" +
                 "Setup: " + side + " " + symbol + "\n" +
                 "Lot: " + DoubleToString(lot, 2) + "\n\n" +
                 "MT5 melding: " + trade.ResultRetcodeDescription() + "\n" +
                 "Code: " + IntegerToString((int)retcode) + "\n\n" +
                 RetcodeHint(retcode);

   ShowStatusPanel("LRNG order niet geplaatst", text, true);
   Print("LRNG trade failed: retcode=", retcode, " ", trade.ResultRetcodeDescription(), " id=", id);
}

void ShowConfigIssue(string id, string side, string symbol, string reason)
{
   string text = "Signaal: " + id + "\n" +
                 "Setup: " + side + " " + symbol + "\n\n" +
                 reason;
   ShowStatusPanel("LRNG signaal niet uitgevoerd", text, true);
   Print("LRNG config issue: ", reason, " id=", id);
}

double NormalizePrice(string symbol, double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

double MinStopDistance(string symbol)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;

   long stops_level = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freeze_level = SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   long level = MathMax(stops_level, freeze_level);
   return point * (double)level;
}

bool HasDirectionalLevels(string side, double reference, double sl, double tp)
{
   if(sl <= 0.0 || tp <= 0.0)
      return false;

   if(side == "BUY")
      return (sl < reference && tp > reference);

   return (sl > reference && tp < reference);
}

bool HasStopDistance(string side, double reference, double sl, double tp, double min_distance)
{
   if(min_distance <= 0.0)
      return true;

   if(side == "BUY")
      return ((reference - sl) >= min_distance && (tp - reference) >= min_distance);

   return ((sl - reference) >= min_distance && (reference - tp) >= min_distance);
}

string PendingKind(string side, double entry_price, double ask, double bid, double tolerance)
{
   if(entry_price <= 0.0)
      return "";

   if(side == "BUY")
   {
      if(entry_price < (ask - tolerance))
         return "BUY_LIMIT";
      if(entry_price > (ask + tolerance))
         return "BUY_STOP";
      return "";
   }

   if(entry_price > (bid + tolerance))
      return "SELL_LIMIT";
   if(entry_price < (bid - tolerance))
      return "SELL_STOP";
   return "";
}

bool PendingDistanceOk(string kind, double order_price, double ask, double bid, double min_distance)
{
   if(min_distance <= 0.0)
      return true;

   if(kind == "BUY_LIMIT")
      return (ask - order_price) >= min_distance;
   if(kind == "BUY_STOP")
      return (order_price - ask) >= min_distance;
   if(kind == "SELL_LIMIT")
      return (order_price - bid) >= min_distance;
   if(kind == "SELL_STOP")
      return (bid - order_price) >= min_distance;

   return true;
}

bool PlacePending(string kind, double lot, string symbol, double price, double sl, double tp, string comment)
{
   ENUM_ORDER_TYPE_TIME ttype = ORDER_TIME_GTC;
   datetime expiry = 0;
   if(OrderExpiryMinutes > 0)
   {
      ttype = ORDER_TIME_SPECIFIED;
      expiry = TimeCurrent() + OrderExpiryMinutes * 60;
   }

   if(kind == "BUY_LIMIT")
      return trade.BuyLimit(lot, price, symbol, sl, tp, ttype, expiry, comment);
   if(kind == "BUY_STOP")
      return trade.BuyStop(lot, price, symbol, sl, tp, ttype, expiry, comment);
   if(kind == "SELL_LIMIT")
      return trade.SellLimit(lot, price, symbol, sl, tp, ttype, expiry, comment);
   if(kind == "SELL_STOP")
      return trade.SellStop(lot, price, symbol, sl, tp, ttype, expiry, comment);
   return false;
}


void ShowStatusPanel(string title, string body, bool is_error = true)
{
   PanelDelete(panelPrefix + "STATUS_BG");
   PanelDelete(panelPrefix + "STATUS_TITLE");
   PanelDelete(panelPrefix + "STATUS_BODY");
   PanelDelete(panelPrefix + "STATUS_OK");

   int x = 20;
   int y = 330;
   int w = 420;
   int h = 150;
   color bg = is_error ? (color)0x2A1616 : (color)0x112016;
   color border = is_error ? clrTomato : (color)0x88D498;
   color titleClr = is_error ? clrTomato : (color)0x88D498;

   PanelRect(panelPrefix + "STATUS_BG", x, y, w, h, bg, border);
   PanelLabel(panelPrefix + "STATUS_TITLE", title, x + 14, y + 12, 13, titleClr);
   PanelLabel(panelPrefix + "STATUS_BODY", body, x + 14, y + 40, 10, clrWhite, "Segoe UI");
   PanelButton(panelPrefix + "STATUS_OK", "OK", x + w - 90, y + h - 34, 64, 22, border, clrBlack);
   status_visible = true;
   ChartRedraw();
}

void ClearStatusPanel()
{
   PanelDelete(panelPrefix + "STATUS_BG");
   PanelDelete(panelPrefix + "STATUS_TITLE");
   PanelDelete(panelPrefix + "STATUS_BODY");
   PanelDelete(panelPrefix + "STATUS_OK");
   status_visible = false;
}

void PanelDelete(string name)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

void PanelClear()
{
   string names[] = {
      "BG","TITLE","SUB","SIDE","MODE","ENTRY","SL","TP1","TP2","TP3","LOT","EXEC","SKIP","FOOT"
   };
   for(int i = 0; i < ArraySize(names); i++)
      PanelDelete(panelPrefix + names[i]);
   panel_visible = false;
}

void PanelRect(string name, int x, int y, int w, int h, color bg, color border)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

void PanelLabel(string name, string text, int x, int y, int size, color clr, string font = "Segoe UI Semibold")
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void PanelButton(string name, string text, int x, int y, int w, int h, color bg, color clr)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI Bold");
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

string ModeText()
{
   if(pending_use_pending)
   {
      string exp = OrderExpiryMinutes > 0 ? " exp " + IntegerToString(OrderExpiryMinutes) + "m" : " GTC";
      return "Mode: " + pending_kind + exp;
   }
   return "Mode: " + pending_side + " MARKET";
}

void ShowExecutionPanel()
{
   PanelClear();

   int x = 20;
   int y = 30;
   int w = 360;
   int h = 285;
   color bg = (color)0x17110B;
   color border = (color)0x8B6B2C;
   color gold = (color)0xD7B66D;
   color text = clrWhite;
   color muted = (color)0xC0B6A8;
   color green = (color)0x88D498;
   color red = (color)0x6C4A4A;

   PanelRect(panelPrefix + "BG", x, y, w, h, bg, border);
   PanelLabel(panelPrefix + "TITLE", "LESSRISK EXECUTION PANEL", x + 14, y + 14, 13, gold);
   PanelLabel(panelPrefix + "SUB", pending_id + "  |  " + pending_symbol, x + 14, y + 38, 10, muted, "Segoe UI");
   PanelLabel(panelPrefix + "SIDE", pending_side, x + 14, y + 66, 24, pending_side == "BUY" ? green : clrTomato);
   PanelLabel(panelPrefix + "MODE", ModeText(), x + 132, y + 72, 10, muted, "Segoe UI");
   PanelLabel(panelPrefix + "ENTRY", "Entry: " + DoubleToString(pending_entry_price, pending_digits), x + 14, y + 110, 11, text, "Segoe UI");
   PanelLabel(panelPrefix + "SL", "SL: " + DoubleToString(pending_sl, pending_digits), x + 14, y + 134, 11, text, "Segoe UI");
   PanelLabel(panelPrefix + "TP1", "TP1: " + DoubleToString(pending_tp1, pending_digits), x + 14, y + 158, 11, text, "Segoe UI");
   PanelLabel(panelPrefix + "TP2", "TP2: " + DoubleToString(pending_tp2, pending_digits), x + 14, y + 182, 11, text, "Segoe UI");
   PanelLabel(panelPrefix + "TP3", "TP3: " + DoubleToString(pending_tp3, pending_digits), x + 14, y + 206, 11, text, "Segoe UI");
   PanelLabel(panelPrefix + "LOT", "Lot: " + DoubleToString(pending_lot, 2) + "  |  Type: " + pending_type + "  |  Tier: " + pending_tier, x + 14, y + 234, 10, muted, "Segoe UI");
   PanelButton(panelPrefix + "EXEC", pending_side == "BUY" ? "EXECUTE BUY" : "EXECUTE SELL", x + 14, y + 252, 160, 24, pending_side == "BUY" ? green : clrTomato, clrBlack);
   PanelButton(panelPrefix + "SKIP", "SKIP", x + 186, y + 252, 90, 24, red, clrWhite);
   PanelLabel(panelPrefix + "FOOT", "TP1 wordt gebruikt voor execution. TP2/TP3 blijven zichtbaar als plan.", x + 14, y + 280, 9, muted, "Segoe UI");

   panel_visible = true;
   ChartRedraw();
}

void ResetPendingSignal(bool clear_file)
{
   pending_id = "";
   pending_symbol = "";
   pending_side = "";
   pending_kind = "";
   pending_entry = "";
   pending_tier = "";
   pending_type = "";
   pending_lot = 0.0;
   pending_sl = 0.0;
   pending_tp1 = 0.0;
   pending_tp2 = 0.0;
   pending_tp3 = 0.0;
   pending_entry_price = 0.0;
   pending_reference_price = 0.0;
   pending_min_distance = 0.0;
   pending_use_pending = false;
   pending_digits = 2;
   if(clear_file)
      ClearSignalFile();
   PanelClear();
}

bool ExecutePendingSignal()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);

   bool ok = false;
   string comment = "LRNG " + pending_id;
   if(pending_use_pending)
      ok = PlacePending(pending_kind, pending_lot, pending_symbol, pending_entry_price, pending_sl, pending_tp1, comment);
   else if(pending_side == "BUY")
      ok = trade.Buy(pending_lot, pending_symbol, 0.0, pending_sl, pending_tp1, comment);
   else if(pending_side == "SELL")
      ok = trade.Sell(pending_lot, pending_symbol, 0.0, pending_sl, pending_tp1, comment);

   if(ok)
   {
      if(pending_use_pending)
         Print("LRNG pending sent: ", pending_kind, " ", pending_symbol, " lot=", pending_lot, " entry=", pending_entry_price, " id=", pending_id);
      else
         Print("LRNG trade sent: ", pending_side, " ", pending_symbol, " lot=", pending_lot, " id=", pending_id);
      ResetPendingSignal(true);
      return true;
   }

   ShowTradeFailure(pending_id, pending_side, pending_symbol, pending_lot);
   ResetPendingSignal(true);
   return false;
}

void PrepareSignalPanel(string id, string symbol, string side, double lot, double sl, double tp1, double tp2, double tp3,
                        double entry_price, string entry_text, string tier, string stype,
                        bool use_pending, string kind, double reference_price, double min_distance, int digits)
{
   pending_id = id;
   pending_symbol = symbol;
   pending_side = side;
   pending_lot = lot;
   pending_sl = sl;
   pending_tp1 = tp1;
   pending_tp2 = tp2;
   pending_tp3 = tp3;
   pending_entry_price = entry_price;
   pending_entry = entry_text;
   pending_tier = tier;
   pending_type = stype;
   pending_use_pending = use_pending;
   pending_kind = kind;
   pending_reference_price = reference_price;
   pending_min_distance = min_distance;
   pending_digits = digits;

   ShowExecutionPanel();
}

void ProcessSignal()
{
   if(panel_visible)
      return;

   string id = ValueOf("id");
   if(id == "" || id == last_id)
      return;

   string symbol = ValueOf("symbol");
   string side   = ValueOf("side");
   StringToUpper(side);
   double signal_lot = NumVal("lot", DefaultLot);
   double lot    = ForceDefaultLot ? DefaultLot : signal_lot;
   double sl     = NumVal("sl", 0.0);
   double tp1    = NumVal("tp1", 0.0);
   double tp2    = NumVal("tp2", 0.0);
   double tp3    = NumVal("tp3", 0.0);
   double entry_price = NumVal("entry", 0.0);
   string entry  = ValueOf("entry");
   string tier   = ValueOf("tier");
   string stype  = ValueOf("type");

   if(symbol == "" || (side != "BUY" && side != "SELL"))
      return;

   if(lot <= 0.0)
      lot = DefaultLot;

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
   {
      ShowConfigIssue(id, side, symbol, "Geen geldige marktprijs ontvangen voor dit symbool.");
      last_id = id;
      ClearSignalFile();
      return;
   }

   ask = NormalizePrice(symbol, ask);
   bid = NormalizePrice(symbol, bid);
   if(entry_price > 0.0)
      entry_price = NormalizePrice(symbol, entry_price);
   if(sl > 0.0)
      sl = NormalizePrice(symbol, sl);
   if(tp1 > 0.0)
      tp1 = NormalizePrice(symbol, tp1);
   if(tp2 > 0.0)
      tp2 = NormalizePrice(symbol, tp2);
   if(tp3 > 0.0)
      tp3 = NormalizePrice(symbol, tp3);

   double min_distance = MinStopDistance(symbol);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double entry_tolerance = MathMax(min_distance, point * 5.0);

   string pending_kind_local = PendingKind(side, entry_price, ask, bid, entry_tolerance);
   bool use_pending = (pending_kind_local != "");
   double reference_price = use_pending ? entry_price : (side == "BUY" ? ask : bid);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   last_id = id;

   if(!HasDirectionalLevels(side, reference_price, sl, tp1))
   {
      ShowConfigIssue(id, side, symbol,
         "SL/TP liggen niet logisch rond de gekozen entry.\n" +
         "Voor BUY moet SL < entry < TP.\n" +
         "Voor SELL moet TP < entry < SL.");
      ClearSignalFile();
      return;
   }

   if(!HasStopDistance(side, reference_price, sl, tp1, min_distance))
   {
      ShowConfigIssue(id, side, symbol,
         "SL of TP staat te dicht op de referentieprijs voor deze broker.\n" +
         "Minimale afstand: " + DoubleToString(min_distance, digits) + ".");
      ClearSignalFile();
      return;
   }

   if(use_pending && !PendingDistanceOk(pending_kind_local, entry_price, ask, bid, min_distance))
   {
      ShowConfigIssue(id, side, symbol,
         "Pending entry ligt te dicht op de actuele marktprijs voor deze broker.\n" +
         "Minimale afstand: " + DoubleToString(min_distance, digits) + ".");
      ClearSignalFile();
      return;
   }

   if(RequireConfirm)
   {
      PrepareSignalPanel(id, symbol, side, lot, sl, tp1, tp2, tp3, entry_price, entry, tier, stype,
                         use_pending, pending_kind_local, reference_price, min_distance, digits);
      Print("LRNG panel ready: ", id, " ", side, " ", symbol, " mode=", use_pending ? pending_kind_local : "MARKET");
      return;
   }

   PrepareSignalPanel(id, symbol, side, lot, sl, tp1, tp2, tp3, entry_price, entry, tier, stype,
                      use_pending, pending_kind_local, reference_price, min_distance, digits);
   ExecutePendingSignal();
}

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   EventSetTimer(2);
   Print("LRNG TradeReceiver active. Waiting for ", SignalFile);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   PanelClear();
   ClearStatusPanel();
}

void OnTimer()
{
   ProcessSignal();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == panelPrefix + "STATUS_OK")
   {
      ClearStatusPanel();
      return;
   }

   if(sparam == panelPrefix + "EXEC")
   {
      ExecutePendingSignal();
      return;
   }

   if(sparam == panelPrefix + "SKIP")
   {
      Print("LRNG signal skipped by user: ", pending_id);
      ResetPendingSignal(true);
      return;
   }
}
