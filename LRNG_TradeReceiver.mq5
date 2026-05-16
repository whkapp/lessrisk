//+------------------------------------------------------------------+
//| Less Risk No Glory — Trade Receiver v3.0                          |
//| Pollt server direct — geen Helper of ini-bestand nodig            |
//+------------------------------------------------------------------+
#property strict
#property version   "3.01"
#property description "LRNG receiver — pollt server direct, geen Helper nodig."

#include <Trade/Trade.mqh>

input string ServerUrl      = "https://projects.doodsbang.nl/LRNG/api";
input string SignalKey      = "626f08c12d5ebacd87f1b2143147b21c269c18b18ddaecb1";
input bool   ForceDefaultLot = true;
input double DefaultLot      = 0.10;
input long   MagicNumber     = 777005;
input int    SignalValidMins = 30;
input bool   PlayAlertSound  = true;

CTrade trade;
string panelPrefix   = "LRNG_PANEL_";
bool   panel_visible  = false;
bool   status_visible = false;
datetime panel_shown_at = 0;
string g_clientId    = "";
string g_lastSeenId  = "";
long   g_startedAtMs = 0;    // UTC milliseconds — alleen signalen NA deze tijd worden verwerkt

string pending_id       = "";
string pending_symbol   = "";
string pending_side     = "";
string pending_kind     = "";
string pending_tier     = "";
string pending_type     = "";
string pending_session  = "";
bool   pending_use_pending = false;
double pending_lot      = 0.0;
double pending_sl       = 0.0;
double pending_tp1      = 0.0;
double pending_tp2      = 0.0;
double pending_tp3      = 0.0;
double pending_entry_price     = 0.0;
double pending_reference_price = 0.0;
double pending_min_distance    = 0.0;
int    pending_digits   = 2;

color C_BG     = (color)0x120A0A;
color C_HEADER = (color)0x1E1212;
color C_BORDER = (color)0x6DB6D7;
color C_GOLD   = (color)0x6DB6D7;
color C_MUTED  = (color)0x806A6A;
color C_WHITE  = clrWhite;
color C_GREEN  = (color)0x8ECF3E;
color C_RED    = (color)0x5757FF;
color C_SKIPBG = (color)0x2E1E1E;
color C_BOXBG  = (color)0x1F1313;
color C_BOXBDR = (color)0x3A2A2A;

//+------------------------------------------------------------------+
//| JSON helpers                                                      |
//+------------------------------------------------------------------+
string JsonStr(string json, string key)
{
   string search = "\"" + key + "\":\"";
   int pos = StringFind(json, search);
   if(pos < 0) return "";
   pos += StringLen(search);
   int end = StringFind(json, "\"", pos);
   if(end < 0) return "";
   return StringSubstr(json, pos, end - pos);
}

double JsonNum(string json, string key)
{
   string search = "\"" + key + "\":";
   int pos = StringFind(json, search);
   if(pos < 0) return 0.0;
   pos += StringLen(search);
   string num = "";
   for(int i = pos; i < pos + 32 && i < StringLen(json); i++)
   {
      ushort c = StringGetCharacter(json, i);
      if((c >= '0' && c <= '9') || c == '.' || c == '-')
         num += ShortToString(c);
      else if(num != "")
         break;
   }
   return StringToDouble(num);
}

bool JsonBool(string json, string key, bool fallback = false)
{
   string search = "\"" + key + "\":";
   int pos = StringFind(json, search);
   if(pos < 0) return fallback;
   pos += StringLen(search);
   string sub = StringSubstr(json, pos, 5);
   if(StringFind(sub, "true") == 0)  return true;
   if(StringFind(sub, "false") == 0) return false;
   return fallback;
}

//+------------------------------------------------------------------+
//| Server polling                                                    |
//+------------------------------------------------------------------+
string PollServer()
{
   string url = ServerUrl + "/pending-signal?clientId=" + g_clientId;
   if(SignalKey != "") url += "&k=" + SignalKey;
   if(g_startedAtMs > 0) url += "&since=" + IntegerToString(g_startedAtMs);

   char body[], result[];
   string resp_headers;
   int code = WebRequest("GET", url, "Accept: application/json\r\n", 8000, body, result, resp_headers);
   if(code != 200) return "";
   return CharArrayToString(result);
}

//+------------------------------------------------------------------+
//| Object helpers                                                    |
//+------------------------------------------------------------------+
void ObjDel(string n) { if(ObjectFind(0,n)>=0) ObjectDelete(0,n); }

void MakeRect(string n, int x, int y, int w, int h, color bg, color br, int z=0)
{
   ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,br);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,z);
}

void MakeLbl(string n, string txt, int x, int y, int sz, color cl, string font="Segoe UI Semibold", int z=1)
{
   ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetString(0,n,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_COLOR,cl);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,sz);
   ObjectSetString(0,n,OBJPROP_FONT,font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,z);
}

void MakeBtn(string n, string txt, int x, int y, int w, int h, color bg, color cl, int sz=11, int z=2)
{
   ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetString(0,n,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_COLOR,cl);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,sz);
   ObjectSetString(0,n,OBJPROP_FONT,"Segoe UI Bold");
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,n,OBJPROP_ZORDER,z);
}

void MakeBox(string pfx, string lbl, string val, int x, int y, int w, color valClr, int boxH=48)
{
   int valSz = (boxH >= 44) ? 10 : 9;
   MakeRect(pfx+"_B", x, y, w, boxH, C_BOXBG, C_BOXBDR, 1);
   MakeLbl (pfx+"_L", lbl, x+8, y+5,  7, C_MUTED, "Segoe UI", 2);
   MakeLbl (pfx+"_V", val, x+8, y+boxH/2+2, valSz, valClr, "Segoe UI Semibold", 2);
}

//+------------------------------------------------------------------+
//| Panel                                                             |
//+------------------------------------------------------------------+
void PanelClear()
{
   string ns[] = {
      "BG","HDRBG","LOGO","LOGO2","SUB","LIVE","DIV",
      "DIRBAR","SIDE","SYM","META","SIGID",
      "BOX_EN_B","BOX_EN_L","BOX_EN_V",
      "BOX_SL_B","BOX_SL_L","BOX_SL_V",
      "BOX_LT_B","BOX_LT_L","BOX_LT_V",
      "BOX_T1_B","BOX_T1_L","BOX_T1_V",
      "BOX_T2_B","BOX_T2_L","BOX_T2_V",
      "BOX_T3_B","BOX_T3_L","BOX_T3_V",
      "COUNTDOWN","MODEBAR",
      "BTN_EXEC","BTN_SKIP","DIV2",
      "STAT_BG","DIV3",
      "S_RI_L","S_RI_V","S_PR_L","S_PR_V","S_VO_L","S_VO_V","S_RR_L","S_RR_V",
      "S_RP_L","S_RP_V","S_EV_L","S_EV_V","S_BA_L","S_BA_V","S_WR_L","S_WR_V",
      "FOOT","CDBG","SIDEBG",
      "BOX_RI_B","BOX_RI_L","BOX_RI_V","BOX_PR_B","BOX_PR_L","BOX_PR_V",
      "BOX_VO_B","BOX_VO_L","BOX_VO_V","BOX_RR_B","BOX_RR_L","BOX_RR_V",
      "BOX_RP_B","BOX_RP_L","BOX_RP_V","BOX_EV_B","BOX_EV_L","BOX_EV_V",
      "BOX_BA_B","BOX_BA_L","BOX_BA_V","BOX_WR_B","BOX_WR_L","BOX_WR_V"
   };
   for(int i=0;i<ArraySize(ns);i++) ObjDel(panelPrefix+ns[i]);
   panel_visible = false;
}

void ClearStatus()
{
   ObjDel(panelPrefix+"ST_BG");
   ObjDel(panelPrefix+"ST_TI");
   ObjDel(panelPrefix+"ST_OK");
   for(int i=0;i<4;i++) ObjDel(panelPrefix+"ST_BO"+IntegerToString(i));
   status_visible = false;
}

string MinsLeft()
{
   if(panel_shown_at == 0) return "--:--";
   int rem = SignalValidMins * 60 - (int)(TimeCurrent() - panel_shown_at);
   if(rem <= 0) return "VERLOPEN";
   return StringFormat("%d:%02d", rem/60, rem%60);
}

void UpdateCountdown()
{
   if(!panel_visible) return;
   string n = panelPrefix + "COUNTDOWN";
   bool expired = (TimeCurrent() - panel_shown_at) >= (SignalValidMins * 60);
   if(ObjectFind(0,n) >= 0)
   {
      ObjectSetString(0,n,OBJPROP_TEXT,"Geldig:  " + MinsLeft());
      ObjectSetInteger(0,n,OBJPROP_COLOR, expired ? C_RED : C_GOLD);
   }
}

void ShowPanel()
{
   PanelClear();
   long chartW = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int px=10, py=10;
   int pw = (int)chartW - 20;
   if(pw < 620) pw = 620;
   if(pw > 900) pw = 900;
   int ph = 430;
   color sc      = (pending_side=="BUY") ? C_GREEN : C_RED;
   color sc_dark = (pending_side=="BUY") ? (color)0x101508 : (color)0x080815;

   // Risk calculations
   double tickVal = SymbolInfoDouble(pending_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSz  = SymbolInfoDouble(pending_symbol, SYMBOL_TRADE_TICK_SIZE);
   double slDist  = MathAbs(pending_entry_price - pending_sl);
   double tp1Dist = MathAbs(pending_tp1 - pending_entry_price);
   double tp3Dist = (pending_tp3>0.0) ? MathAbs(pending_tp3 - pending_entry_price) : tp1Dist;
   double riskAmt = (tickSz>0.0) ? pending_lot * slDist  / tickSz * tickVal : 0.0;
   double profAmt = (tickSz>0.0) ? pending_lot * tp3Dist / tickSz * tickVal : 0.0;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskPct = (balance>0.0) ? riskAmt / balance * 100.0 : 0.0;
   double rr      = (slDist>0.0)  ? tp3Dist / slDist : 0.0;
   double winRate = 0.65;
   double expVal  = winRate * profAmt - (1.0 - winRate) * riskAmt;

   // Layout constants — all derived from pw
   int lpad=14, bg=6, bh=48;
   int bw = (pw - 2*lpad - 2*bg) / 3;   // pw=660 → bw=206
   // Flat stat section: 4 columns, each statSep wide
   int statSep = (pw - 2*lpad) / 4;      // pw=660 → 158 per column
   int voff = 62;                         // x-offset from label to value within a column

   // ── Panel + header ───────────────────────────────────────────────
   MakeRect(panelPrefix+"BG",    px, py, pw, ph, C_BG, C_BORDER, 0);
   MakeRect(panelPrefix+"HDRBG", px, py, pw, 52, C_HEADER, C_BORDER, 1);
   MakeLbl (panelPrefix+"LOGO",  "LESS RISK", px+16, py+9,  11, C_RED, "Segoe UI Black", 2);
   MakeLbl (panelPrefix+"LOGO2", "NO GLORY",  px+16, py+28, 9,  C_RED, "Segoe UI Bold",  2);
   MakeLbl (panelPrefix+"LIVE",  "● LIVE",    px+pw-80, py+20, 9, C_GREEN, "Segoe UI Semibold", 2);
   MakeRect(panelPrefix+"DIV",   px, py+52, pw, 1, C_BORDER, C_BORDER, 1);

   // ── Direction bar (68px — ruimte voor symbol + meta + countdown) ─
   int dirY = py+53;
   MakeRect(panelPrefix+"DIRBAR", px, dirY, pw, 68, sc_dark, sc, 1);
   MakeLbl (panelPrefix+"SIDE",   pending_side,   px+16,     dirY+8,  18, sc,     "Segoe UI Black",    2);
   MakeLbl (panelPrefix+"SYM",    pending_symbol, px+16+100, dirY+12, 14, C_WHITE,"Segoe UI Semibold", 2);
   MakeLbl (panelPrefix+"COUNTDOWN","Geldig:  "+MinsLeft(), px+pw-160, dirY+10, 9, C_GOLD, "Segoe UI Semibold", 2);
   // Meta: links uitlijnen onder SYM, afkappen zodat het niet overlapt met countdown
   string metaStr = "";
   if(pending_session != "") metaStr += pending_session;
   if(pending_type    != "") { if(metaStr!="") metaStr += "  \x2022  "; metaStr += pending_type; }
   if(pending_tier    != "") { if(metaStr!="") metaStr += "  \x2022  "; metaStr += pending_tier; }
   int maxMeta = (pw - 198) / 6;
   if(maxMeta < 20) maxMeta = 20;
   if(StringLen(metaStr) > maxMeta) metaStr = StringSubstr(metaStr, 0, maxMeta-2) + "..";
   MakeLbl(panelPrefix+"META", metaStr, px+16, dirY+42, 7, C_MUTED, "Segoe UI", 2);

   // Signal ID + mode — onder direction bar (niet erin)
   string modeStr = pending_use_pending ? pending_kind : pending_side+" MARKET";
   MakeLbl(panelPrefix+"SIGID", "ID: "+pending_id+"  |  "+modeStr, px+16, py+132, 7, C_MUTED, "Segoe UI", 2);

   // ── Trade boxes row 1: Entry | SL | Lot ──────────────────────────
   int r1y = py+152;
   MakeBox(panelPrefix+"BOX_EN","ENTRY",    "$"+DoubleToString(pending_entry_price,pending_digits), px+lpad,           r1y, bw, C_WHITE);
   MakeBox(panelPrefix+"BOX_SL","STOP LOSS","$"+DoubleToString(pending_sl,pending_digits),          px+lpad+bw+bg,     r1y, bw, C_RED);
   MakeBox(panelPrefix+"BOX_LT","LOT",      DoubleToString(pending_lot,2)+" lots",                  px+lpad+2*(bw+bg), r1y, bw, C_WHITE);

   // ── Trade boxes row 2: TP1 | TP2 | TP3 ──────────────────────────
   int r2y = r1y+bh+bg;
   string t2s = pending_tp2>0.0 ? "$"+DoubleToString(pending_tp2,pending_digits) : "—";
   string t3s = pending_tp3>0.0 ? "$"+DoubleToString(pending_tp3,pending_digits) : "—";
   MakeBox(panelPrefix+"BOX_T1","TP 1","$"+DoubleToString(pending_tp1,pending_digits), px+lpad,           r2y, bw, C_GREEN);
   MakeBox(panelPrefix+"BOX_T2","TP 2",t2s,                                            px+lpad+bw+bg,     r2y, bw, C_GREEN);
   MakeBox(panelPrefix+"BOX_T3","TP 3",t3s,                                            px+lpad+2*(bw+bg), r2y, bw, C_GREEN);

   // ── Buttons ───────────────────────────────────────────────────────
   int btnY  = r2y+bh+10;
   int skipW = 88;
   int execW = pw-2*lpad-skipW-bg;
   MakeBtn(panelPrefix+"BTN_EXEC",
           pending_side=="BUY" ? "EXECUTE BUY" : "EXECUTE SELL",
           px+lpad, btnY, execW, 42, sc, clrBlack, 12, 3);
   MakeBtn(panelPrefix+"BTN_SKIP","SKIP",
           px+lpad+execW+bg, btnY, skipW, 42, C_SKIPBG, C_MUTED, 10, 3);

   // ── Gold separator ────────────────────────────────────────────────
   int div2Y = btnY+42+8;
   MakeRect(panelPrefix+"DIV2", px, div2Y, pw, 2, C_BORDER, C_BORDER, 1);

   // ── Risk stats — flat inline pairs, no box borders ────────────────
   // Layout: 4 columns × 2 rows. Each cell: label(7pt muted) then value(9pt colored) on same line.
   // col positions: px+lpad + n*statSep  (n=0..3)
   int sr1 = div2Y+2+10;   // stats row 1 y
   int sr2 = sr1+28+4;     // stats row 2 y

   // Subtle background strip behind stats
   MakeRect(panelPrefix+"STAT_BG", px, div2Y+2, pw, 74, (color)0x180C0C, (color)0x180C0C, 1);
   MakeRect(panelPrefix+"DIV3",    px, sr1+22,  pw, 1,  (color)0x2E1E1E, (color)0x2E1E1E, 2);

   // Row 1: RISK | PROFIT | VOL | RR
   MakeLbl(panelPrefix+"S_RI_L","RISK",   px+lpad+0*statSep,      sr1, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_RI_V","$"+DoubleToString(riskAmt,2),    px+lpad+0*statSep+voff, sr1, 9, C_RED,   "Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_PR_L","PROFIT", px+lpad+1*statSep,      sr1, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_PR_V","$"+DoubleToString(profAmt,2),    px+lpad+1*statSep+voff, sr1, 9, C_GREEN, "Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_VO_L","VOL",    px+lpad+2*statSep,      sr1, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_VO_V",DoubleToString(pending_lot,2),    px+lpad+2*statSep+voff, sr1, 9, C_WHITE, "Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_RR_L","RR",     px+lpad+3*statSep,      sr1, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_RR_V","1:"+DoubleToString(rr,2),        px+lpad+3*statSep+voff, sr1, 9, C_WHITE, "Segoe UI Semibold", 3);

   // Row 2: RISK% | EXP.VAL | BALANCE | WIN%
   MakeLbl(panelPrefix+"S_RP_L","RISK%",  px+lpad+0*statSep,      sr2, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_RP_V",DoubleToString(riskPct,2)+"%",    px+lpad+0*statSep+voff, sr2, 9, C_RED,                    "Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_EV_L","EXP",    px+lpad+1*statSep,      sr2, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_EV_V","$"+DoubleToString(expVal,2),     px+lpad+1*statSep+voff, sr2, 9, expVal>=0.0?C_GREEN:C_RED,"Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_BA_L","BAL",    px+lpad+2*statSep,      sr2, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_BA_V","$"+DoubleToString(balance,0),    px+lpad+2*statSep+voff, sr2, 9, C_WHITE, "Segoe UI Semibold", 3);
   MakeLbl(panelPrefix+"S_WR_L","WIN",    px+lpad+3*statSep,      sr2, 7, C_MUTED, "Segoe UI", 3);
   MakeLbl(panelPrefix+"S_WR_V",IntegerToString((int)(winRate*100))+"%", px+lpad+3*statSep+voff, sr2, 9, C_GREEN, "Segoe UI Semibold", 3);

   // ── Footer ────────────────────────────────────────────────────────
   int footY = div2Y+2+74+6;
   MakeLbl(panelPrefix+"FOOT","DISCIPLINE TODAY, FREEDOM TOMORROW.",
           px+lpad, footY, 7, C_MUTED, "Segoe UI", 2);

   panel_visible  = true;
   panel_shown_at = TimeCurrent();
   ChartRedraw();
}

void ShowStatus(string title, string body, bool is_err=true)
{
   ClearStatus();
   int x=10, y=10, w=660, h=210;
   color bdr = is_err ? C_RED : C_GREEN;
   MakeRect(panelPrefix+"ST_BG", x,y,w,h, is_err?(color)0x05051A:(color)0x0A1A05, bdr, 10);
   MakeLbl (panelPrefix+"ST_TI", title, x+16, y+14, 13, bdr, "Segoe UI Bold", 11);
   // Body split on \n — show up to 3 lines with 30px spacing to prevent overlap
   int p=0, line=0;
   while(line<3 && p<=StringLen(body))
   {
      int nl = StringFind(body,"\n",p);
      if(nl<0) nl=StringLen(body);
      string row = StringSubstr(body,p,nl-p);
      if(StringLen(row)>0)
         MakeLbl(panelPrefix+"ST_BO"+IntegerToString(line), row, x+16, y+52+line*30, 10, C_WHITE, "Segoe UI", 11);
      line++;
      p=nl+1;
   }
   MakeBtn(panelPrefix+"ST_OK","  SLUITEN  ", x+16, y+h-52, w-32, 36, bdr, clrBlack, 12, 12);
   status_visible = true;
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Trade logic                                                       |
//+------------------------------------------------------------------+
string RetcodeHint(uint rc)
{
   switch(rc)
   {
      case 10016: return "Stops ongeldig voor deze broker.";
      case 10017: return "Trading staat uit voor dit symbool.";
      case 10018: return "Markt is gesloten.";
      case 10019: return "Onvoldoende marge.";
      case 10020: return "Prijs veranderd — probeer opnieuw.";
      case 10021: return "Geen geldige marktprijs.";
      case 10027: return "AutoTrading staat uit — zet het aan.";
   }
   return "Order geweigerd. Check Journal voor details.";
}

double MinStop(string sym)
{
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(pt<=0.0) return 0.0;
   long sl=SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL);
   long fr=SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL);
   return pt * (double)MathMax(sl,fr);
}

bool DirOk(string side, double ref, double sl, double tp)
{
   if(sl<=0.0||tp<=0.0) return false;
   return (side=="BUY") ? (sl<ref && tp>ref) : (sl>ref && tp<ref);
}

bool DistOk(string side, double ref, double sl, double tp, double mind)
{
   if(mind<=0.0) return true;
   return (side=="BUY") ? ((ref-sl)>=mind && (tp-ref)>=mind)
                        : ((sl-ref)>=mind && (ref-tp)>=mind);
}

string PendKind(string side, double ep, double ask, double bid, double tol)
{
   if(ep<=0.0) return "";
   if(side=="BUY")  { if(ep<(ask-tol)) return "BUY_LIMIT"; if(ep>(ask+tol)) return "BUY_STOP"; return ""; }
   if(ep>(bid+tol)) return "SELL_LIMIT";
   if(ep<(bid-tol)) return "SELL_STOP";
   return "";
}

bool PendDistOk(string kind, double op, double ask, double bid, double mind)
{
   if(mind<=0.0) return true;
   if(kind=="BUY_LIMIT")  return (ask-op)>=mind;
   if(kind=="BUY_STOP")   return (op-ask)>=mind;
   if(kind=="SELL_LIMIT") return (op-bid)>=mind;
   if(kind=="SELL_STOP")  return (bid-op)>=mind;
   return true;
}

bool PlacePend(string kind, double lot, string sym, double price, double sl, double tp, string cmt)
{
   if(kind=="BUY_LIMIT")  return trade.BuyLimit (lot,price,sym,sl,tp,ORDER_TIME_GTC,0,cmt);
   if(kind=="BUY_STOP")   return trade.BuyStop  (lot,price,sym,sl,tp,ORDER_TIME_GTC,0,cmt);
   if(kind=="SELL_LIMIT") return trade.SellLimit(lot,price,sym,sl,tp,ORDER_TIME_GTC,0,cmt);
   if(kind=="SELL_STOP")  return trade.SellStop (lot,price,sym,sl,tp,ORDER_TIME_GTC,0,cmt);
   return false;
}

void ResetPending()
{
   pending_id=""; pending_symbol=""; pending_side=""; pending_kind="";
   pending_tier=""; pending_type=""; pending_session="";
   pending_lot=0; pending_sl=0; pending_tp1=0; pending_tp2=0; pending_tp3=0;
   pending_entry_price=0; pending_reference_price=0; pending_min_distance=0;
   pending_use_pending=false; pending_digits=2; panel_shown_at=0;
   PanelClear();
}

bool ExecuteSignal()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   string cmt = "LRNG "+pending_id;
   bool ok = false;
   if(pending_use_pending)
      ok = PlacePend(pending_kind, pending_lot, pending_symbol, pending_entry_price, pending_sl, pending_tp1, cmt);
   else if(pending_side=="BUY")
      ok = trade.Buy (pending_lot, pending_symbol, 0.0, pending_sl, pending_tp1, cmt);
   else if(pending_side=="SELL")
      ok = trade.Sell(pending_lot, pending_symbol, 0.0, pending_sl, pending_tp1, cmt);

   if(ok)
   {
      Print("LRNG order: ",pending_side," ",pending_symbol," lot=",pending_lot," id=",pending_id);
      ShowStatus("Order geplaatst!  "+pending_side+" "+pending_symbol,
                 "Entry: "+DoubleToString(pending_entry_price,pending_digits)+
                 "   SL: "+DoubleToString(pending_sl,pending_digits)+
                 "\nTP1: "+DoubleToString(pending_tp1,pending_digits)+
                 "   Lot: "+DoubleToString(pending_lot,2)+
                 "\nID: "+pending_id, false);
      ResetPending();
      return true;
   }

   uint rc = trade.ResultRetcode();
   ShowStatus("Order niet geplaatst",
              "Setup: "+pending_side+" "+pending_symbol+
              "\nMT5: "+trade.ResultRetcodeDescription()+" ("+IntegerToString((int)rc)+")"+
              "\n"+RetcodeHint(rc), true);
   Print("LRNG trade failed: rc=",rc," id=",pending_id);
   ResetPending();
   return false;
}

//+------------------------------------------------------------------+
//| Signal processing                                                 |
//+------------------------------------------------------------------+
void ProcessServerSignal()
{
   if(panel_visible) { UpdateCountdown(); return; }

   string json = PollServer();
   if(json == "") return;

   if(!JsonBool(json, "ok")) return;

   // Haal signal object op
   int sigPos = StringFind(json, "\"signal\":{");
   if(sigPos < 0) return;
   string sig = StringSubstr(json, sigPos);

   string id = JsonStr(sig, "id");
   if(id == "" || id == g_lastSeenId) return;

   string symbol = JsonStr(sig, "symbol");
   string side   = JsonStr(sig, "side");
   StringToUpper(side);
   if(symbol=="" || (side!="BUY" && side!="SELL")) return;

   double lot = ForceDefaultLot ? DefaultLot : JsonNum(sig, "lot");
   if(lot <= 0.0) lot = DefaultLot;

   double sl  = JsonNum(sig, "sl");
   double tp1 = JsonNum(sig, "tp1");
   double tp2 = JsonNum(sig, "tp2");
   double tp3 = JsonNum(sig, "tp3");
   double ep  = JsonNum(sig, "entry");
   string tier = JsonStr(sig, "tier");
   string stype= JsonStr(sig, "type");
   string sess = JsonStr(sig, "session");

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(ask<=0.0||bid<=0.0)
   {
      ShowStatus("Signaal overgeslagen",
                 "Symbool '"+symbol+"' niet beschikbaar op dit account.\nID: "+id, true);
      g_lastSeenId = id;
      return;
   }

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   ask=NormalizeDouble(ask,digits); bid=NormalizeDouble(bid,digits);
   if(ep>0.0)  ep  = NormalizeDouble(ep, digits);
   if(sl>0.0)  sl  = NormalizeDouble(sl, digits);
   if(tp1>0.0) tp1 = NormalizeDouble(tp1,digits);
   if(tp2>0.0) tp2 = NormalizeDouble(tp2,digits);
   if(tp3>0.0) tp3 = NormalizeDouble(tp3,digits);

   double mind = MinStop(symbol);
   double tol  = MathMax(mind, SymbolInfoDouble(symbol,SYMBOL_POINT)*50.0);
   string kind = PendKind(side,ep,ask,bid,tol);
   bool   usep = (kind!="");
   double ref  = usep ? ep : (side=="BUY" ? ask : bid);

   g_lastSeenId = id;

   if(!DirOk(side,ref,sl,tp1))
   {
      ShowStatus("Signaal niet geldig",
                 "SL/TP niet logisch rond entry.\nBUY: SL<entry<TP   SELL: TP<entry<SL\nID: "+id, true);
      return;
   }
   if(!DistOk(side,ref,sl,tp1,mind))
   {
      ShowStatus("Signaal niet geldig",
                 "SL/TP te dicht op marktprijs.\nMin afstand: "+DoubleToString(mind,digits)+"\nID: "+id, true);
      return;
   }

   pending_id=id; pending_symbol=symbol; pending_side=side;
   pending_lot=lot; pending_sl=sl; pending_tp1=tp1; pending_tp2=tp2; pending_tp3=tp3;
   pending_entry_price=ep>0.0?ep:ref; pending_reference_price=ref;
   pending_min_distance=mind; pending_use_pending=usep;
   pending_kind=kind; pending_tier=tier; pending_type=stype; pending_session=sess;
   pending_digits=digits;

   if(PlayAlertSound) PlaySound("alert2.wav");
   ShowPanel();
   Print("LRNG signaal ontvangen: ",id," ",side," ",symbol," mode=",usep?kind:"MARKET");
}

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   g_clientId    = "lrng_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   g_startedAtMs = (long)TimeGMT() * 1000;
   EventSetTimer(2);
   Print("LRNG TradeReceiver v3.01  client=",g_clientId,"  since=",g_startedAtMs,"  server=",ServerUrl);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   PanelClear();
   ClearStatus();
}

void OnTick() {}

void OnTimer()
{
   ProcessServerSignal();
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sp == panelPrefix+"ST_OK")    { ClearStatus(); return; }
   if(sp == panelPrefix+"BTN_EXEC") { ObjectSetInteger(0,sp,OBJPROP_STATE,false); ExecuteSignal(); return; }
   if(sp == panelPrefix+"BTN_SKIP")
   {
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
      Print("LRNG overgeslagen: ", pending_id);
      ResetPending();
   }
}
