# Less Risk No Glory — MT5 Trade Receiver

**Versie:** 3.01  
**EA-type:** Expert Advisor voor MetaTrader 5 (directe serverpolling, geen Helper nodig)  
**Uitgever:** Less Risk No Glory  
**Website:** https://projects.doodsbang.nl/LRNG/

---

## Wat doet het?

De **LRNG_TradeReceiver** EA verbindt je MetaTrader 5-terminal direct met de Less Risk No Glory signaalserver. Zodra een handelssignaal wordt gepubliceerd (via Telegram of het dashboard), pikt de EA het binnen enkele seconden op en toont een bevestigingspaneel op je chart. **Jij bevestigt altijd handmatig voordat er een order wordt geplaatst.**

Geen achtergrond-helper, geen .ini-bestand, geen extra software nodig.

---

## Vereisten

- Windows-pc of VPS met MetaTrader 5 geïnstalleerd
- Actief Less Risk No Glory-lidmaatschap
- Stabiele internetverbinding
- AutoTrading (Algo Trading) ingeschakeld in MT5

---

## Installatie

### Stap 1 — Voer de installer uit
Dubbelklik op `LessRisk_Installer.exe` en volg de wizard.  
De EA wordt automatisch gekopieerd naar je MT5 Experts-map.

### Stap 2 — Sta WebRequest toe in MT5
Open MT5 → **Extra → Instellingen → Expert Advisors**  
Zet vinkje bij **"Allow WebRequest for listed URL"** en voeg toe:
```
https://projects.doodsbang.nl/LRNG/api
```
Klik op OK.

> De installer probeert dit automatisch in te stellen. Als het paneel toch  
> "WebRequest GEBLOKKEERD" toont, voeg de URL dan handmatig toe zoals hierboven.

### Stap 3 — Koppel de EA aan een chart
1. Open de Navigator in MT5 en vouw **Expert Advisors** uit
2. Sleep **LRNG_TradeReceiver** naar een chart (bijv. BTCUSD H1)
3. In de EA-instellingen → tabblad **Common**: schakel **Allow Algo Trading** in
4. Klik OK — het smiley-icoontje verschijnt rechtsbovenin de chart

### Stap 4 — Zet AutoTrading aan
Klik op de **Algo Trading**-knop in de MT5-werkbalk (moet groen/aan zijn).

---

## Hoe werken signalen?

1. Een signaal wordt gepubliceerd op de LRNG-server (getriggerd vanuit Telegram of het dashboard)
2. De EA pollt de server elke 2 seconden
3. Er verschijnt een paneel op de chart met:
   - **SELL / BUY** richting + symbool
   - Instap, Stop Loss, TP1 / TP2 / TP3
   - Risicobedrag, Winstdoel, R:R-verhouding
   - Risico %, Verwachte waarde, Saldo, Winratio
4. Klik op **EXECUTE** om de order te plaatsen, of **SKIP** om te sluiten
5. Het signaal is 30 minuten geldig (afteltimer zichtbaar in paneel)

---

## EA-instellingen

| Instelling | Standaard | Beschrijving |
|---|---|---|
| ServerUrl | https://projects.doodsbang.nl/LRNG/api | Signaalserver endpoint |
| SignalKey | (vooringevuld) | Jouw persoonlijke toegangssleutel |
| ForceDefaultLot | true | Gebruik DefaultLot i.p.v. serverwaarde |
| DefaultLot | 0.50 | Lotgrootte per trade |
| MagicNumber | 777005 | Uniek ID voor EA-orders |
| SignalValidMins | 30 | Hoe lang een signaal actief blijft |
| PlayAlertSound | true | Geluid afspelen bij nieuw signaal |

---

## Ondersteunde symbolen

De EA werkt met elk symbool beschikbaar bij jouw broker. Standaardsignalen:
- **XAUUSD** (Goud)
- **BTCUSD** (Bitcoin)
- **NAS100 / NAS1** (Nasdaq)

Symboolnamen kunnen per broker verschillen. Als een symbool niet beschikbaar is, toont het paneel een waarschuwing en slaat het signaal automatisch over.

---

## Problemen oplossen

**"WebRequest GEBLOKKEERD"** in het Experts-logboek  
→ Voeg `https://projects.doodsbang.nl/LRNG/api` toe aan de MT5 WebRequest-whitelist (Extra → Instellingen → Expert Advisors)

**Paneel verschijnt niet**  
→ Controleer of Algo Trading AAN staat (groene knop in werkbalk)  
→ Controleer of de EA aan een chart is gekoppeld (smiley-icoontje)  
→ Kijk in het tabblad Experts in MT5 voor foutmeldingen

**Signaal was verlopen voordat ik kon klikken**  
→ Signalen zijn 30 minuten geldig. Bij de volgende geplande sessie verschijnt een nieuw signaal.

**Verkeerde lotgrootte geplaatst**  
→ Stel `ForceDefaultLot = true` in en pas `DefaultLot` aan in de EA-instellingen

---

## Verwijderen

Voer **Uninstall LessRisk** uit vanuit het Startmenu of de installatiemap.  
De EA wordt automatisch verwijderd uit de MT5 Experts-map.

---

## Risicowaarschuwing

Handelen brengt een substantieel verliesrisico met zich mee. Deze EA en zijn signalen vormen geen financieel advies. Beoordeel elk signaal altijd zelf vóór executie. Resultaten uit het verleden bieden geen garantie voor de toekomst.

---

*Less Risk No Glory — Discipline vandaag, vrijheid morgen.*
