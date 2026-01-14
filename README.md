# Meow Mod Analyzer
CMD script to analyze Minecraft mods and identify potential cheat clients.

## Installation
```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')"
```

## Usage
On startup, the script requests the mods folder path:
- Press Enter to use the default path: `%USERPROFILE%\AppData\Roaming\.minecraft\mods`
- Or enter a custom path

## How It Works

### Phase 1: Database Verification
The script calculates the SHA1 hash of each JAR file and compares it with official databases:

**Modrinth API** `https://api.modrinth.com/v2/version_file/{hash}`
- Main database of verified mods
- Returns project name and slug if found

**Megabase API** `https://megabase.vercel.app/api/query?hash={hash}`
- Alternative database for known mods
- Backup in case Modrinth doesn't find matches

Found mods are classified as **VERIFIED**.

### Phase 2: Pattern Analysis
For unverified mods, the script:
1. Extracts JAR file contents using `System.IO.Compression.ZipFile`
2. Analyzes internal file names and paths
3. Reads content of `.class`, `.json`, and `MANIFEST.MF` files
4. Searches for suspicious patterns via regex matching

### Download Source Tracking
The script reads Windows' `Zone.Identifier` stream (Alternate Data Stream) to identify where the mod was downloaded from.

**Recognized safe sites:**
- CurseForge
- Modrinth

**Risky sites:**
- Discord / Discord CDN
- MediaFire
- Github
- MEGA
- Dropbox
- Google Drive
- AnyDesk
- DoomsdayClient
- PrestigeClient
- 198Macros

## Detected Cheat Patterns
The script contains over 100 patterns associated with cheat clients:

**Combat:**
`AimAssist`, `AutoCrystal`, `AutoHitCrystal`, `TriggerBot`, `Velocity`, `Criticals`, `Reach`, `Hitboxes`, `ShieldBreaker`, `ShieldDisabler`, `AxeSpam`

**Movement:**
`Flight`, `Antiknockback`, `NoKnockback`, `JumpReset`, `SprintReset`, `NoJumpDelay`

**PvP Utility:**
`AutoTotem`, `AutoArmor`, `AutoPot`, `AutoDoubleHand`, `InventoryTotem`, `TotemHit`, `PopSwitch`, `LagReach`, `Wtap`, `FakeLag`

**Visual:**
`BlockESP`, `Freecam`, `PackSpoof`, `PingSpoof`, `FakeNick`, `FakeItem`

**Automation:**
`FastPlace`, `ChestSteal`, `Refill`, `AutoEat`, `AutoMine`, `AutoClicker`, `FastXP`

**Known clients:**
`Asteria`, `Prestige`, `Xenon`, `Argon`, `Hellion`, `Grim`, `Virgin`, `Donut`, `Krypton`, `dev.krypton`, `dev.gambleclient`

**Obfuscated patterns:**
- Package `org.chainlibs.module.impl.modules.*`
- Classes with Japanese characters (`じ.class`, `ふ.class`, `ぶ.class`, etc.)
- Suspicious mixins: `KeyboardMixin`, `ClientPlayerInteractionManagerMixin`, `LicenseCheckMixin`
- Files: `phantom-refmap.json`, `xyz.greaj`
- Libraries: `jnativehook`, `imgui`, `imgui.gl3`, `imgui.glfw`

**And more patterns...**

## Output
The script categorizes mods into three groups:

**VERIFIED MODS**
Mods found in official databases, considered safe.

**UNKNOWN MODS**
Mods not present in databases but without suspicious patterns. Shows download source when available.

**SUSPICIOUS MODS**
Mods containing one or more patterns associated with cheats. Lists all detected patterns for each mod.

## Additional Information
If Minecraft is running, the script displays:
- Process name (java/javaw)
- Process PID
- Startup timestamp
- Current uptime

## Contacts
Discord: `tonyboy90_`
GitHub: [MeowTonynoh](https://github.com/MeowTonynoh)
YouTube: tonynoh-07
