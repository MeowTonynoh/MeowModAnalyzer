# Meow Mod Analyzer

CMD script to analyze Minecraft mods and identify potential cheat clients.

## Installation

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1')"
```

## Usage

On startup, the script requests the mods folder path:
- Press **Enter** to use the default path: `%USERPROFILE%\AppData\Roaming\.minecraft\mods`
- Or enter a custom path

---

## How It Works

### Phase 1: Database Verification

The script calculates the **SHA1 hash** of each JAR file and compares it with official databases:

**Modrinth API** `https://api.modrinth.com/v2/version_file/{hash}`
- Main database of verified mods
- Returns project name and slug if found

**Megabase API** `https://megabase.vercel.app/api/query?hash={hash}`
- Alternative database for known mods
- Backup in case Modrinth doesn't find matches

Found mods are classified as **VERIFIED**.

---

### Phase 2: Pattern & String Analysis

For all mods, the script:
1. Extracts JAR file contents using `System.IO.Compression.ZipFile`
2. Analyzes internal file names and paths via regex
3. Reads content of `.class`, `.json`, and `MANIFEST.MF` files
4. Searches for suspicious **patterns** (class/file names) and **strings** (hardcoded cheat-related text)
5. Detects **fullwidth Unicode strings** (e.g. `Ａｕｔｏ Ｃｒｙｓｔａｌ`) used to hide cheat labels
6. Also scans **nested JARs** embedded in `META-INF/jars/`

---

### Phase 3: Bypass & Injection Scan

Performs structural analysis on all mods to detect dangerous or deceptive behaviors:

- **Suspicious nested JARs** — unknown dependencies bundled without version info
- **Hollow shell mods** — minimal outer classes wrapping a single inner JAR
- **Runtime.exec()** — code capable of executing arbitrary OS commands (flagged when combined with obfuscation)
- **HTTP file download** — fetches and writes remote files to disk at runtime
- **HTTP POST exfiltration** — sends system data (e.g. properties) to an external server
- **Heavy obfuscation** — high percentage of `a/b/c`-style single-letter class path segments
- **Numeric/Unicode class names** — statistically abnormal class naming
- **Fake mod identity** — claims to be a known safe mod (e.g. `lithium`, `sodium`) but contains dangerous code

---

### Phase 4: Obfuscation Analysis

Deep-scans class naming conventions and content to identify obfuscated mods:

| Flag | Description |
|---|---|
| Numeric class names | e.g. `1234.class` — typical of automated obfuscators |
| Unicode class names | Non-ASCII characters in class names |
| Fullwidth Unicode | `ａｂｃ` / `ＡＢＣ` / `０１２` style naming |
| Japanese obfuscation | Hiragana/Katakana class names (e.g. `じ.class`, `ふ.class`) |
| Single/two-letter names | Very short class names (`A.class`, `ab.class`) in high percentages |
| Gibberish names | Consonant clusters with no vowels |
| Confusion-char names | Names made of `I`, `l`, `1`, `O`, `0`, `_` |
| Single-char package paths | Deeply nested paths like `a/b/c/d/` |
| Known cheat obfuscators | Detected signatures for: **Skidfuscator**, **Paramorphism**, **Radon**, **Caesium**, **Bozar**, **Branchlock**, **Binscure**, **SuperBlaubeere27**, **Qprotect**, **Zelix**, **Stringer**, **JNIC**, **Scuti**, **Smoke** |

---

### Phase 5: JVM / Runtime Injection Scan

If Minecraft is currently running, the script inspects the live **Java process** for:

- **`-javaagent:`** flags — external agents attached to the JVM (non-standard ones flagged)
- **`-Xbootclasspath/p:`** — prepends to bootstrap classpath, can override core Java classes
- **`-Xbootclasspath/a:`** — appends below the classloader, used for deep injection
- **`-agentlib:jdwp`** — JDWP debug agent, enables remote debugging/control
- **`-agentpath:`** — native agent loaded, bypasses Java sandbox entirely

---

### Download Source Tracking

The script reads Windows' **`Zone.Identifier`** Alternate Data Stream to identify where each mod was downloaded from.

**Recognized sources:**

| Source | Classification |
|---|---|
| Modrinth | ✅ Safe |
| CurseForge | ✅ Safe |
| GitHub | ⚠️ Verify |
| Discord / Discord CDN | ⚠️ Risky |
| MediaFire | ⚠️ Risky |
| MEGA | ⚠️ Risky |
| Dropbox | ⚠️ Risky |
| Google Drive | ⚠️ Risky |
| AnyDesk | 🚨 Suspicious |
| DoomsdayClient | 🚨 Suspicious |
| PrestigeClient | 🚨 Suspicious |
| 198Macros | 🚨 Suspicious |
| Dqrkis | 🚨 Suspicious |

---

## Detected Cheat Patterns

The script contains **200+ patterns and strings** associated with cheat clients.

**Combat:**
`AimAssist`, `AutoCrystal`, `AutoHitCrystal`, `CrystalAura`, `TriggerBot`, `SilentAim`, `Criticals`, `Reach`, `ReachHack`, `ShieldBreaker`, `ShieldDisabler`, `AxeSpam`, `KillAura`, `BowAimbot`, `AutoCrit`

**Crystal / Anchor / Bed:**
`AutoAnchor`, `AnchorTweaks`, `DoubleAnchor`, `SafeAnchor`, `AirAnchor`, `AutoBed`, `BedAura`, `NoBounce`, `LWFH Crystal`, `WalksyCrystalOptimizerMod`

**Totem / Survival:**
`AutoTotem`, `HoverTotem`, `InventoryTotem`, `LegitTotem`, `AutoPot`, `AutoArmor`, `AutoDoubleHand`, `PopSwitch`, `MaceSwap`, `StunSlam`

**Movement:**
`FlyHack`, `SpeedHack`, `BHop`, `AntiFall`, `NoKnockback`, `AntiKB`, `StepHack`, `WaterWalk`, `NoSlow`, `JumpReset`, `SprintReset`, `NoJumpDelay`, `ElytraSpeed`

**PvP Utility:**
`FakeLag`, `PingSpoof`, `FakeInv`, `WTap`, `FakeNick`, `PackSpoof`, `Antiknockback`, `AutoGap`, `AutoPearl`, `AutoTPA`

**Visual / ESP:**
`BlockESP`, `PlayerESP`, `XRayHack`, `Tracers`, `Freecam`, `FakeItem`, `NewChunks`

**Automation:**
`FastPlace`, `ChestSteal`, `AutoClicker`, `AutoEat`, `AutoMine`, `AutoFirework`, `ElytraSwap`, `FastXP`, `AutoBridge`, `AutoBreach`

**Anti-Cheat Bypass:**
`GrimBypass`, `VulcanBypass`, `MatrixBypass`, `AACBypass`, `VerusDisabler`, `WatchdogBypass`, `PacketMine`, `PacketFly`

**Malware / RAT indicators:**
`SessionStealer`, `TokenLogger`, `TokenGrabber`, `KeyLogger`, `RemoteAccess`, `ReverseShell`, `Backdoor`

**Known clients:**
`Asteria`, `Prestige`, `Xenon`, `Argon`, `Hellion`, `Virgin`, `Donut`, `VapeClient`, `MeteorClient`, `LiquidBounce`, `RusherHack`, `FutureClient`, `Aristois`, `Pandaware`, `AstolfoClient`, `Novoclient`, `IntentClient`

**Obfuscated / hidden patterns:**
- Package `org.chainlibs.module.impl.modules.*`
- Classes with Japanese characters (`じ.class`, `ふ.class`, `ぶ.class`, etc.)
- Fullwidth Unicode strings (e.g. `Ａｕｔｏ Ｃｒｙｓｔａｌ`, `ＡｕｔｏＴｏｔｅｍ`)
- Suspicious mixins: `LicenseCheckMixin`, `ClientPlayerInteractionManagerAccessor`
- Files: `phantom-refmap.json`, `client-refmap.json`, `cheat-refmap.json`
- Libraries: `jnativehook`, `imgui.binding`, `imgui.gl3`, `imgui.glfw`

---

## Output Categories

### ✅ VERIFIED MODS
Mods matched in Modrinth or Megabase by SHA1 hash. Considered safe.

### ❓ UNKNOWN MODS
Not found in any database, but no suspicious content detected. Download source shown when available.

### 🚨 SUSPICIOUS MODS
Contain one or more cheat-related patterns or strings. All matches are listed per mod, grouped by:
- **PATTERNS** — suspicious file/class names
- **STRINGS** — hardcoded cheat text found in bytecode
- **FULLWIDTH UNICODE** — hidden fullwidth labels (resolved to their cheat meaning)

### 🟣 BYPASS / INJECTION DETECTED
Structural anomalies suggesting the mod injects code, downloads payloads, or exfiltrates data.

### 🟡 OBFUSCATED MODS
Not explicitly suspicious by content, but heavily obfuscated — statistically unusual naming, known obfuscator signatures, or single-letter path structures.

### ⚡ JVM / RUNTIME INJECTION
Active issues found in the running Java process: external agents, dangerous JVM flags, or debug hooks.

---

## Runtime Info

If Minecraft is running when the script starts, it displays:
- Process name (`java` / `javaw`) and PID
- Startup timestamp
- Current uptime

---

## Contacts

Discord: `tonyboy90_`
GitHub: [MeowTonynoh](https://github.com/MeowTonynoh)
YouTube: `tonynoh-07`
