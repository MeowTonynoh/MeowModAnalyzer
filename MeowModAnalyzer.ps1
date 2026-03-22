# Meow Mod Analyzer - PowerShell Script
# Author: Tonynoh
# scans minecraft mods for shady stuff and checks em against known mod databases

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Clear-Host

$Banner = @"

  ███╗   ███╗███████╗ ██████╗ ██╗    ██╗  ███╗   ███╗ ██████╗ ██████╗
  ████╗ ████║██╔════╝██╔═══██╗██║    ██║  ████╗ ████║██╔═══██╗██╔══██╗
  ██╔████╔██║█████╗  ██║   ██║██║ █╗ ██║  ██╔████╔██║██║   ██║██║  ██║
  ██║╚██╔╝██║██╔══╝  ██║   ██║██║███╗██║  ██║╚██╔╝██║██║   ██║██║  ██║
  ██║ ╚═╝ ██║███████╗╚██████╔╝╚███╔███╔╝  ██║ ╚═╝ ██║╚██████╔╝██████╔╝
  ╚═╝     ╚═╝╚══════╝ ╚═════╝  ╚══╝╚══╝   ╚═╝     ╚═╝ ╚═════╝ ╚═════╝

   █████╗ ███╗   ██╗ █████╗ ██╗   ██╗   ██╗███████╗███████╗██████╗
  ██╔══██╗████╗  ██║██╔══██╗██║   ╚██╗ ██╔╝╚══███╔╝██╔════╝██╔══██╗
  ███████║██╔██╗ ██║███████║██║    ╚████╔╝   ███╔╝ █████╗  ██████╔╝
  ██╔══██║██║╚██╗██║██╔══██║██║     ╚██╔╝   ███╔╝  ██╔══╝  ██╔══██╗
  ██║  ██║██║ ╚████║██║  ██║███████╗ ██║   ███████╗███████╗██║  ██║
  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝ ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝

                         \    /\
                          )  ( ')
                         (  /  )
                          \(__)|

"@

Write-Host $Banner -ForegroundColor Cyan
Write-Host ""
Write-Host "  by " -ForegroundColor DarkGray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + ("─" * 74)) -ForegroundColor DarkGray
Write-Host

# ask the user where their mods folder is
Write-Host "Enter path to the mods folder: " -NoNewline
Write-Host "(press Enter to use default)" -ForegroundColor DarkGray
$modsPath = Read-Host "PATH"
Write-Host

if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Continuing with " -NoNewline
    Write-Host $modsPath -ForegroundColor White
    Write-Host
}

if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "❌ Invalid Path!" -ForegroundColor Red
    Write-Host "The directory does not exist or is not accessible." -ForegroundColor Yellow
    Write-Host
    Write-Host "Tried to access: $modsPath" -ForegroundColor Gray
    Write-Host
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  path  " -ForegroundColor DarkGray -NoNewline
Write-Host "$modsPath" -ForegroundColor White
Write-Host

# check if minecraft is already running
$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "  minecraft" -ForegroundColor DarkCyan -NoNewline
        Write-Host "  pid $($mcProcess.Id)  uptime $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor DarkGray
        Write-Host ""
    } catch {
        # couldn't grab process info, no biggie
    }
}

function Get-FileSHA1 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA1).Hash
}

function Get-DownloadSource {
    param([string]$Path)
    $zoneData = Get-Content -Raw -Stream Zone.Identifier $Path -ErrorAction SilentlyContinue
    if ($zoneData -match "HostUrl=(.+)") {
        $url = $matches[1].Trim()
        if ($url -match "mediafire\.com")                                        { return "MediaFire" }
        elseif ($url -match "discord\.com|discordapp\.com|cdn\.discordapp\.com") { return "Discord" }
        elseif ($url -match "dropbox\.com")                                      { return "Dropbox" }
        elseif ($url -match "drive\.google\.com")                                { return "Google Drive" }
        elseif ($url -match "mega\.nz|mega\.co\.nz")                             { return "MEGA" }
        elseif ($url -match "github\.com")                                       { return "GitHub" }
        elseif ($url -match "modrinth\.com")                                     { return "Modrinth" }
        elseif ($url -match "curseforge\.com")                                   { return "CurseForge" }
        elseif ($url -match "anydesk\.com")                                      { return "AnyDesk" }
        elseif ($url -match "doomsdayclient\.com")                               { return "DoomsdayClient" }
        elseif ($url -match "prestigeclient\.vip")                               { return "PrestigeClient" }
        elseif ($url -match "198macros\.com")                                    { return "198Macros" }
        elseif ($url -match "dqrkis\.xyz")                                       { return "Dqrkis" }
        else {
            if ($url -match "https?://(?:www\.)?([^/]+)") { return $matches[1] }
            return $url
        }
    }
    return $null
}

function Query-Modrinth {
    param([string]$Hash)
    try {
        $versionInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if ($versionInfo.project_id) {
            $projectInfo = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($versionInfo.project_id)" -Method Get -UseBasicParsing -ErrorAction Stop
            return @{ Name = $projectInfo.title; Slug = $projectInfo.slug }
        }
    } catch { }
    return @{ Name = ""; Slug = "" }
}

function Query-Megabase {
    param([string]$Hash)
    try {
        $result = Invoke-RestMethod -Uri "https://megabase.vercel.app/api/query?hash=$Hash" -Method Get -UseBasicParsing -ErrorAction Stop
        if (-not $result.error) { return $result.data }
    } catch { }
    return $null
}

# --- detection lists ---
$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "JumpReset", "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "Velocity", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "Virgin", "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill", "NoJumpDelay", "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean", "Argon",
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "Grim", "grim",
    "org.chainlibs.module.impl.modules.Crystal.Y",
    "org.chainlibs.module.impl.modules.Crystal.bF",
    "org.chainlibs.module.impl.modules.Crystal.bM",
    "org.chainlibs.module.impl.modules.Crystal.bY",
    "org.chainlibs.module.impl.modules.Crystal.bq",
    "org.chainlibs.module.impl.modules.Crystal.cv",
    "org.chainlibs.module.impl.modules.Crystal.o",
    "org.chainlibs.module.impl.modules.Blatant.I",
    "org.chainlibs.module.impl.modules.Blatant.bR",
    "org.chainlibs.module.impl.modules.Blatant.bx",
    "org.chainlibs.module.impl.modules.Blatant.cj",
    "org.chainlibs.module.impl.modules.Blatant.dk",
    "imgui", "imgui.gl3", "imgui.glfw",
    "BowAim", "Criticals", "Fakenick", "FakeItem",
    "invsee", "ItemExploit", "Hellion", "hellion",
    "LicenseCheckMixin", "ClientPlayerInteractionManagerAccessor",
    "ClientPlayerEntityMixim", "dev.gambleclient", "obfuscatedAuth",
    "phantom-refmap.json", "xyz.greaj",
    "じ.class", "ふ.class", "ぶ.class", "ぷ.class", "た.class",
    "ね.class", "そ.class", "な.class", "ど.class", "ぐ.class",
    "ず.class", "で.class", "つ.class", "べ.class", "せ.class",
    "と.class", "み.class", "び.class", "す.class", "の.class"
)

$cheatStrings = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal",
    "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
    "hasGlowstone", "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "AutoClicker",
    "Failed to switch to mace after axe!",
    "Breaking shield with axe...",
    "Donut", "JumpReset", "axespam", "axe spam",
    "shieldbreaker", "shield breaker", "EndCrystalItemMixin",
    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "FakeInv", "Friends", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof", "velocity",
    "webmacro", "web macro",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "AutoMace", "AutoFirework", "MaceSwap", "AirAnchor",
    "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "NoFall", "nofall",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "autoCrystalPlaceClock",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "setSelectedSlot", "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onTickMovement", "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing"
)

# ─────────────────────────────────────────────────────────────────────────────
# BYPASS / INJECTION DETECTION
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-BypassScan {
    param([string]$FilePath)

    $flags = [System.Collections.Generic.List[string]]::new()

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $mavenPrefixes = @(
        "com_","org_","net_","io_","dev_","gs_","xyz_",
        "app_","me_","tv_","uk_","be_","fr_","de_"
    )

    function Test-SuspiciousJarName {
        param([string]$JarName)
        $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
        if ($base -match '\d')                                          { return $false }
        foreach ($pfx in $mavenPrefixes) {
            if ($base.ToLower().StartsWith($pfx))                       { return $false }
        }
        if ($base.Length -gt 20)                                        { return $false }
        return $true
    }

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)

        $nestedJars   = @($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $outerClasses = @($zip.Entries | Where-Object { $_.FullName -match "\.class$" })

        # ── 1. SUSPICIOUS NESTED JAR NAME ────────────────────────────────────
        $suspiciousNestedJars = @()
        foreach ($nj in $nestedJars) {
            $njBase = [System.IO.Path]::GetFileName($nj.FullName)
            if (Test-SuspiciousJarName -JarName $njBase) {
                $suspiciousNestedJars += $njBase
            }
        }
        foreach ($sj in $suspiciousNestedJars) {
            $flags.Add("Suspicious nested JAR — no version number, not a known dependency: $sj")
        }

        # ── 2. HOLLOW SHELL ───────────────────────────────────────────────────
        if ($nestedJars.Count -eq 1 -and $outerClasses.Count -lt 3) {
            $njName = [System.IO.Path]::GetFileName(($nestedJars | Select-Object -First 1).FullName)
            $flags.Add("Hollow shell — outer JAR has only $($outerClasses.Count) own class(es) but wraps: $njName")
        }

        # ── Read outer mod ID for later use ──────────────────────────────────
        $outerModId = ""
        $fmje = $zip.Entries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
        if ($fmje) {
            try {
                $s = $fmje.Open()
                $r = New-Object System.IO.StreamReader($s)
                $t = $r.ReadToEnd(); $r.Close(); $s.Close()
                if ($t -match '"id"\s*:\s*"([^"]+)"') { $outerModId = $matches[1] }
            } catch { }
        }

        # ── 3. BYTECODE CHECKS — scan outer + all nested JARs ────────────────
        $allEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $allEntries.Add($e) }

        $innerZips = [System.Collections.Generic.List[object]]::new()
        foreach ($nj in $nestedJars) {
            try {
                $ns = $nj.Open()
                $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close()
                $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $innerZips.Add($iz)
                foreach ($ie in $iz.Entries) { $allEntries.Add($ie) }
            } catch { }
        }

        $runtimeExecFound  = $false
        $httpDownloadFound = $false
        $httpExfilFound    = $false
        $obfuscatedCount   = 0
        $totalClassCount   = 0

        foreach ($entry in $allEntries) {
            $name = $entry.FullName

            if ($name -match "\.class$") {
                $totalClassCount++

                $segs = ($name -replace "\.class$","") -split "/"
                $consecutiveSingle = 0
                $maxConsecutive    = 0
                foreach ($seg in $segs) {
                    if ($seg.Length -eq 1) {
                        $consecutiveSingle++
                        if ($consecutiveSingle -gt $maxConsecutive) { $maxConsecutive = $consecutiveSingle }
                    } else {
                        $consecutiveSingle = 0
                    }
                }
                if ($maxConsecutive -ge 3) { $obfuscatedCount++ }

                try {
                    $st = $entry.Open()
                    $ms2 = New-Object System.IO.MemoryStream
                    $st.CopyTo($ms2)
                    $st.Close()
                    $rawBytes = $ms2.ToArray()
                    $ms2.Dispose()
                    $ct = [System.Text.Encoding]::ASCII.GetString($rawBytes)

                    if ($ct -match "java/lang/Runtime" -and
                        $ct -match "getRuntime" -and
                        $ct -match "exec") {
                        $runtimeExecFound = $true
                    }

                    if ($ct -match "openConnection" -and
                        $ct -match "HttpURLConnection" -and
                        $ct -match "FileOutputStream") {
                        $httpDownloadFound = $true
                    }

                    if ($ct -match "openConnection" -and
                        $ct -match "setDoOutput" -and
                        $ct -match "getOutputStream" -and
                        $ct -match "getProperty") {
                        $httpExfilFound = $true
                    }
                } catch { }
            }
        }

        foreach ($iz in $innerZips) { try { $iz.Dispose() } catch { } }
        $zip.Dispose()

        # ── Emit dangerous-code flags ─────────────────────────────────────────

        $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($obfuscatedCount / $totalClassCount) * 100) } else { 0 }

        if ($runtimeExecFound -and $obfPct -ge 40) {
            $flags.Add("Runtime.exec() inside obfuscated code — mod can execute arbitrary OS commands (combined with heavy obfuscation this is a strong malice indicator)")
        }

        if ($httpDownloadFound) {
            $flags.Add("HTTP file download — mod fetches and writes files from a remote server at runtime (no legitimate Fabric mod does this)")
        }

        if ($httpExfilFound) {
            $flags.Add("HTTP POST exfiltration — mod reads system properties and sends data to an external server (possible token/session theft)")
        }

        if ($totalClassCount -ge 10 -and $obfPct -ge 40) {
            $flags.Add("Heavy obfuscation — $obfPct% of classes have 3+ consecutive single-letter path segments (a/b/c style). Legitimate mods never do this.")
        }

        # ── Fake mod identity (only with corroborating dangerous flags) ───────
        $knownLegitModIds = @(
            "vmp-fabric","vmp","lithium","sodium","iris","fabric-api",
            "modmenu","ferrite-core","lazydfu","starlight","entityculling",
            "memoryleakfix","krypton","c2me-fabric","smoothboot-fabric",
            "immediatelyfast","noisium","threadtweak"
        )
        $dangerCount = ($flags | Where-Object {
            $_ -match "Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR"
        }).Count
        if ($outerModId -and ($knownLegitModIds -contains $outerModId) -and $dangerCount -gt 0) {
            $flags.Add("Fake mod identity — outer JAR claims to be '$outerModId' but dangerous code was found inside (trojanized build)")
        }

    } catch { }

    return $flags
}

# single pass scan — runs pattern matching and raw string search together
function Invoke-ModScan {
    param([string]$FilePath)

    $foundPatterns = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings  = [System.Collections.Generic.HashSet[string]]::new()

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    try {
        $patternRegex = [regex]::new(
            '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
            [System.Text.RegularExpressions.RegexOptions]::Compiled
        )
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        foreach ($entry in $archive.Entries) {
            foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
            if ($entry.FullName -match '\.(class|json)$' -or $entry.FullName -match 'MANIFEST\.MF') {
                try {
                    $stream  = $entry.Open()
                    $reader  = New-Object System.IO.StreamReader($stream)
                    $content = $reader.ReadToEnd()
                    $reader.Close(); $stream.Close()
                    foreach ($m in $patternRegex.Matches($content)) { [void]$foundPatterns.Add($m.Value) }
                } catch { }
            }
        }
        $archive.Dispose()
    } catch { }

    try {
        $stringsExe = @(
            "C:\Program Files\Git\usr\bin\strings.exe",
            "C:\Program Files\Git\mingw64\bin\strings.exe",
            "$env:ProgramFiles\Git\usr\bin\strings.exe",
            "C:\msys64\usr\bin\strings.exe",
            "C:\cygwin64\bin\strings.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($stringsExe) {
            $tmp = Join-Path $env:TEMP "meow_str_$(Get-Random).txt"
            & $stringsExe $FilePath 2>$null | Out-File $tmp -Encoding UTF8
            if (Test-Path $tmp) {
                $raw = Get-Content $tmp -Raw
                Remove-Item $tmp -Force -ErrorAction SilentlyContinue
                foreach ($s in $cheatStrings) {
                    if ($s -eq "velocity") {
                        if ($raw -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                            [void]$foundStrings.Add($s)
                        }
                    } elseif ($raw -match [regex]::Escape($s)) {
                        [void]$foundStrings.Add($s)
                    }
                }
            }
        } else {
            $rawText = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($FilePath))
            foreach ($s in $cheatStrings) {
                if ($s -eq "velocity") {
                    if ($rawText -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                        [void]$foundStrings.Add($s)
                    }
                } elseif ($rawText -match [regex]::Escape($s)) {
                    [void]$foundStrings.Add($s)
                }
            }
            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
                foreach ($entry in ($zip.Entries | Where-Object { $_.Name -like "*.class" })) {
                    try {
                        $stream    = $entry.Open()
                        $reader    = New-Object System.IO.StreamReader($stream)
                        $classText = $reader.ReadToEnd()
                        $reader.Close(); $stream.Close()
                        foreach ($s in $cheatStrings) {
                            if ($s -eq "velocity") {
                                if ($classText -match "velocity(?:hack|module|cheat|bypass|packet|horizontal|vertical|amount|factor|setting)") {
                                    [void]$foundStrings.Add($s)
                                }
                            } elseif ($classText -match [regex]::Escape($s)) {
                                [void]$foundStrings.Add($s)
                            }
                        }
                    } catch { }
                }
                $zip.Dispose()
            } catch { }
        }
    } catch { }

    return @{ Patterns = $foundPatterns; Strings = $foundStrings }
}

$verifiedMods   = @()
$unknownMods    = @()
$suspiciousMods = @()
$bypassMods     = @()

try {
    $jarFiles = Get-ChildItem -Path $modsPath -Filter *.jar -ErrorAction Stop
} catch {
    Write-Host "❌ Error accessing directory: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($jarFiles.Count -eq 0) {
    Write-Host "⚠️  No JAR files found in: $modsPath" -ForegroundColor Yellow
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

$fileWord = if ($jarFiles.Count -eq 1) { "file" } else { "files" }
Write-Host "  found  " -ForegroundColor DarkGray -NoNewline
Write-Host "$($jarFiles.Count) jar $fileWord" -ForegroundColor White
Write-Host

$spinnerFrames = @("⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷")
$totalFiles    = $jarFiles.Count
$idx           = 0

# pass 1 - hash lookup against modrinth and megabase
foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Verifying: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $hash = Get-FileSHA1 -Path $jar.FullName

    if ($hash) {
        $modrinthData = Query-Modrinth -Hash $hash
        if ($modrinthData.Slug) {
            $verifiedMods += [PSCustomObject]@{ ModName = $modrinthData.Name; FileName = $jar.Name; FilePath = $jar.FullName }
            continue
        }
        $megabaseData = Query-Megabase -Hash $hash
        if ($megabaseData.name) {
            $verifiedMods += [PSCustomObject]@{ ModName = $megabaseData.Name; FileName = $jar.Name; FilePath = $jar.FullName }
            continue
        }
    }

    $src = Get-DownloadSource $jar.FullName
    $unknownMods += [PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName; DownloadSource = $src }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

# pass 2 - deep scan every jar for cheat patterns and strings
$modWord = if ($totalFiles -eq 1) { "mod" } else { "mods" }
Write-Host "  scan   " -ForegroundColor DarkGray -NoNewline
Write-Host "deep-scanning $totalFiles $modWord" -ForegroundColor White
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Scanning: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $result = Invoke-ModScan -FilePath $jar.FullName

    if ($result.Patterns.Count -gt 0 -or $result.Strings.Count -gt 0) {
        $suspiciousMods += [PSCustomObject]@{
            FileName = $jar.Name
            Patterns = $result.Patterns
            Strings  = $result.Strings
        }
        $verifiedMods = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

# pass 3 - bypass / injection scan
Write-Host "  bypass " -ForegroundColor DarkGray -NoNewline
Write-Host "injection scan on $totalFiles $modWord" -ForegroundColor White
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Bypass scan: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $bypassFlags = Invoke-BypassScan -FilePath $jar.FullName

    if ($bypassFlags.Count -gt 0) {
        $bypassMods += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $bypassFlags
        }
        $verifiedMods = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
        $unknownMods  = $unknownMods  | Where-Object { $_.FileName -ne $jar.Name }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

# --- results ---
Write-Host ""
Write-Host ("  " + ("─" * 74)) -ForegroundColor DarkGray
Write-Host ""

if ($verifiedMods.Count -gt 0) {
    Write-Host "  VERIFIED" -ForegroundColor Green -NoNewline
    Write-Host "  $($verifiedMods.Count) mod$(if($verifiedMods.Count -ne 1){'s'})" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $verifiedMods) {
        Write-Host "    + " -ForegroundColor Green -NoNewline
        Write-Host "$($mod.ModName)" -ForegroundColor White -NoNewline
        Write-Host "  $($mod.FileName)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($unknownMods.Count -gt 0) {
    Write-Host "  UNKNOWN" -ForegroundColor Yellow -NoNewline
    Write-Host "  $($unknownMods.Count) mod$(if($unknownMods.Count -ne 1){'s'})" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $unknownMods) {
        $src = if ($mod.DownloadSource) { $mod.DownloadSource } else { "unknown source" }
        Write-Host "    ? " -ForegroundColor Yellow -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor White -NoNewline
        Write-Host "  via $src" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($suspiciousMods.Count -gt 0) {
    Write-Host "  SUSPICIOUS" -ForegroundColor Red -NoNewline
    Write-Host "  $($suspiciousMods.Count) mod$(if($suspiciousMods.Count -ne 1){'s'})" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $suspiciousMods) {
        Write-Host "    ! " -ForegroundColor Red -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor White
        Write-Host ""

        if ($mod.Patterns.Count -gt 0) {
            Write-Host "      patterns" -ForegroundColor DarkGray
            foreach ($p in ($mod.Patterns | Sort-Object)) {
                Write-Host "        $p" -ForegroundColor DarkRed
            }
            Write-Host ""
        }

        $uniqueStrings = $mod.Strings | Where-Object { $mod.Patterns -notcontains $_ } | Sort-Object
        if ($uniqueStrings.Count -gt 0) {
            Write-Host "      strings" -ForegroundColor DarkGray
            foreach ($s in $uniqueStrings) {
                Write-Host "        $s" -ForegroundColor DarkYellow
            }
            Write-Host ""
        }

        Write-Host ("    " + ("·" * 68)) -ForegroundColor DarkGray
        Write-Host ""
    }
}

if ($bypassMods.Count -gt 0) {
    Write-Host "  INJECTION" -ForegroundColor Magenta -NoNewline
    Write-Host "  $($bypassMods.Count) mod$(if($bypassMods.Count -ne 1){'s'})" -ForegroundColor DarkGray
    Write-Host ""
    foreach ($mod in $bypassMods) {
        Write-Host "    ! " -ForegroundColor Magenta -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor White
        Write-Host ""
        Write-Host "      flags" -ForegroundColor DarkGray
        foreach ($flag in $mod.Flags) {
            Write-Host "        $flag" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host ("    " + ("·" * 68)) -ForegroundColor DarkGray
        Write-Host ""
    }
}

Write-Host ("  " + ("─" * 74)) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  SUMMARY" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "    scanned     " -ForegroundColor DarkGray -NoNewline; Write-Host "$totalFiles" -ForegroundColor White
Write-Host "    verified    " -ForegroundColor DarkGray -NoNewline; Write-Host "$($verifiedMods.Count)" -ForegroundColor Green
Write-Host "    unknown     " -ForegroundColor DarkGray -NoNewline; Write-Host "$($unknownMods.Count)" -ForegroundColor Yellow
Write-Host "    suspicious  " -ForegroundColor DarkGray -NoNewline; Write-Host "$($suspiciousMods.Count)" -ForegroundColor Red
Write-Host "    injected    " -ForegroundColor DarkGray -NoNewline; Write-Host "$($bypassMods.Count)" -ForegroundColor Magenta
Write-Host ""
Write-Host ("  " + ("─" * 74)) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Meow Mod Analyzer  by Tonynoh" -ForegroundColor DarkGray
Write-Host "    discord   tonyboy90_" -ForegroundColor DarkGray
Write-Host "    github    https://github.com/MeowTonynoh" -ForegroundColor DarkGray
Write-Host "    youtube   tonynoh-07" -ForegroundColor DarkGray
Write-Host ""
Write-Host ("  " + ("─" * 74)) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  press any key to exit" -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
