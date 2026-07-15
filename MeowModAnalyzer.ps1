[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
Clear-Host

$currentFont = (Get-ItemProperty "HKCU:\Console" -ErrorAction SilentlyContinue).FaceName
if ($currentFont -notmatch "NSimSun|Gothic|Noto") {
    Write-Host "  Tip: To see all Unicode characters, set the terminal font to 'NSimSun'" -ForegroundColor DarkYellow
    Write-Host
}

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
Write-Host "                Made with " -ForegroundColor Gray -NoNewline
Write-Host "♥ " -ForegroundColor Red -NoNewline
Write-Host "by " -ForegroundColor Gray -NoNewline
Write-Host "MeowTonynoh" -ForegroundColor Cyan
Write-Host ""
Write-Host ("━" * 76) -ForegroundColor DarkCyan
Write-Host

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

Write-Host "📁 Scanning directory: $modsPath" -ForegroundColor Green
Write-Host

$mcProcess = Get-Process javaw -ErrorAction SilentlyContinue
if (-not $mcProcess) {
    $mcProcess = Get-Process java -ErrorAction SilentlyContinue
}

if ($mcProcess) {
    try {
        $startTime = $mcProcess.StartTime
        $uptime = (Get-Date) - $startTime
        Write-Host "🕒 { Minecraft Uptime }" -ForegroundColor DarkCyan
        Write-Host "   $($mcProcess.Name) PID $($mcProcess.Id) started at $startTime" -ForegroundColor Gray
        Write-Host "   Running for: $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s" -ForegroundColor Gray
        Write-Host ""
    } catch { }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$suspiciousPatterns = @(
    "AimAssist", "AnchorTweaks", "AutoAnchor", "AutoCrystal", "AutoDoubleHand", "JDWP.VirtualMachine.AllModules",
    "AutoHitCrystal", "AutoPot", "AutoTotem", "AutoArmor", "InventoryTotem",
    "LegitTotem", "PingSpoof", "SelfDestruct",
    "ShieldBreaker", "TriggerBot", "AxeSpam", "WebMacro",
    "FastPlace", "WalskyOptimizer", "WalksyOptimizer", "walsky.optimizer",
    "WalksyCrystalOptimizerMod", "Donut", "Replace Mod",
    "ShieldDisabler", "SilentAim", "Totem Hit", "Wtap", "FakeLag",
    "BlockESP", "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",  "AntiMissClick",
    "LagReach", "PopSwitch", "SprintReset", "ChestSteal", "AntiBot",
    "ElytraSwap", "FastXP", "FastExp", "Refill",  "AirAnchor",
    "jnativehook", "FakeInv", "HoverTotem", "AutoClicker", "AutoFirework",
    "PackSpoof", "Antiknockback", "catlean", 
    "AuthBypass", "Asteria", "Prestige", "AutoEat", "AutoMine",
    "MaceSwap",  "Macro198", "StunSlam", "SafeAnchor", "DoubleAnchor", "AutoTPA", "BaseFinder", "Xenon", "gypsy",
    "AutoPotRefill", "WalksyOptimizer", "KeyPearl", "AimAssist", "AutoNethPot", "AutoDtap",
    "TriggerBot", "AutoWeb", "AnchorAction",

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
    "imgui.gl3", "imgui.glfw",
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
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "JDWP.VirtualMachine.AllModules",
    "dontPlaceCrystal", "dontBreakCrystal",
    "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer", "healPotSlot",
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ",
    "ＡｕｔｏＨｉｔＣｒｙｓｔａｌ",
    "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor",
     "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor",
    "SafeAnchor", "AirAnchor",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ", "Ｄｏｕｂｌｅ Ａｎｃｈｏｒ",
    "ＳａｆｅＡｎｃｈｏｒ", "Ｓａｆｅ Ａｎｃｈｏｒ",
    "Ａｎｃｈｏｒ Ｍａｃｒｏ", "anchorMacro",
    "AutoTotem", "autototem", "auto totem", "InventoryTotem",
    "inventorytotem", "HoverTotem", "hover totem", "legittotem",
    "ＡｕｔｏＴｏｔｅｍ", "Ａｕｔｏ Ｔｏｔｅｍ",
    "ＨｏｖｅｒＴｏｔｅｍ", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "ＩｎｖｅｎｔｏｒｙＴｏｔｅｍ", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Ａｕｔｏ Ｔｏｔｅｍ Ｈｉｔ",
    "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor",
    "ＡｕｔｏＰｏｔ", "Ａｕｔｏ Ｐｏｔ",
    "Ａｕｔｏ Ｐｏｔ Ｒｅｆｉｌｌ", "AutoPotRefill",
    "ＡｕｔｏＡｒｍｏｒ", "Ａｕｔｏ Ａｒｍｏｒ",
    "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "ShieldDisabler", "ShieldBreaker",
    "ＳｈｉｅｌｄＤｉｓａｂｌｅｒ", "Ｓｈｉｅｌｄ Ｄｉｓａｂｌｅｒ",
    "Breaking shield with axe...",
    "AutoDoubleHand", "autodoublehand", "auto double hand",
    "ＡｕｔｏＤｏｕｂｌｅＨａｎｄ", "Ａｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ",
    "AutoClicker",
    "ＡｕｔｏＣｌｉｃｋｅｒ",
    "Failed to switch to mace after axe!",
    "AutoMace", "MaceSwap", "SpearSwap",
    "ＡｕｔｏＭａｃｅ", "Ａｕｔｏ Ｍａｃｅ",
    "ＭａｃｅＳｗａｐ", "Ｍａｃｅ Ｓｗａｐ",
    "Ｓｐｅａｒ Ｓｗａｐ", "Ａｕｔｏｍａｔｉｃａｌｌｙ ａｘｅ ａｎｄ ｍａｃｅ ｓｈｉｅｌｄｅｄ ｐｌａｙｅｒｓ",
    "Ｓｔｕｎ Ｓｌａｍ", "StunSlam",
    "Donut", "JumpReset", "axespam", "axe spam",

    "findKnockbackSword", "attackRegisteredThisClick",
    "AimAssist", "aimassist", "aim assist",
    "triggerbot", "trigger bot",
    "ＡｉｍＡｓｓｉｓｔ", "Ａｉｍ Ａｓｓｉｓｔ",
    "ＴｒｉｇｇｅｒＢｏｔ", "Ｔｒｉｇｇｅｒ Ｂｏｔ",
    "Silent Rotations", "SilentRotations",
    "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "FakeInv", "swapBackToOriginalSlot",
    "FakeLag", "pingspoof", "ping spoof",
    "ＦａｋｅＬａｇ", "Ｆａｋｅ Ｌａｇ",
    "fakePunch", "Fake Punch",
    "Ｆａｋｅ Ｐｕｎｃｈ",
    "mace_swap", "quick_strike", "macro_198", "stun_slam",
    "safe_anchor", "double_anchor", "auto_pot_refill",
    "walksy_optimizer", "key_pearl", "aim_assist",
    "auto_neth_pot", "auto_dtap", "trigger_bot", "auto_web",
    "DOUBLE_ESCAPE", "DOUBLE_RIGHTCLICK_FIRST", "DOUBLE_RIGHTCLICK_SECOND",
    "POST_CYCLE_DELAY", "PLACE_OBI", "WAIT_OBI", "PLACE_CRYSTAL", "BREAK_CRYSTAL",
    "ROTATING_DOWN", "ROTATING_BACK", "REFILLING", "PLANTING", "BONEMEALING",
    "AnchorAction", "Places two anchors for massive damage",
    "REOFFHAND_TOTEM",
    "webmacro", "web macro",
    "AntiWeb", "AutoWeb",
    "Ａｎｔｉ Ｗｅｂ", "ＡｕｔｏＷｅｂ",
    "Ｐｌａｃｅｓ Ｗｅｂｓ Ｏｎ Ｅｎｅｍｉｅｓ",
    "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "WalksyCrystalOptimizerMod", "WalksyOptimizer", "WalskyOptimizer",
    "Ｗａｌｋｓｙ Ｏｐｔｉｍｉｚｅｒ",
    "autoCrystalPlaceClock",
    "AutoFirework", "ElytraSwap", "FastXP", "FastExp", "NoJumpDelay",
    "ＥｌｙｔｒａＳｗａｐ", "Ｅｌｙｔｒａ Ｓｗａｐ",
    "PackSpoof", "Antiknockback", "catlean",
    "AuthBypass", "obfuscatedAuth", "LicenseCheckMixin",
    "BaseFinder", "invsee", "ItemExploit",
    "FreezePlayer",
    "Ｆｒｅｅｃａｍ", "Ｍｏｖｅ ｆｒｅｅｌｙ ｔｈｒｏｕｇｈ ｗａｌｌｓ",
    "Ｎｏ Ｃｌｉｐ", "Ｆｒｅｅｚｅ Ｐｌａｙｅｒ",
    "LWFH Crystal", "JDWP.VirtualMachine.AllModules",
    "ＬＷＦＨ Ｃｒｙｓｔａｌ",
    "KeyPearl", "LootYeeter",
    "ＫｅｙＰｅａｒｌ", "Ｋｅｙ Ｐｅａｒｌ",
    "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "FastPlace",
    "Ｆａｓｔ Ｐｌａｃｅ", "Ｐｌａｃｅ ｂｌｏｃｋｓ ｆａｓｔｅｒ",
    "AutoBreach",
    "Ａｕｔｏ Ｂｒｅａｃｈ",
    "setBlockBreakingCooldown", "getBlockBreakingCooldown", "blockBreakingCooldown",
    "onBlockBreaking", "setItemUseCooldown",
    "invokeDoAttack", "invokeDoItemUse", "invokeOnMouseButton",
    "onPushOutOfBlocks", "onIsGlowing",
    "Automatically switches to sword when hitting with totem",
    "arrayOfString", "POT_CHEATS",
    "Dqrkis Client", "Entity.isGlowing",
    "Activate Key", "Ａｃｔｉｖａｔｅ Ｋｅｙ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "On RMB", "Ｏｎ ＲＭＢ",
    "No Count Glitch", "Ｎｏ Ｃｏｕｎｔ Ｇｌｉｔｃｈ",
    "No Bounce", "NoBounce", "Ｎｏ Ｂｏｕｎｃｅ", "ＮｏＢｏｕｎｃｅ",
    "Ｒｅｍｏｖｅｓ ｔｈｅ ｃｒｙｓｔａｌ ｂｏｕｎｃｅ ａｎｉｍａｔｉｏｎ",
    "Place Delay", "Ｐｌａｃｅ Ｄｅｌａｙ",
    "Break Delay", "Ｂｒｅａｋ Ｄｅｌａｙ",
     "Ｆａｓｔ Ｍｏｄｅ",
    "Place Chance", "Ｐｌａｃｅ Ｃｈａｎｃｅ",
    "Break Chance", "Ｂｒｅａｋ Ｃｈａｎｃｅ",
    "Stop On Kill", "Ｓｔｏｐ Ｏｎ Ｋｉｌｌ",
    "Ｄａｍａｇｅ Ｔｉｃｋ", "damagetick",
    "Anti Weakness", "Ａｎｔｉ Ｗｅａｋｎｅｓｓ",
    "Particle Chance", "Ｐａｒｔｉｃｌｅ Ｃｈａｎｃｅ",
    "Trigger Key", "Ｔｒｉｇｇｅｒ Ｋｅｙ",
    "Switch Delay", "Ｓｗｉｔｃｈ Ｄｅｌａｙ",
    "Totem Slot", "Ｔｏｔｅｍ Ｓｌｏｔ",
    "Silent Rotations", "Ｓｉｌｅｎｔ Ｒｏｔａｔｉｏｎｓ",
    "Smooth Rotations", "Ｓｍｏｏｔｈ Ｒｏｔａｔｉｏｎｓ",
    "Rotation Speed", "Ｒｏｔａｔｉｏｎ Ｓｐｅｅｄ",
    "Use Easing", "Ｕｓｅ Ｅａｓｉｎｇ",
    "Easing Strength", "Ｅａｓｉｎｇ Ｓｔｒｅｎｇｔｈ",
    "While Use", "Ｗｈｉｌｅ Ｕｓｅ",
    "Stop on Kill", "Ｓｔｏｐ ｏｎ Ｋｉｌｌ",
    "Click Simulation", "Ｃｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "Glowstone Delay", "Ｇｌｏｗｓｔｏｎｅ Ｄｅｌａｙ",
    "Glowstone Chance", "Ｇｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ",
    "Explode Delay", "Ｅｘｐｌｏｄｅ Ｄｅｌａｙ",
    "Explode Chance", "Ｅｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Explode Slot", "Ｅｘｐｌｏｄｅ Ｓｌｏｔ",
    "Only Charge", "Ｏｎｌｙ Ｃｈａｒｇｅ",
    "Anchor Macro", "Ａｎｃｈｏｒ Ｍａｃｒｏ",
    "Reach Distance", "Ｒｅａｃｈ Ｄｉｓｔａｎｃｅ",
    "Min Height", "Ｍｉｎ Ｈｅｉｇｈｔ",
    "Min Fall Speed", "Ｍｉｎ Ｆａｌｌ Ｓｐｅｅｄ",
    "Attack Delay", "Ａｔｔａｃｋ Ｄｅｌａｙ",
    "Breach Delay", "Ｂｒｅａｃｈ Ｄｅｌａｙ",
    "Require Elytra", "Ｒｅｑｕｉｒｅ Ｅｌｙｔｒａ",
    "Auto Switch Back", "Ａｕｔｏ Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Check Line of Sight", "Ｃｈｅｃｋ Ｌｉｎｅ ｏｆ Ｓｉｇｈｔ",
    "Only When Falling", "Ｏｎｌｙ Ｗｈｅｎ Ｆａｌｌｉｎｇ",
    "Require Crit", "Ｒｅｑｕｉｒｅ Ｃｒｉｔ",
    "Show Status Display", "Ｓｈｏｗ Ｓｔａｔｕｓ Ｄｉｓｐｌａｙ",
    "Stop On Crystal", "Ｓｔｏｐ Ｏｎ Ｃｒｙｓｔａｌ",
    "Check Shield", "Ｃｈｅｃｋ Ｓｈｉｅｌｄ",
    "On Pop", "Ｏｎ Ｐｏｐ",
    "Predict Damage", "Ｐｒｅｄｉｃｔ Ｄａｍａｇｅ",
    "On Ground", "Ｏｎ Ｇｒｏｕｎｄ",
    "Check Players", "Ｃｈｅｃｋ Ｐｌａｙｅｒｓ",
    "Predict Crystals", "Ｐｒｅｄｉｃｔ Ｃｒｙｓｔａｌｓ",
    "Check Aim", "Ｃｈｅｃｋ Ａｉｍ",
    "Check Items", "Ｃｈｅｃｋ Ｉｔｅｍｓ",
    "Activates Above", "Ａｃｔｉｖａｔｅｓ Ａｂｏｖｅ",
    "Blatant", "Ｂｌａｔａｎｔ",
    "Force Totem", "Ｆｏｒｃｅ Ｔｏｔｅｍ",
    "Stay Open For", "Ｓｔａｙ Ｏｐｅｎ Ｆｏｒ",
    "Auto Inventory Totem", "Ａｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ",
    "Only On Pop", "Ｏｎｌｙ Ｏｎ Ｐｏｐ",
    "Vertical Speed", "Ｖｅｒｔｉｃａｌ Ｓｐｅｅｄ",
    "Hover Totem", "Ｈｏｖｅｒ Ｔｏｔｅｍ",
    "Swap Speed", "Ｓｗａｐ Ｓｐｅｅｄ",
    "Strict One-Tick", "Ｓｔｒｉｃｔ Ｏｎｅ－Ｔｉｃｋ",
    "Mace Priority", "Ｍａｃｅ Ｐｒｉｏｒｉｔｙ",
    "Min Totems", "Ｍｉｎ Ｔｏｔｅｍｓ",
    "Min Pearls", "Ｍｉｎ Ｐｅａｒｌｓ",
    "Totem First", "Ｔｏｔｅｍ Ｆｉｒｓｔ",
    "Drop Interval", "Ｄｒｏｐ Ｉｎｔｅｒｖａｌ",
    "Random Pattern", "Ｒａｎｄｏｍ Ｐａｔｔｅｒｎ",
    "Loot Yeeter", "Ｌｏｏｔ Ｙｅｅｔｅｒ",
    "Horizontal Aim Speed", "Ｈｏｒｉｚｏｎｔａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Vertical Aim Speed", "Ｖｅｒｔｉｃａｌ Ａｉｍ Ｓｐｅｅｄ",
    "Include Head", "Ｉｎｃｌｕｄｅ Ｈｅａｄ",
    "Web Delay", "Ｗｅｂ Ｄｅｌａｙ",
    "Holding Web", "Ｈｏｌｄｉｎｇ Ｗｅｂ",
    "Not When Affects Player", "Ｎｏｔ Ｗｈｅｎ Ａｆｆｅｃｔｓ Ｐｌａｙｅｒ",
    "Hit Delay", "Ｈｉｔ Ｄｅｌａｙ",
    "Ｓｗｉｔｃｈ Ｂａｃｋ",
    "Require Hold Axe", "Ｒｅｑｕｉｒｅ Ｈｏｌｄ Ａｘｅ",
    "Fake Punch", "Ｆａｋｅ Ｐｕｎｃｈ",
    "placeInterval", "breakInterval", "stopOnKill",
    "activateOnRightClick", "holdCrystal",
    "ｐｌａｃｅＩｎｔｅｒｖａｌ", "ｂｒｅａｋＩｎｔｅｒｖａｌ",
    "ｓｔｏｐＯｎＫｉｌｌ", "ａｃｔｉｖａｔｅＯｎＲｉｇｈｔＣｌｉｃｋ",
    "ｄａｍａｇｅｔｉｃｋ", "ｈｏｌｄＣｒｙｓｔａｌ",
    "ｆａｋｅＰｕｎｃｈ",
    "Ｒｅｆｉｌｌｓ ｙｏｕｒ ｈｏｔｂａｒ ｗｉｔｈ ｐｏｔｉｏｎｓ",
    "Ｋｅｐｓ ｙｏｕ ｓｐｒｉｎｔｉｎｇ ａｔ ａｌｌ ｔｉｍｅｓ",
    "Ｐｌａｃｅｓ ａｎｃｈｏｒ， ｃｈａｒｇｅｓ ｉｔ， ｐｒｏｔｅｃｔｓ ｙｏｕ， ａｎｄ ｅｘｐｌｏｄｅｓ",
    "Ａｕｔｏ ｓｗａｐ ｔｏ ｓｐｅａｒ ｏｎ ａｔｔａｃｋ",
    "Macro Key", "Ａｕｔｏ Ｐｏｔ", "Ｍａｃｒｏ Ｋｅｙ",
    "KillAura", "ClickAura", "MultiAura", "ForceField", "LegitAura",
    "AimBot", "AutoAim", "SilentAim", "AimLock", "HeadSnap",
    "CrystalAura",
    "AnchorAura", "AnchorFill", "AnchorPlace",
    "BedAura", "AutoBed", "BedBomb", "BedPlace",
    "BowAimbot", "BowSpam", "AutoBow",
    "AutoCrit", "CritBypass", "AlwaysCrit", "CriticalHit",
    "ReachHack", "ExtendReach", "LongReach", "HitboxExpand",
    "AntiKB", "NoKnockback", "GrimVelocity", "GrimDisabler", "VelocitySpoof", "KBReduce",
    "OffhandTotem", "TotemSwitch",
    "AutoWeapon", "AutoSword", "AutoCity", "Burrow", "SelfTrap",
    "HoleFiller", "AntiSurround", "AntiBurrow",
    "WTap", "TargetStrafe", "AutoGap", "AutoPearl",
    "FlyHack", "CreativeFlight", "BoatFly", "PacketFly", "AirJump",
    "SpeedHack", "BHop", "BunnyHop",
    "AntiFall", "NoFallDamage", "SafeFall",
    "StepHack", "FastClimb", "AutoStep", "HighStep",
    "WaterWalk", "LiquidWalk", "LavaWalk",
    "NoSlow", "NoSlowdown", "NoWeb", "NoSoulSand",
    "WallHack",
    "ElytraSpeed", "InstantElytra",
    "ScaffoldWalk", "FastBridge", "BuildHelper", "AutoBridge",
    "Nuker", "NukerLegit", "InstantBreak",
    "GhostHand", "NoSwing",
    "PlaceAssist", "AirPlace", "AutoPlace", "InstantPlace",
    "PlayerESP", "MobESP", "ItemESP", "StorageESP", "ChestESP",
    "Tracers", "NameTagsHack",
    "XRayHack", "OreFinder", "CaveFinder", "OreESP",
    "NewChunks", "ChunkBorders", "TunnelFinder",
    "TargetHUD", "ReachDisplay",
    "DoubleClicker", "JitterClick", "ButterflyClick", "CPSBoost",
    "ChestStealer", "InvManager", "InvMovebypass",
    "AutoSprint", "AntiAFK", "AutoRespawn",
    "PopSwitch",
    "FakeLatency", "FakePing", "SpoofRotation", "PositionSpoof",
    "GameSpeed", "SpeedTimer",
     "GrimBypass", "VulcanBypass", "MatrixBypass",
    "AACBypass", "VerusDisabler", "IntaveBypass", "WatchdogBypass",
    "PacketMine", "PacketWalk", "PacketSneak", "PacketCancel", "PacketDupe", "PacketSpam",
    "SelfDestruct", "HideClient",
    "SessionStealer", "TokenLogger", "TokenGrabber", "DiscordToken",
    "RemoteAccess", "ReverseShell", "C2Server", "Backdoor", "KeyLogger",
    "StashFinder", "TrailFinder",
    "imgui.binding",
    "JNativeHook", "GlobalScreen", "NativeKeyListener",
    "client-refmap.json", "cheat-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment", "cc/novoline",
    "com/alan/clients", "club/maxstats", "wtf/moonlight",
    "me/zeroeightsix/kami", "net/ccbluex", "today/opai",
    "net/minecraft/injection", "org/chainlibs/module/impl/modules",
    "xyz/greaj", "com/cheatbreaker", "com/moonsworth",
    "doomsdayclient", "DoomsdayClient", "doomsday.jar",
    "novaclient", "api.novaclient.lol",
    "WalksyOptimizer", "LWFH Crystal",
    "vape.gg", "vapeclient", "VapeClient", "VapeLite",
    "intent.store", "IntentClient",
    "rise.today", "riseclient.com",
    "meteor-client", "meteorclient", "meteordevelopment.meteorclient",
    "liquidbounce", "fdp-client", "net.ccbluex",
    "novoware", "novoclient",
    "aristois", "impactclient", "azura",
    "pandaware", "skilled", "moonClient", "astolfo",
    "futureClient", "konas", "rusherhack", "inertia", "exhibition",
    "dev.krypton", "dev/krypton", "skid.krypton", "skid/krypton",
     "VirginClient", "virgin client",
    "catlean", "CatleanClient", "catlean client",
     "ArgonClient", "argon client",
    "Asteria", "AsteriaClient", "asteria client",
    "Prestige", "PrestigeClient", "prestige client", "prestigeclient.vip",
    "gypsy", "GypsyClient", "gypsy client",
    "Xenon", "XenonClient", "xenon client",
     "GrimClient", "grim client",
    "phantom-refmap.json",
     "dqrkis.xyz", "Dqrkis Client",

    "Assists your aim towards targ", "Assists your aim towards targets smoothly",
    "ate Key", "ation",
    "Auto Anchor", "Auto Inventory", "Auto Jump Reset", "Auto Mace", "Auto Switch",
    "AutoAnchor", "AutoCrystal", "AutoMace",
    "Automatically hit-crystals for", "Autototem", "AutoTotem",
    "B.ackg", "B.latant", "B.latant Mode", "B.o", "B.r", "B.reach", "B.reak Chance",
    "E.xplode Delay", "E.xplode Slot"
)

$patternRegex = [regex]::new(
    '(?<![A-Za-z])(' + ($suspiciousPatterns -join '|') + ')(?![A-Za-z])',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$cheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $cheatStrings) { [void]$cheatStringSet.Add($s) }

$fullwidthRegex = [regex]::new(
    "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}",
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$mavenPrefixes = @(
    "com_","org_","net_","io_","dev_","gs_","xyz_",
    "app_","me_","tv_","uk_","be_","fr_","de_"
)

$cheatObfuscators = @{
    "Skidfuscator"   = @("dev/skidfuscator", "Skidfuscator", "skidfuscator.dev")
    "Paramorphism"   = @("Paramorphism", "paramorphism-", "dev/paramorphism")
    "Radon"          = @("ItzSomebody/Radon", "me/itzsomebody/radon", "Radon Obfuscator")
    "Caesium"        = @("sim0n/Caesium", "Caesium Obfuscator", "dev/sim0n/caesium")
    "Bozar"          = @("vimasig/Bozar", "Bozar Obfuscator", "com/bozar")
    "Branchlock"     = @("Branchlock", "branchlock.dev")
    "Binscure"       = @("Binscure", "com/binscure")
    "SuperBlaubeere" = @("superblaubeere", "superblaubeere27")
    "Qprotect"       = @("Qprotect", "QProtect", "mdma.dev/qprotect")
    "Zelix"          = @("ZKMFLOW", "ZKM", "ZelixKlassMaster", "com/zelix")
    "Stringer"       = @("StringerJavaObfuscator", "com/licel/stringer")
    "JNIC"           = @("JNIC", "jnic.obf", "jnic-obfuscator")
    "Scuti"          = @("ScutiObf", "scuti.obf")
    "Smoke"          = @("SmokeObf", "smoke.obf")
}

$knownLegitModIds = @(
    "vmp-fabric","vmp","lithium","sodium","iris","fabric-api",
    "modmenu","ferrite-core","lazydfu","starlight","entityculling",
    "memoryleakfix","krypton","c2me-fabric","smoothboot-fabric",
    "immediatelyfast","noisium","threadtweak"
)

$legitJvmAgents  = @("jmxremote","yjp","jrebel","newrelic","jacoco","theseus")
$jvmInfoPrefixes = @("-Xmx","-Xms","-javaagent","-Dfabric.addMods","-Dloader.addMods")
$jvmSuspiciousFlagDefs = @(
    @{ Flag = "-Xbootclasspath/p:"; Desc = "prepends to bootstrap classpath, overrides core Java classes" },
    @{ Flag = "-Xbootclasspath/a:"; Desc = "appends to bootstrap classpath, injects below classloader" },
    @{ Flag = "-agentlib:jdwp";     Desc = "JDWP debug agent, remote debugging enabled" },
    @{ Flag = "-agentpath:";         Desc = "native agent loaded, bypasses Java sandbox" }
)

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

function Test-SuspiciousJarName {
    param([string]$JarName)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($JarName)
    if ($base -match '\d')                                          { return $false }
    foreach ($pfx in $script:mavenPrefixes) {
        if ($base.ToLower().StartsWith($pfx))                       { return $false }
    }
    if ($base.Length -gt 20)                                        { return $false }
    return $true
}

function Get-JarHandle {
    param([string]$FilePath)

    $handle = [PSCustomObject]@{
        OuterArchive     = $null
        InnerArchives    = [System.Collections.Generic.List[object]]::new()
        OuterEntries     = @()
        AllEntries       = [System.Collections.Generic.List[object]]::new()
        NestedJarEntries = @()
        Opened           = $false
    }

    try {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $handle.OuterArchive = $archive
        $handle.OuterEntries = @($archive.Entries)
        foreach ($e in $archive.Entries) { $handle.AllEntries.Add($e) }

        $nestedJars = @($archive.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })
        $handle.NestedJarEntries = $nestedJars

        foreach ($nj in $nestedJars) {
            try {
                $ns = $nj.Open()
                $ms = New-Object System.IO.MemoryStream
                $ns.CopyTo($ms); $ns.Close()
                $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $handle.InnerArchives.Add($iz)
                foreach ($ie in $iz.Entries) { $handle.AllEntries.Add($ie) }
            } catch { }
        }

        $handle.Opened = $true
    } catch { }

    return $handle
}

function Close-JarHandle {
    param($Handle)
    foreach ($ia in $Handle.InnerArchives) { try { $ia.Dispose() } catch { } }
    if ($Handle.OuterArchive) { try { $Handle.OuterArchive.Dispose() } catch { } }
}

function Invoke-CombinedScan {
    param($Handle)

    $foundPatterns  = [System.Collections.Generic.HashSet[string]]::new()
    $foundStrings   = [System.Collections.Generic.HashSet[string]]::new()
    $foundFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    $bypassFlags    = [System.Collections.Generic.List[string]]::new()
    $obfFlags       = [System.Collections.Generic.List[string]]::new()

    if (-not $Handle.Opened) {
        return @{ Patterns=$foundPatterns; Strings=$foundStrings; Fullwidth=$foundFullwidth; BypassFlags=$bypassFlags; ObfFlags=$obfFlags }
    }

    foreach ($entry in $Handle.OuterEntries) {
        foreach ($m in $patternRegex.Matches($entry.FullName)) { [void]$foundPatterns.Add($m.Value) }
    }

    $outerClasses = @($Handle.OuterEntries | Where-Object { $_.FullName -match "\.class$" })
    $suspiciousNestedJars = @()
    foreach ($nj in $Handle.NestedJarEntries) {
        $njBase = [System.IO.Path]::GetFileName($nj.FullName)
        if (Test-SuspiciousJarName -JarName $njBase) { $suspiciousNestedJars += $njBase }
    }
    foreach ($sj in $suspiciousNestedJars) {
        $bypassFlags.Add("Suspicious nested JAR — no version, unknown dependency: $sj")
    }
    if ($Handle.NestedJarEntries.Count -eq 1 -and $outerClasses.Count -lt 3) {
        $njName = [System.IO.Path]::GetFileName(($Handle.NestedJarEntries | Select-Object -First 1).FullName)
        $bypassFlags.Add("Hollow shell — only $($outerClasses.Count) own class(es), wraps: $njName")
    }

    $outerModId = ""
    $fmje = $Handle.OuterEntries | Where-Object { $_.FullName -eq "fabric.mod.json" } | Select-Object -First 1
    if ($fmje) {
        try {
            $s = $fmje.Open()
            $r = New-Object System.IO.StreamReader($s)
            $t = $r.ReadToEnd(); $r.Close(); $s.Close()
            if ($t -match '"id"\s*:\s*"([^"]+)"') { $outerModId = $matches[1] }
        } catch { }
    }

    $totalClass         = 0
    $numericCount        = 0
    $unicodeCount        = 0
    $fullwidthCount      = 0
    $japaneseCount       = 0
    $singleLetterCount   = 0
    $twoLetterCount      = 0
    $gibberishCount      = 0
    $noVowelCount        = 0
    $confusionCount      = 0
    $singleCharPkg       = 0
    $contentSample       = [System.Text.StringBuilder]::new()
    $sampleSize          = 0

    $bypassObfuscatedCount = 0
    $numericClassCount     = 0
    $unicodeClassCount     = 0
    $totalClassCount       = 0
    $runtimeExecFound      = $false
    $httpDownloadFound     = $false
    $httpExfilFound        = $false

    foreach ($entry in $Handle.AllEntries) {
        $name = $entry.FullName
        $isClass = $name -match "\.class$"

        if ($isClass) {
            $totalClass++
            $totalClassCount++
            $className = [System.IO.Path]::GetFileNameWithoutExtension(($name -split "/")[-1])

            if ($className -match "^\d+$")                          { $numericCount++; $numericClassCount++ }
            if ($className -match "[^\x00-\x7F]")                   { $unicodeCount++; $unicodeClassCount++ }
            if ($className -match "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]") { $fullwidthCount++ }
            if ($className -match "[\u3040-\u309F\u30A0-\u30FF]")  { $japaneseCount++ }
            if ($className -match "^[a-zA-Z]$")                     { $singleLetterCount++ }
            if ($className -match "^[a-zA-Z]{2}$")                  { $twoLetterCount++ }
            if ($className -match "^[Il1O0]+$" -or $className -match "^[_]+$") { $confusionCount++ }

            if ($className.Length -ge 3 -and $className.Length -le 8 -and $className -match "^[a-zA-Z]+$") {
                $vowels = ($className.ToCharArray() | Where-Object { $_ -match "[aeiouAEIOU]" }).Count
                if ($vowels -eq 0) { $noVowelCount++ }
                $hasCluster = $className -match "[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{3,}"
                if ($hasCluster -and ($vowels / $className.Length) -lt 0.3) { $gibberishCount++ }
            }

            $segs = ($name -replace "\.class$", "") -split "/"
            foreach ($seg in $segs[0..($segs.Count - 2)]) {
                if ($seg.Length -eq 1) { $singleCharPkg++ }
            }

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
            if ($maxConsecutive -ge 3) { $bypassObfuscatedCount++ }
        }

        if ($isClass -or $name -match '\.(json)$' -or $name -match 'MANIFEST\.MF') {
            try {
                $st = $entry.Open()
                $ms2 = New-Object System.IO.MemoryStream
                $st.CopyTo($ms2); $st.Close()
                $bytes = $ms2.ToArray(); $ms2.Dispose()

                $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
                $utf8  = [System.Text.Encoding]::UTF8.GetString($bytes)

                foreach ($m in $patternRegex.Matches($ascii)) { [void]$foundPatterns.Add($m.Value) }
                foreach ($s in $cheatStringSet) {
                    if ($ascii.Contains($s)) { [void]$foundStrings.Add($s); continue }
                    if ($utf8.Contains($s))  { [void]$foundStrings.Add($s) }
                }
                foreach ($m in $fullwidthRegex.Matches($utf8)) { [void]$foundFullwidth.Add($m.Value) }

                if ($isClass) {
                    if ($ascii -match "java/lang/Runtime" -and $ascii -match "getRuntime" -and $ascii -match "exec") {
                        $runtimeExecFound = $true
                    }
                    if ($ascii -match "openConnection" -and $ascii -match "HttpURLConnection" -and $ascii -match "FileOutputStream") {
                        $httpDownloadFound = $true
                    }
                    if ($ascii -match "openConnection" -and $ascii -match "setDoOutput" -and $ascii -match "getOutputStream" -and $ascii -match "getProperty") {
                        $httpExfilFound = $true
                    }

                    if ($sampleSize -lt 150000 -and $entry.Length -lt 100000 -and $entry.Length -gt 100) {
                        [void]$contentSample.Append($ascii)
                        $sampleSize += $ascii.Length
                    }
                }
            } catch { }
        }
    }

    $fwCheatPool = @($script:cheatStrings | Where-Object {
        $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]"
    })
    $resolvedFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in @($foundFullwidth)) {
        if ($fw.Length -lt 3) { continue }
        $bestMatch = $null
        foreach ($cs in $fwCheatPool) {
            if ($cs.Contains($fw)) {
                if ($null -eq $bestMatch -or $cs.Length -lt $bestMatch.Length) { $bestMatch = $cs }
            }
        }
        if ($null -ne $bestMatch) {
            [void]$resolvedFullwidth.Add($bestMatch)
        } elseif ($fw.Length -ge 6) {
            [void]$resolvedFullwidth.Add($fw)
        }
    }
    $resolved = @($resolvedFullwidth)
    $finalFullwidth = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $resolved) {
        $isRedundant = $false
        foreach ($other in $resolved) {
            if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $isRedundant = $true; break }
        }
        if (-not $isRedundant) { [void]$finalFullwidth.Add($fw) }
    }

    if ($totalClass -ge 5) {
        $pct = { param($n) [math]::Round(($n / $totalClass) * 100) }

        $numPct   = & $pct $numericCount
        $uniPct   = & $pct $unicodeCount
        $fwPct    = & $pct $fullwidthCount
        $jpPct    = & $pct $japaneseCount
        $s1Pct    = & $pct $singleLetterCount
        $s2Pct    = & $pct $twoLetterCount
        $gibPct   = & $pct $gibberishCount
        $novPct   = & $pct $noVowelCount
        $confPct  = & $pct $confusionCount

        if ($numPct   -ge 20) { $obfFlags.Add("Numeric class names — $numPct% of classes have numeric-only names") }
        if ($uniPct   -ge 10) { $obfFlags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters") }
        if ($fwPct    -gt  0) { $obfFlags.Add("Fullwidth Unicode class names — $fwPct% use ａｂｃ/ＡＢＣ/０１２ chars ($fullwidthCount classes)") }
        if ($jpPct    -gt  0) { $obfFlags.Add("Japanese obfuscation — $jpPct% use hiragana/katakana class names ($japaneseCount classes)") }
        if ($s1Pct    -ge 15) { $obfFlags.Add("Single-letter class names — $s1Pct% ($singleLetterCount classes)") }
        if ($s2Pct    -ge 20) { $obfFlags.Add("Two-letter class names — $s2Pct% ($twoLetterCount classes)") }
        if ($gibPct   -ge  5) { $obfFlags.Add("Gibberish class names — $gibPct% have no vowels / consonant clusters ($gibberishCount classes)") }
        if ($novPct   -ge  8) { $obfFlags.Add("No-vowel class names — $novPct% ($noVowelCount classes)") }
        if ($confPct  -ge  3) { $obfFlags.Add("Confusion-char names (Il1O0/_) — $confPct% ($confusionCount classes)") }
        if ($singleCharPkg -ge 6) { $obfFlags.Add("Single-char package paths — $singleCharPkg path segments like a/b/c") }

        $sampleStr = $contentSample.ToString()
        $fwStringMatches = [regex]::Matches($sampleStr, "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}")
        if ($fwStringMatches.Count -gt 0) {
            $examples = ($fwStringMatches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
            $obfFlags.Add("Fullwidth strings in class content — $($fwStringMatches.Count) occurrences (e.g. $examples)")
        }

        foreach ($obfName in $cheatObfuscators.Keys) {
            foreach ($pat in $cheatObfuscators[$obfName]) {
                if ($sampleStr.Contains($pat)) {
                    $obfFlags.Add("Known cheat obfuscator detected — $obfName (matched: $pat)")
                    break
                }
            }
        }
    }

    $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($bypassObfuscatedCount / $totalClassCount) * 100) } else { 0 }
    $numPctB = if ($totalClassCount -ge 5)  { [math]::Round(($numericClassCount / $totalClassCount) * 100) } else { 0 }
    $uniPctB = if ($totalClassCount -ge 5)  { [math]::Round(($unicodeClassCount / $totalClassCount) * 100) } else { 0 }

    if ($runtimeExecFound -and $obfPct -ge 25) {
        $bypassFlags.Add("Runtime.exec() in obfuscated code — can run arbitrary OS commands")
    }
    if ($httpDownloadFound) {
        $bypassFlags.Add("HTTP file download — fetches and writes files from a remote server at runtime")
    }
    if ($httpExfilFound) {
        $bypassFlags.Add("HTTP POST exfiltration — sends system data to an external server")
    }
    if ($totalClassCount -ge 10 -and $obfPct -ge 25) {
        $bypassFlags.Add("Heavy obfuscation — $obfPct% of classes use single-letter path segments (a/b/c style)")
    }
    if ($numPctB -ge 20) {
        $bypassFlags.Add("Numeric class names — $numPctB% of classes have numeric-only names (e.g. 1234.class)")
    }
    if ($uniPctB -ge 10) {
        $bypassFlags.Add("Unicode class names — $uniPctB% of classes use non-ASCII characters")
    }

    $dangerCount = ($bypassFlags | Where-Object {
        $_ -match "Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation|Suspicious nested JAR"
    }).Count
    if ($outerModId -and ($knownLegitModIds -contains $outerModId) -and $dangerCount -gt 0) {
        $bypassFlags.Add("Fake mod identity — claims to be '$outerModId' but contains dangerous code")
    }

    return @{
        Patterns    = $foundPatterns
        Strings     = $foundStrings
        Fullwidth   = $finalFullwidth
        BypassFlags = $bypassFlags
        ObfFlags    = $obfFlags
    }
}

function Invoke-JvmScan {
    $results = [System.Collections.Generic.List[object]]::new()

    try {
        $procs = Get-CimInstance Win32_Process -Filter "name = 'javaw.exe' or name = 'java.exe'" -ErrorAction Stop
    } catch {
        return $results
    }

    foreach ($proc in $procs) {
        $cmd = $proc.CommandLine
        if (-not $cmd) { continue }

        $argList  = $cmd -split ' (?=-)'
        $flags    = [System.Collections.Generic.List[string]]::new()
        $infoArgs = [System.Collections.Generic.List[string]]::new()

        foreach ($rawArg in $argList) {
            $argTrim = $rawArg.Trim()
            if ($argTrim -eq "") { continue }

            foreach ($pfx in $jvmInfoPrefixes) {
                if ($argTrim -like "$pfx*") { $infoArgs.Add($argTrim); break }
            }

            if ($argTrim -match '^-javaagent:(.+)$') {
                $agentPath = $matches[1].Trim('"').Trim("'")
                $agentName = [System.IO.Path]::GetFileName($agentPath)
                $isLegit = $false
                foreach ($la in $legitJvmAgents) { if ($agentName -match $la) { $isLegit = $true; break } }
                if (-not $isLegit) {
                    $flags.Add("JVM Agent — -javaagent:$agentName (path: $agentPath)")
                }
            }

            foreach ($sf in $jvmSuspiciousFlagDefs) {
                if ($argTrim -match [regex]::Escape($sf.Flag)) {
                    $flags.Add("Suspicious JVM flag — $($sf.Flag) ($($sf.Desc))")
                }
            }
        }

        $results.Add([PSCustomObject]@{
            ProcessId   = $proc.ProcessId
            ProcessName = $proc.Name
            Flags       = $flags
            InfoArgs    = $infoArgs
        })
    }

    return $results
}

function Write-Rule {
    param([string]$Char = "─", [int]$Width = 76, [ConsoleColor]$Color = "DarkGray")
    Write-Host ($Char * $Width) -ForegroundColor $Color
}

function Write-SectionHeader {
    param(
        [string]$Title,
        [int]$Count,
        [ConsoleColor]$DotColor,
        [ConsoleColor]$CountColor
    )
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "●" -ForegroundColor $DotColor -NoNewline
    Write-Host "  $Title  " -ForegroundColor White -NoNewline
    Write-Host "($Count)" -ForegroundColor $CountColor
    Write-Host ""
}

function Write-SuspiciousCard {
    param($Mod)

    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkRed
    Write-Host "  │ " -ForegroundColor DarkRed -NoNewline
    Write-Host " FLAGGED " -ForegroundColor White -BackgroundColor DarkRed -NoNewline
    Write-Host "  " -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host ("  │ " + ("─" * 66)) -ForegroundColor DarkRed

    if ($Mod.Patterns.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline
        Write-Host "PATTERNS" -ForegroundColor DarkGray
        foreach ($p in ($Mod.Patterns | Sort-Object)) {
            Write-Host "  │    " -ForegroundColor DarkRed -NoNewline
            Write-Host $p -ForegroundColor Red
        }
    }

    $uniqueStrings = $Mod.Strings | Where-Object { $Mod.Patterns -notcontains $_ } | Sort-Object
    if ($uniqueStrings.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline
        Write-Host "STRINGS" -ForegroundColor DarkGray
        foreach ($s in $uniqueStrings) {
            Write-Host "  │    " -ForegroundColor DarkRed -NoNewline
            Write-Host $s -ForegroundColor DarkYellow
        }
    }

    if ($Mod.Fullwidth -and $Mod.Fullwidth.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkRed
        Write-Host "  │  " -ForegroundColor DarkRed -NoNewline
        Write-Host "FULLWIDTH UNICODE" -ForegroundColor DarkGray
        foreach ($fw in ($Mod.Fullwidth | Sort-Object)) {
            Write-Host "  │    " -ForegroundColor DarkRed -NoNewline
            Write-Host "FULLWIDTH: $fw" -ForegroundColor Cyan
        }
    }

    Write-Host "  │" -ForegroundColor DarkRed
    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkRed
    Write-Host ""
}

function Write-InjectionCard {
    param($Mod)

    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkMagenta
    Write-Host "  │ " -ForegroundColor DarkMagenta -NoNewline
    Write-Host " INJECTION " -ForegroundColor White -BackgroundColor DarkMagenta -NoNewline
    Write-Host "  " -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host ("  │ " + ("─" * 66)) -ForegroundColor DarkMagenta

    foreach ($flag in $Mod.Flags) {
        if ($flag -match "^(.+?) — (.+)$") {
            $flagTitle = $matches[1]
            $flagDesc  = $matches[2]
        } else {
            $flagTitle = $flag
            $flagDesc  = ""
        }

        Write-Host "  │" -ForegroundColor DarkMagenta
        Write-Host "  │  " -ForegroundColor DarkMagenta -NoNewline
        Write-Host "◉ " -ForegroundColor Magenta -NoNewline
        Write-Host $flagTitle -ForegroundColor White

        if ($flagDesc -ne "") {
            Write-Host "  │    " -ForegroundColor DarkMagenta -NoNewline
            Write-Host $flagDesc -ForegroundColor Gray
        }
    }

    Write-Host "  │" -ForegroundColor DarkMagenta
    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkMagenta
    Write-Host ""
}

function Write-ObfuscationCard {
    param($Mod)

    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkYellow
    Write-Host "  │ " -ForegroundColor DarkYellow -NoNewline
    Write-Host " OBFUSCATED " -ForegroundColor Black -BackgroundColor DarkYellow -NoNewline
    Write-Host "  " -NoNewline
    Write-Host $Mod.FileName -ForegroundColor Yellow
    Write-Host ("  │ " + ("─" * 66)) -ForegroundColor DarkYellow

    foreach ($flag in $Mod.Flags) {
        if ($flag -match "^(.+?) — (.+)$") {
            $flagTitle = $matches[1]
            $flagDesc  = $matches[2]
        } else {
            $flagTitle = $flag
            $flagDesc  = ""
        }

        Write-Host "  │" -ForegroundColor DarkYellow
        Write-Host "  │  " -ForegroundColor DarkYellow -NoNewline
        Write-Host "⚑ " -ForegroundColor Yellow -NoNewline
        Write-Host $flagTitle -ForegroundColor White

        if ($flagDesc -ne "") {
            Write-Host "  │    " -ForegroundColor DarkYellow -NoNewline
            Write-Host $flagDesc -ForegroundColor Gray
        }
    }

    Write-Host "  │" -ForegroundColor DarkYellow
    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkYellow
    Write-Host ""
}

function Write-JvmProcessCard {
    param($Proc)

    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkYellow
    Write-Host "  │ " -ForegroundColor DarkYellow -NoNewline
    Write-Host " JVM " -ForegroundColor Black -BackgroundColor Yellow -NoNewline
    Write-Host "  $($Proc.ProcessName) (PID $($Proc.ProcessId))" -ForegroundColor Yellow
    Write-Host ("  │ " + ("─" * 66)) -ForegroundColor DarkYellow

    foreach ($flag in $Proc.Flags) {
        $ft = $flag; $fd = ""; $fpath = ""
        if ($flag -match "^(.+?) — (.+) \(path: (.+)\)$") {
            $ft = $matches[1]; $fd = $matches[2]; $fpath = $matches[3]
        } elseif ($flag -match "^(.+?) — (.+)$") {
            $ft = $matches[1]; $fd = $matches[2]
        }
        Write-Host "  │" -ForegroundColor DarkYellow
        Write-Host "  │  " -ForegroundColor DarkYellow -NoNewline
        Write-Host "◉ " -ForegroundColor Yellow -NoNewline
        Write-Host $ft -ForegroundColor White
        if ($fd -ne "") {
            Write-Host "  │    " -ForegroundColor DarkYellow -NoNewline
            Write-Host $fd -ForegroundColor Gray
        }
        if ($fpath -ne "") {
            $display = if ($fpath.Length -gt 60) { "..." + $fpath.Substring($fpath.Length - 57) } else { $fpath }
            Write-Host "  │    " -ForegroundColor DarkYellow -NoNewline
            Write-Host $display -ForegroundColor DarkGray
        }
    }

    if ($Proc.InfoArgs.Count -gt 0) {
        Write-Host "  │" -ForegroundColor DarkYellow
        Write-Host "  │  " -ForegroundColor DarkYellow -NoNewline
        Write-Host "JVM / MOD ARGUMENTS" -ForegroundColor DarkGray
        foreach ($a in $Proc.InfoArgs) {
            Write-Host "  │    " -ForegroundColor DarkYellow -NoNewline
            Write-Host $a -ForegroundColor Gray
        }
    }

    Write-Host "  │" -ForegroundColor DarkYellow
    Write-Host ("  " + ("─" * 70)) -ForegroundColor DarkYellow
    Write-Host ""
}

$verifiedMods    = @()
$unknownMods     = @()
$suspiciousMods  = @()
$bypassMods      = @()
$obfuscatedMods  = @()

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

$fileWord    = if ($jarFiles.Count -eq 1) { "file" } else { "files" }
Write-Host "🔍 Found $($jarFiles.Count) JAR $fileWord to analyze" -ForegroundColor Green
Write-Host

$spinnerFrames = @("⣾","⣽","⣻","⢿","⡿","⣟","⣯","⣷")
$totalFiles    = $jarFiles.Count
$idx           = 0

Write-Host "🔍 Pass 1 — Hash verification (Modrinth + Megabase)..." -ForegroundColor Cyan

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Verifying: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $hash = Get-FileSHA1 -Path $jar.FullName

    if ($hash) {
        $modrinthData = Query-Modrinth -Hash $hash
        if ($modrinthData.Slug) {

            $modrinthWhitelistedSlugs = @("viafabricplus", "viafabricversion")
            $isModrinthWhitelisted = $modrinthWhitelistedSlugs -contains $modrinthData.Slug.ToLower()

            $verifiedMods += [PSCustomObject]@{
                ModName             = $modrinthData.Name
                FileName            = $jar.Name
                FilePath            = $jar.FullName
                ModrinthWhitelisted = $isModrinthWhitelisted
            }
            continue
        }
        $megabaseData = Query-Megabase -Hash $hash
        if ($megabaseData.name) {
            $verifiedMods += [PSCustomObject]@{
                ModName             = $megabaseData.Name
                FileName            = $jar.Name
                FilePath            = $jar.FullName
                ModrinthWhitelisted = $false
            }
            continue
        }
    }

    $src = Get-DownloadSource $jar.FullName
    $unknownMods += [PSCustomObject]@{ FileName = $jar.Name; FilePath = $jar.FullName; DownloadSource = $src }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

$modWord = if ($totalFiles -eq 1) { "mod" } else { "mods" }
Write-Host "🔬 Pass 2 — Deep-scanning all $totalFiles $modWord (patterns, bypass, obfuscation)..." -ForegroundColor Cyan
$idx = 0

foreach ($jar in $jarFiles) {
    $idx++
    $spinner = $spinnerFrames[$idx % $spinnerFrames.Length]
    Write-Host "`r[$spinner] Scanning: $idx/$totalFiles - $($jar.Name)" -ForegroundColor Yellow -NoNewline

    $verifiedEntry = $verifiedMods | Where-Object { $_.FileName -eq $jar.Name } | Select-Object -First 1
    if ($verifiedEntry -and $verifiedEntry.ModrinthWhitelisted -eq $true) {
        continue
    }

    $handle = Get-JarHandle -FilePath $jar.FullName
    $scan   = Invoke-CombinedScan -Handle $handle
    Close-JarHandle -Handle $handle

    $isSuspicious = ($scan.Patterns.Count -gt 0 -or $scan.Strings.Count -gt 0 -or $scan.Fullwidth.Count -gt 0)
    $isBypass     = ($scan.BypassFlags.Count -gt 0)
    $isObf        = ($scan.ObfFlags.Count -gt 0)

    if ($isSuspicious) {
        $suspiciousMods += [PSCustomObject]@{
            FileName  = $jar.Name
            Patterns  = $scan.Patterns
            Strings   = $scan.Strings
            Fullwidth = $scan.Fullwidth
        }
    }

    if ($isBypass) {
        $bypassMods += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $scan.BypassFlags
        }
    }

    if ($isObf -and -not $isSuspicious -and -not $isBypass) {
        $obfuscatedMods += [PSCustomObject]@{
            FileName = $jar.Name
            Flags    = $scan.ObfFlags
        }
    }

    if ($isSuspicious -or $isBypass -or $isObf) {
        $verifiedMods = $verifiedMods | Where-Object { $_.FileName -ne $jar.Name }
    }
    if ($isBypass) {
        $unknownMods = $unknownMods | Where-Object { $_.FileName -ne $jar.Name }
    }
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

$jvmResults = @()
Write-Host "⚡ Pass 3 — Scanning JVM processes for agents and injections..." -ForegroundColor DarkYellow
$jvmResults = Invoke-JvmScan
$jvmFlagTotal = ($jvmResults | ForEach-Object { $_.Flags.Count } | Measure-Object -Sum).Sum
if (-not $jvmFlagTotal) { $jvmFlagTotal = 0 }

if ($jvmResults.Count -eq 0) {
    Write-Host "   ✓  No running Java/Minecraft processes found" -ForegroundColor DarkGray
} elseif ($jvmFlagTotal -gt 0) {
    Write-Host "   ⚠️  JVM issues found!" -ForegroundColor Yellow
} else {
    Write-Host "   ✓  JVM looks clean" -ForegroundColor DarkGray
}

Write-Host "`r$(' ' * 100)`r" -NoNewline

if ($verifiedMods.Count -gt 0) {
    Write-SectionHeader -Title "VERIFIED MODS" -Count $verifiedMods.Count -DotColor Green -CountColor Green
    Write-Rule "─" 76 DarkGray
    foreach ($mod in $verifiedMods) {
        Write-Host "  ✓ " -ForegroundColor Green -NoNewline
        Write-Host "$($mod.ModName)" -ForegroundColor White -NoNewline
        Write-Host " → " -ForegroundColor Gray -NoNewline
        Write-Host "$($mod.FileName)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($unknownMods.Count -gt 0) {
    Write-SectionHeader -Title "UNKNOWN MODS" -Count $unknownMods.Count -DotColor Yellow -CountColor Yellow
    Write-Rule "─" 76 DarkGray
    foreach ($mod in $unknownMods) {
        $name = $mod.FileName
        if ($name.Length -gt 50) { $name = $name.Substring(0,47) + "..." }
        $topLine    = "  ╔═ ? " + $name + " " + ("═" * (65 - $name.Length)) + "╗"
        $sourceText = if ($mod.DownloadSource) { "Source: $($mod.DownloadSource)" } else { "Source: ?" }
        $bottomLine = "  ╚═ " + $sourceText + " " + ("═" * (67 - $sourceText.Length)) + "╝"
        Write-Host $topLine    -ForegroundColor Yellow
        Write-Host $bottomLine -ForegroundColor Yellow
        Write-Host ""
    }
}

if ($suspiciousMods.Count -gt 0) {
    Write-SectionHeader -Title "SUSPICIOUS MODS" -Count $suspiciousMods.Count -DotColor Red -CountColor Red
    Write-Rule "─" 76 DarkGray
    Write-Host ""
    foreach ($mod in $suspiciousMods) {
        Write-SuspiciousCard -Mod $mod
    }
}

if ($bypassMods.Count -gt 0) {
    Write-SectionHeader -Title "BYPASS / INJECTION DETECTED" -Count $bypassMods.Count -DotColor Magenta -CountColor Magenta
    Write-Rule "─" 76 DarkGray
    Write-Host ""
    foreach ($mod in $bypassMods) {
        Write-InjectionCard -Mod $mod
    }
}

if ($obfuscatedMods.Count -gt 0) {
    Write-SectionHeader -Title "OBFUSCATED MODS" -Count $obfuscatedMods.Count -DotColor DarkYellow -CountColor Yellow
    Write-Rule "─" 76 DarkGray
    Write-Host ""
    foreach ($mod in $obfuscatedMods) {
        Write-ObfuscationCard -Mod $mod
    }
}

$relevantJvmProcs = @($jvmResults | Where-Object { $_.Flags.Count -gt 0 -or $_.InfoArgs.Count -gt 0 })
if ($relevantJvmProcs.Count -gt 0) {
    Write-SectionHeader -Title "JVM / RUNTIME INFO" -Count $relevantJvmProcs.Count -DotColor Yellow -CountColor Yellow
    Write-Rule "─" 76 DarkGray
    Write-Host ""
    foreach ($p in $relevantJvmProcs) {
        Write-JvmProcessCard -Proc $p
    }
}

Write-Host "📊 SUMMARY" -ForegroundColor Cyan
Write-Rule "━" 76 Blue
Write-Host "  Total files scanned: " -ForegroundColor Gray -NoNewline; Write-Host "$totalFiles"                   -ForegroundColor White
Write-Host "  Verified mods:       " -ForegroundColor Gray -NoNewline; Write-Host "$($verifiedMods.Count)"        -ForegroundColor Green
Write-Host "  Unknown mods:        " -ForegroundColor Gray -NoNewline; Write-Host "$($unknownMods.Count)"         -ForegroundColor Yellow
Write-Host "  Suspicious mods:     " -ForegroundColor Gray -NoNewline; Write-Host "$($suspiciousMods.Count)"      -ForegroundColor Red
Write-Host "  Bypass/Injected:     " -ForegroundColor Gray -NoNewline; Write-Host "$($bypassMods.Count)"          -ForegroundColor Magenta
Write-Host "  Obfuscated mods:     " -ForegroundColor Gray -NoNewline; Write-Host "$($obfuscatedMods.Count)"      -ForegroundColor Yellow
Write-Host "  JVM processes seen:  " -ForegroundColor Gray -NoNewline; Write-Host "$($jvmResults.Count)"          -ForegroundColor White
Write-Host "  JVM issues:          " -ForegroundColor Gray -NoNewline; Write-Host "$jvmFlagTotal"                 -ForegroundColor Yellow
Write-Host
Write-Rule "━" 76 Blue
Write-Host ""
Write-Host "  ✨ Analysis complete! Thanks for using Meow Mod Analyzer 🐱" -ForegroundColor Cyan
Write-Host ""
Write-Host "  👤 Created by: " -ForegroundColor White -NoNewline
Write-Host "🌟 " -ForegroundColor Cyan -NoNewline
Write-Host "Tonynoh" -ForegroundColor Cyan
Write-Host "  📱 My Socials: " -ForegroundColor White -NoNewline
Write-Host "💬 " -ForegroundColor Blue -NoNewline
Write-Host "Discord  : " -ForegroundColor Blue -NoNewline
Write-Host "tonyboy90_" -ForegroundColor Blue
Write-Host "                 " -NoNewline
Write-Host "🔗 " -ForegroundColor DarkGray -NoNewline
Write-Host "GitHub   : " -ForegroundColor DarkGray -NoNewline
Write-Host "https://github.com/MeowTonynoh" -ForegroundColor DarkGray
Write-Host "                 " -NoNewline
Write-Host "🎥 " -ForegroundColor Red -NoNewline
Write-Host "YouTube  : " -ForegroundColor Red -NoNewline
Write-Host "tonynoh-07" -ForegroundColor Red
Write-Host ""
Write-Rule "━" 76 Blue
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
