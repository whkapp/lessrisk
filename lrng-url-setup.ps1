# LRNG MT5 WebRequest URL installer
# Schrijft https://projects.doodsbang.nl naar common.ini van alle MT5 installaties
# MT5 slaat de URL encrypted op in common.ini [Experts] - wij schrijven de bekende waarde direct

$encodedUrl = '001E7889E64BFE20696119B6AE1766738CAAF80E6ED38CAED4CCBE5B036CF0FD5D7B6B81D33803257D7518B59E073D4A203EBED4A20755774A422CC9B21B'

# Sluit MT5 als het open is
@('terminal64', 'terminal') | ForEach-Object {
    $proc = Get-Process -Name $_ -ErrorAction SilentlyContinue
    if ($proc) {
        $proc | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

$dir = [System.Environment]::GetFolderPath('ApplicationData') + '\MetaQuotes\Terminal'
if (-not (Test-Path $dir)) { exit 0 }

Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $ini = Join-Path $_.FullName 'config\common.ini'
    if (-not (Test-Path $ini)) { return }

    $lines = [System.IO.File]::ReadAllLines($ini)

    # Al aanwezig? Sla over.
    if ($lines -like "*$encodedUrl*") { return }

    $inExperts   = $false
    $expertsDone = $false
    $wReqDone    = $false
    $wReqUrlDone = $false
    $result      = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ($line -match '^\[Experts\]') {
            $inExperts   = $true
            $expertsDone = $true
        } elseif ($line -match '^\[') {
            if ($inExperts) {
                # [Experts] blok eindigt hier — vul ontbrekende keys aan
                if (-not $wReqDone)    { $result.Add('WebRequest=1') }
                if (-not $wReqUrlDone) { $result.Add('WebRequestUrl=' + $encodedUrl) }
            }
            $inExperts = $false
        }

        if ($inExperts -and $line -match '^WebRequest=') {
            $line = 'WebRequest=1'
            $wReqDone = $true
        }
        if ($inExperts -and $line -match '^WebRequestUrl=') {
            if ($line -match '^WebRequestUrl=\s*$') {
                # Lege waarde — schrijf onze URL
                $line = 'WebRequestUrl=' + $encodedUrl
            }
            $wReqUrlDone = $true
        }

        $result.Add($line)
    }

    # [Experts] was het laatste blok in het bestand
    if ($inExperts) {
        if (-not $wReqDone)    { $result.Add('WebRequest=1') }
        if (-not $wReqUrlDone) { $result.Add('WebRequestUrl=' + $encodedUrl) }
    }

    # [Experts] sectie bestond helemaal niet
    if (-not $expertsDone) {
        $result.Add('[Experts]')
        $result.Add('WebRequest=1')
        $result.Add('WebRequestUrl=' + $encodedUrl)
    }

    [System.IO.File]::WriteAllLines($ini, $result)
}
