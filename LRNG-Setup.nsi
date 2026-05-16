; ============================================================
; Less Risk No Glory — MT5 EA Installer
; Version: 2026.05.16
; EA polls server directly — no Helper.exe required
; ============================================================
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

!define APP_NAME    "LessRisk MT5 EA"
!define APP_VERSION "3.02"
!define BUILD_DATE  "2026.05.16"
!define APP_PUBLISHER "Less Risk No Glory"
!define APP_URL     "https://projects.doodsbang.nl/LRNG/"
!define APP_DIR     "Less Risk No Glory\MT5 EA"
!define OUT_DIR     "dist-installer"
!define OUT_FILE    "LessRisk_Installer_v302.exe"
!define API_URL     "https://projects.doodsbang.nl/LRNG/api"

Name "${APP_NAME} v${APP_VERSION}"
OutFile "${OUT_DIR}\${OUT_FILE}"
InstallDir "$PROGRAMFILES64\${APP_DIR}"
InstallDirRegKey HKCU "Software\${APP_PUBLISHER}\${APP_NAME}" "InstallDir"
RequestExecutionLevel admin
Unicode True
BrandingText "Less Risk No Glory"

VIProductVersion "3.0.1.0"
VIAddVersionKey "ProductName"    "${APP_NAME}"
VIAddVersionKey "CompanyName"    "${APP_PUBLISHER}"
VIAddVersionKey "LegalCopyright" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "Less Risk No Glory MT5 EA Installer"
VIAddVersionKey "FileVersion"    "${APP_VERSION}"

; ---- Branding ------------------------------------------------
!define MUI_ABORTWARNING
!define MUI_ICON    "branding/appicon.ico"
!define MUI_UNICON  "branding/appicon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "branding/installer-sidebar.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "branding/installer-banner.bmp"
!define MUI_HEADERIMAGE_RIGHT

; ---- Pages ---------------------------------------------------
!define MUI_WELCOMEPAGE_TITLE   "$(WELCOME_TITLE)"
!define MUI_WELCOMEPAGE_TEXT    "$(WELCOME_TEXT)"
!define MUI_FINISHPAGE_TEXT     "$(FINISH_TEXT)"
!define MUI_FINISHPAGE_LINK     "$(FINISH_LINK_TEXT)"
!define MUI_FINISHPAGE_LINK_LOCATION "${APP_URL}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LRNG-LICENSE-EN-NL.txt"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ---- Languages -----------------------------------------------
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Dutch"

; ---- Language strings ----------------------------------------
LangString WELCOME_TITLE   ${LANG_ENGLISH} "Welcome to Less Risk No Glory MT5 EA"
LangString WELCOME_TITLE   ${LANG_DUTCH}   "Welkom bij Less Risk No Glory MT5 EA"

LangString WELCOME_TEXT    ${LANG_ENGLISH} "This wizard will install the LRNG_TradeReceiver Expert Advisor (v${APP_VERSION}) into your MetaTrader 5 terminal.$\r$\n$\r$\nThe EA connects directly to the signal server — no extra software or background helper is needed.$\r$\n$\r$\nClick Next to continue."
LangString WELCOME_TEXT    ${LANG_DUTCH}   "Deze wizard installeert de LRNG_TradeReceiver Expert Advisor (v${APP_VERSION}) in je MetaTrader 5-terminal.$\r$\n$\r$\nDe EA verbindt direct met de signaalserver — geen extra software of achtergrond-helper nodig.$\r$\n$\r$\nKlik op Volgende om door te gaan."

LangString FINISH_TEXT     ${LANG_ENGLISH} "Installation complete.$\r$\n$\r$\nThe WebRequest URL has been set automatically.$\r$\n$\r$\nNext steps:$\r$\n1. Open MT5$\r$\n2. Drag LRNG_TradeReceiver onto a chart$\r$\n3. Enable Algo Trading (toolbar button)$\r$\n$\r$\nIf the panel shows 'WebRequest BLOCKED', add manually:$\r$\n${API_URL}"
LangString FINISH_TEXT     ${LANG_DUTCH}   "Installatie voltooid.$\r$\n$\r$\nDe WebRequest URL is automatisch ingesteld.$\r$\n$\r$\nVolgende stappen:$\r$\n1. Open MT5$\r$\n2. Sleep LRNG_TradeReceiver naar een chart$\r$\n3. Zet Algo Trading aan (werkbalk)$\r$\n$\r$\nToont het paneel 'WebRequest GEBLOKKEERD', voeg dan handmatig toe:$\r$\n${API_URL}"

LangString FINISH_LINK_TEXT ${LANG_ENGLISH} "Open Less Risk No Glory website"
LangString FINISH_LINK_TEXT ${LANG_DUTCH}   "Open Less Risk No Glory website"

LangString SEC_EA_NAME     ${LANG_ENGLISH} "MT5 Expert Advisor (required)"
LangString SEC_EA_NAME     ${LANG_DUTCH}   "MT5 Expert Advisor (vereist)"
LangString SEC_EA_DESC     ${LANG_ENGLISH} "Installs LRNG_TradeReceiver.ex5 into your MT5 Experts folder. Polls the signal server directly every 2 seconds. No Helper app needed."
LangString SEC_EA_DESC     ${LANG_DUTCH}   "Installeert LRNG_TradeReceiver.ex5 in je MT5 Experts-map. Pollt de signaalserver direct elke 2 seconden. Geen Helper-app nodig."

LangString SEC_URL_NAME    ${LANG_ENGLISH} "Set MT5 WebRequest URL (recommended)"
LangString SEC_URL_NAME    ${LANG_DUTCH}   "MT5 WebRequest URL instellen (aanbevolen)"
LangString SEC_URL_DESC    ${LANG_ENGLISH} "Whitelists ${API_URL} in MT5 so the EA can reach the signal server. Without this the EA shows 'WebRequest BLOCKED'."
LangString SEC_URL_DESC    ${LANG_DUTCH}   "Voegt ${API_URL} toe aan de MT5 WebRequest-whitelist zodat de EA de signaalserver kan bereiken. Zonder dit toont de EA 'WebRequest GEBLOKKEERD'."

LangString SEC_DOCS_NAME   ${LANG_ENGLISH} "Documentation & Quick Start"
LangString SEC_DOCS_NAME   ${LANG_DUTCH}   "Documentatie & Snelstart"
LangString SEC_DOCS_DESC   ${LANG_ENGLISH} "Installs README (EN+NL), Quick Start guide and license in the installation folder."
LangString SEC_DOCS_DESC   ${LANG_DUTCH}   "Installeert README (NL+EN), snelstartgids en licentie in de installatiemap."

LangString DETAIL_FINDMT5  ${LANG_ENGLISH} "Searching for MetaTrader 5 installation..."
LangString DETAIL_FINDMT5  ${LANG_DUTCH}   "Zoeken naar MetaTrader 5-installatie..."
LangString DETAIL_COPYEA   ${LANG_ENGLISH} "Copying EA to MT5 Experts folder..."
LangString DETAIL_COPYEA   ${LANG_DUTCH}   "EA kopiëren naar MT5 Experts-map..."
LangString DETAIL_SETURL   ${LANG_ENGLISH} "Setting MT5 WebRequest URL..."
LangString DETAIL_SETURL   ${LANG_DUTCH}   "MT5 WebRequest URL instellen..."
LangString DETAIL_NOMT5    ${LANG_ENGLISH} "MetaTrader 5 not found. EA copied to install folder — move LRNG_TradeReceiver.ex5 to MT5\MQL5\Experts manually."
LangString DETAIL_NOMT5    ${LANG_DUTCH}   "MetaTrader 5 niet gevonden. EA gekopieerd naar installatiemap — verplaats LRNG_TradeReceiver.ex5 handmatig naar MT5\MQL5\Experts."

; ==============================================================
; SECTION: Core EA install
; ==============================================================
Section "$(SEC_EA_NAME)" SEC_EA
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "LRNG_TradeReceiver.ex5"

  ; Find MT5 via registry (multiple common install paths)
  DetailPrint "$(DETAIL_FINDMT5)"
  ClearErrors
  ReadRegStr $R0 HKCU "Software\MetaQuotes\Terminal" "Default"
  ${If} ${Errors}
    ReadRegStr $R0 HKLM "Software\MetaQuotes\Terminal" "Default"
  ${EndIf}

  ${If} $R0 != ""
    DetailPrint "$(DETAIL_COPYEA)"
    CreateDirectory "$R0\MQL5\Experts"
    CopyFiles "$INSTDIR\LRNG_TradeReceiver.ex5" "$R0\MQL5\Experts\LRNG_TradeReceiver.ex5"
  ${Else}
    ; Fallback: search common paths
    ${If} ${FileExists} "$PROGRAMFILES64\MetaTrader 5\terminal64.exe"
      StrCpy $R0 "$PROGRAMFILES64\MetaTrader 5"
    ${ElseIf} ${FileExists} "$PROGRAMFILES\MetaTrader 5\terminal64.exe"
      StrCpy $R0 "$PROGRAMFILES\MetaTrader 5"
    ${Else}
      DetailPrint "$(DETAIL_NOMT5)"
      Goto ea_done
    ${EndIf}
    DetailPrint "$(DETAIL_COPYEA)"
    CreateDirectory "$R0\MQL5\Experts"
    CopyFiles "$INSTDIR\LRNG_TradeReceiver.ex5" "$R0\MQL5\Experts\LRNG_TradeReceiver.ex5"
  ${EndIf}

  ea_done:

  ; Registry entries
  WriteRegStr HKCU "Software\${APP_PUBLISHER}\${APP_NAME}" "InstallDir"  "$INSTDIR"
  WriteRegStr HKCU "Software\${APP_PUBLISHER}\${APP_NAME}" "Version"     "${APP_VERSION}"
  WriteRegStr HKCU "Software\${APP_PUBLISHER}\${APP_NAME}" "BuildDate"   "${BUILD_DATE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName"     "${APP_NAME} v${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher"       "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion"  "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout"    "${APP_URL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\LessRisk"
  CreateShortcut "$SMPROGRAMS\LessRisk\Uninstall LessRisk MT5 EA.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

; ==============================================================
; SECTION: WebRequest URL
; ==============================================================
Section "$(SEC_URL_NAME)" SEC_URL
  DetailPrint "$(DETAIL_SETURL)"
  SetOutPath "$INSTDIR"
  File "lrng-url-setup.ps1"
  ExecWait 'powershell.exe -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "$INSTDIR\lrng-url-setup.ps1"'
  Delete "$INSTDIR\lrng-url-setup.ps1"
SectionEnd

; ==============================================================
; SECTION: Documentation
; ==============================================================
Section "$(SEC_DOCS_NAME)" SEC_DOCS
  SetOutPath "$INSTDIR"
  File "README-EN.md"
  File "README-NL.md"
  File "QUICK-START.html"
  File "LRNG-LICENSE-EN-NL.txt"
  CreateShortcut "$SMPROGRAMS\LessRisk\LessRisk Quick Start.lnk" "$INSTDIR\QUICK-START.html"
SectionEnd

; ==============================================================
; UNINSTALL
; ==============================================================
Section "Uninstall"
  Delete "$INSTDIR\LRNG_TradeReceiver.ex5"
  Delete "$INSTDIR\README-EN.md"
  Delete "$INSTDIR\README-NL.md"
  Delete "$INSTDIR\QUICK-START.html"
  Delete "$INSTDIR\LRNG-LICENSE-EN-NL.txt"
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$SMPROGRAMS\LessRisk\LessRisk Quick Start.lnk"
  Delete "$SMPROGRAMS\LessRisk\Uninstall LessRisk MT5 EA.lnk"
  RMDir  "$SMPROGRAMS\LessRisk"
  RMDir  "$INSTDIR"
  DeleteRegKey HKCU "Software\${APP_PUBLISHER}\${APP_NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd

