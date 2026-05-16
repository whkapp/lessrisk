# Less Risk No Glory — MT5 Trade Receiver

**Version:** 3.01  
**EA type:** Expert Advisor for MetaTrader 5 (direct server polling, no Helper required)  
**Publisher:** Less Risk No Glory  
**Website:** https://projects.doodsbang.nl/LRNG/

---

## What it does

The **LRNG_TradeReceiver** EA connects your MetaTrader 5 terminal directly to the Less Risk No Glory signal server. When a trade signal is published (via Telegram or the dashboard), the EA picks it up within seconds and shows a confirmation panel on your chart. **You always confirm manually before any order is placed.**

No background helper app, no .ini file, no extra software needed.

---

## Requirements

- Windows PC or VPS with MetaTrader 5 installed
- Active Less Risk No Glory membership
- Stable internet connection
- AutoTrading (Algo Trading) enabled in MT5

---

## Installation

### Step 1 — Run the installer
Double-click `LessRisk_Installer.exe` and follow the wizard.  
The EA is automatically copied to your MT5 Experts folder.

### Step 2 — Allow WebRequest in MT5
Open MT5 → **Tools → Options → Expert Advisors**  
Check **"Allow WebRequest for listed URL"** and add:
```
https://projects.doodsbang.nl/LRNG/api
```
Click OK.

> The installer attempts to do this automatically. If the panel still shows  
> "WebRequest blocked", add the URL manually as above.

### Step 3 — Attach the EA to a chart
1. In MT5 Navigator, expand **Expert Advisors**
2. Drag **LRNG_TradeReceiver** onto any chart (e.g. BTCUSD H1)
3. In the EA settings → **Common** tab: enable **Allow Algo Trading**
4. Click OK — the EA smiley face appears top-right of the chart

### Step 4 — Enable AutoTrading
Click the **Algo Trading** button in the MT5 toolbar (must be green/on).

---

## How signals work

1. A signal is published on the LRNG server (triggered from Telegram or the dashboard)
2. The EA polls the server every 2 seconds
3. A panel appears on the chart:
   - **SELL / BUY** direction + symbol
   - Entry, Stop Loss, TP1 / TP2 / TP3
   - Risk amount, Profit target, R:R ratio
   - Risk %, Expected value, Balance, Win rate
4. Click **EXECUTE** to place the order, or **SKIP** to dismiss
5. Signal is valid for 30 minutes (countdown shown in panel)

---

## EA Settings

| Setting | Default | Description |
|---|---|---|
| ServerUrl | https://projects.doodsbang.nl/LRNG/api | Signal server endpoint |
| SignalKey | (pre-filled) | Your personal access key |
| ForceDefaultLot | true | Use DefaultLot instead of server lot |
| DefaultLot | 0.50 | Lot size for every trade |
| MagicNumber | 777005 | Unique ID for EA orders |
| SignalValidMins | 30 | How long a signal stays active |
| PlayAlertSound | true | Play alert when signal arrives |

---

## Supported symbols

The EA works with any symbol available on your broker. Default signals cover:
- **XAUUSD** (Gold)
- **BTCUSD** (Bitcoin)
- **NAS100 / NAS1** (Nasdaq)

Symbol names may differ per broker. If a symbol is unavailable, the panel shows a warning and skips the signal automatically.

---

## Troubleshooting

**"WebRequest BLOCKED"** in the Experts log  
→ Add `https://projects.doodsbang.nl/LRNG/api` to MT5 WebRequest whitelist (Tools → Options → Expert Advisors)

**Panel does not appear**  
→ Confirm Algo Trading is ON (green button in toolbar)  
→ Confirm EA is attached to a chart with a smiley face icon  
→ Check Experts tab in MT5 for error messages

**Signal expired before I could click**  
→ Signals are valid for 30 minutes. A new signal will appear at the next scheduled session.

**Wrong lot size placed**  
→ Set `ForceDefaultLot = true` and adjust `DefaultLot` in EA settings

---

## Uninstall

Run **Uninstall LessRisk** from the Start Menu or from the installation folder.  
The EA will be removed from the MT5 Experts folder automatically.

---

## Risk warning

Trading carries substantial risk of loss. This EA and its signals do not constitute financial advice. Always review every signal before executing. Past performance does not guarantee future results.

---

*Less Risk No Glory — Discipline Today, Freedom Tomorrow.*
