# LessRisk — LRNG_TradeReceiver EA

**Less Risk No Glory** — MetaTrader 5 Expert Advisor die live signalen ontvangt van de LessRisk server en een interactief trade-panel toont.

## Wat doet de EA?
- Pollt de signaalserver elke 2 seconden (geen Helper-app nodig)
- Toont een dynamisch trade-panel met ENTRY / SL / TP1-3 / risk stats
- Kleuren: BUY = groen, SELL = rood
- Standaard lot: 0.10 (instelbaar via EA parameters)
- Voert pas een order uit na handmatige bevestiging

## Installatie (Windows)
1. Download `LessRisk_Installer_v302.exe`
2. Run als administrator
3. Installer plaatst de EA automatisch in MT5 en stelt de server URL in
4. Open MT5 → sleep `LRNG_TradeReceiver` op een chart
5. Zet Algo Trading aan (toolbar)

## Handmatige installatie
1. Kopieer `LRNG_TradeReceiver.ex5` naar `MT5/MQL5/Experts/`
2. Of open `LRNG_TradeReceiver.mq5` in MetaEditor → F7 (compileer)
3. Server URL: `https://projects.doodsbang.nl/LRNG/api`

## Build pipeline
```
LRNG_TradeReceiver.mq5  →  MetaEditor (F7)  →  LRNG_TradeReceiver.ex5
LRNG_TradeReceiver.ex5  →  makensis LRNG-Setup.nsi  →  LessRisk_Installer_vXXX.exe
```

## Versies
| Versie | Datum | Wijzigingen |
|--------|-------|-------------|
| v3.02 | 2026-05-16 | Dynamische breedte, BGR kleuren fix, 0.10 lot default, layout overlaps opgelost, status-box spacing |
| v3.01 | 2026-05-16 | Direct server polling, geen Helper.exe meer nodig, nieuw risk-panel |
