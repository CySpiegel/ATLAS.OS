# ATLAS.OS — Developer Workflow & Build Guide

## Project Pattern (mirrors athena)

This project follows the same architecture patterns as the **athena** project. If something looks unfamiliar, check `P:/athena` for reference.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **HEMTT** | 1.18.2+ | Build system — compiles, rapifies, packs PBOs |
| **Arma 3** | 2.16+ | Target platform |
| **CBA_A3** | 3.16+ | Required dependency (events, settings, XEH) |
| **Python 3** + Pillow | Any | Icon generation (`tools/generate_icons.py`) |

### Installing HEMTT

Download from: https://github.com/BrettMayson/HEMTT/releases

Current location on this machine:
```
C:\Users\chimi\Downloads\windows-x64\hemtt.exe
```

Or add to PATH for convenience.

---

## Building

From the project root (`P:/ATLAS.OS`):

```bash
# Development build — fast, no signing
hemtt build

# Development with file patching (for live editing)
hemtt dev

# Release build — signed PBOs
hemtt release
```

### Build Output

HEMTT outputs to `.hemttout/`:
```
.hemttout/
├── build/          # hemtt build output
│   ├── addons/     # .pbo files
│   ├── mod.cpp
│   ├── meta.cpp
│   └── LICENSE
├── dev/            # hemtt dev output (file patching)
└── release/        # hemtt release output (signed)
```

### Symlink to Arma 3

A junction link exists from Arma 3 to the build output:
```
D:\Program Files\Steam\steamapps\common\Arma 3\@ATLAS_OS
  → P:\ATLAS.OS\.hemttout\build
```

To recreate it:
```powershell
New-Item -ItemType Junction -Path "D:\Program Files\Steam\steamapps\common\Arma 3\@ATLAS_OS" -Target "P:\ATLAS.OS\.hemttout\build"
```

After `hemtt build`, the mod is immediately available in Arma 3's launcher under `@ATLAS_OS`.

---

## File Structure Pattern

Every addon follows this exact structure (copied from athena):

```
addons/<addon_name>/
├── $PBOPREFIX$              # Contains: z\atlas\addons\<addon_name>
├── script_component.hpp     # #define COMPONENT <short_name>
├── config.cpp               # CfgPatches + CfgFunctions (inline) + CfgEventHandlers include
├── CfgEventHandlers.hpp     # Extended_PreInit/PostInit_EventHandlers
├── XEH_preInit.sqf          # PREP() calls, GVAR() init, CBA settings, event handlers
├── XEH_postInit.sqf         # Server init, PFH start, client-side keybinds
├── functions/               # SQF function files
│   ├── fnc_init.sqf
│   ├── fnc_someFunction.sqf
│   └── ...
└── ui/
    └── icon.png             # 32x32 module icon (convert to .paa for release)
```

### Macro System

All macros live in `addons/atlas_main/script_macros.hpp`. Other addons include it via:
```cpp
// script_component.hpp
#define COMPONENT opcom
#include "\z\atlas\addons\atlas_main\script_macros.hpp"
```

With `PREFIX = atlas` and `COMPONENT = opcom`, the macros expand to:

| Macro | Expansion | Example |
|-------|-----------|---------|
| `ADDON` | `atlas_opcom` | Addon identifier |
| `FUNC(evaluate)` | `atlas_opcom_fnc_evaluate` | Function reference |
| `GVAR(instances)` | `atlas_opcom_instances` | Global variable |
| `QFUNC(evaluate)` | `"atlas_opcom_fnc_evaluate"` | Quoted function name |
| `QGVAR(instances)` | `"atlas_opcom_instances"` | Quoted variable name |
| `EFUNC(main,log)` | `atlas_main_fnc_log` | External module function |
| `EGVAR(main,profileRegistry)` | `atlas_main_profileRegistry` | External module variable |
| `PREP(evaluate)` | Compiles `fnc_evaluate.sqf` → `atlas_opcom_fnc_evaluate` | Function compilation |
| `LOG("msg")` | `diag_log text format ["[ATLAS/opcom] msg"]` | Logging |

### Key Rules

1. **COMPONENT is the SHORT name** — `main`, `opcom`, `profile` — NOT `atlas_main`
2. **PREP() in XEH_preInit.sqf** — every function must be compiled via PREP() before use
3. **FUNC() for same-module calls** — never use raw function names
4. **EFUNC() for cross-module calls** — `EFUNC(main,registerModule)` not `ATLAS_fnc_registerModule`
5. **GVAR() for all globals** — never use raw `ATLAS_opcom_*` names directly
6. **Functions go in `functions/`** — named `fnc_<name>.sqf` (not `fn_`)
7. **CfgFunctions inline in config.cpp** — no separate `CfgFunctions.hpp`
8. **CBA settings in XEH_preInit.sqf** — use `QGVAR()` for setting variable names

### Adding a New Function

1. Create `addons/<module>/functions/fnc_myFunction.sqf`:
```sqf
#include "..\script_component.hpp"

// atlas_<module>_fnc_myFunction
// Description of what this does
// Parameters: ...
// Returns: ...

params ["_arg1", "_arg2"];

// Use FUNC() for same-module, EFUNC() for cross-module
private _data = [_arg1] call FUNC(otherFunction);
private _registry = EGVAR(main,profileRegistry);
```

2. Add `PREP(myFunction);` to the module's `XEH_preInit.sqf`

3. Rebuild: `hemtt build`

### Adding a New Module

1. Create the directory: `addons/atlas_<name>/`
2. Create `$PBOPREFIX$` containing: `z\atlas\addons\atlas_<name>`
3. Copy `script_component.hpp`, `config.cpp`, `CfgEventHandlers.hpp`, `XEH_preInit.sqf`, `XEH_postInit.sqf` from an existing module
4. Update `COMPONENT` to the short name
5. Update `CfgPatches` class name, display name, dependencies
6. Update `CfgFunctions` tag and file path
7. Update `CfgEventHandlers.hpp` class names
8. Create `functions/` directory
9. Register module in `XEH_preInit.sqf` via `EFUNC(main,registerModule)`
10. Run `python tools/generate_icons.py` to generate an icon
11. Rebuild: `hemtt build`

---

## Scheduler & Auto-Budget System (adapted from athena)

### Design (from `P:/athena/addons/core/`)

ATLAS.OS uses a **single per-frame handler** that dispatches to subsystems via staggered timers. This eliminates the problem of 10+ independent PFHs all running on the same frame tick. The pattern is derived from athena's scheduler (`fnc_initScheduler.sqf`, `fnc_schedulerTick.sqf`, `fnc_autoBudget.sqf`).

### Key Principles

1. **One PFH to rule them all** — a single `CBA_fnc_addPerFrameHandler` at rate `0` (every frame) dispatches to subsystems. No module registers its own PFH.

2. **Priority-based `exitWith` chain** — only ONE subsystem runs per frame tick, highest priority first:
   ```sqf
   if (_now >= GVAR(nextProfileMoveTime)) exitWith { ... };
   if (_now >= GVAR(nextOPCOMTime))       exitWith { ... };
   if (_now >= GVAR(nextInfluenceTime))   exitWith { ... };
   // etc.
   ```

3. **Staggered initial offsets** — subsystems are offset at init so they never pile up on the same frame:
   ```sqf
   GVAR(nextProfileMoveTime) = _now + 0.5;
   GVAR(nextOPCOMTime)       = _now + 1.0;
   GVAR(nextInfluenceTime)   = _now + 1.5;
   GVAR(nextCivilianTime)    = _now + 2.0;
   GVAR(nextGCTime)          = _now + 3.0;
   ```

4. **Round-robin within budget** — each subsystem processes items in a `while` loop bounded by `diag_tickTime`:
   ```sqf
   private _budget = GVAR(profileMoveBudget) / 1000;
   private _start = diag_tickTime;
   while {_idx < _count && {diag_tickTime - _start < _budget}} do {
       // process one profile
       _idx = _idx + 1;
   };
   GVAR(profileMoveIdx) = _idx mod _count;  // wrap for next tick
   ```

5. **Auto-budget adjusts ms allocation based on FPS**:
   - Every 2 seconds, measure `diag_fps` (EMA smoothed, 70/30 weight)
   - Compute `headroom = (1000/targetFPS) - (1000/currentFPS)`
   - If headroom > 0: gently increase budget toward desired (30% lerp)
   - If headroom < 0: pressure-scale budget down (up to 40% reduction)
   - Ceiling: `targetFrameTime * (framePct / 100)` — user-configurable in CBA settings
   - Floor: 1ms minimum (diag_tickTime can't measure below this)

### CBA Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `atlas_main_schedulerTargetFPS` | SLIDER | 40 | Target FPS floor. Budget scales down as FPS approaches this. |
| `atlas_main_schedulerFramePct` | SLIDER | 15 | Max % of frame time ATLAS scheduler can use. 10-15% listen server, 20-30% dedicated. |

### ATLAS Subsystem Priority Order

| Priority | Subsystem | Interval | Budget Source | Items |
|----------|-----------|----------|---------------|-------|
| 1 (highest) | Profile virtual movement | 0.25s | autoBudget | Virtual profiles |
| 2 | Spawn/despawn check | 2.0s | fixed | Players × nearby profiles |
| 3 | OPCOM decision tick | 30.0s | autoBudget | Objectives |
| 4 | Influence map update | 30.0s | autoBudget | Grid cells |
| 5 | Morale update | 5.0s | autoBudget | All profiles |
| 6 | LOGCOM convoy tick | 10.0s | fixed | Active convoys |
| 7 | Civilian ambient | 5.0s | fixed | Nearby players |
| 8 | CQB garrison check | event-driven | — | On player area change |
| 9 | GC cleanup | 10.0s | fixed | Death queue |
| 10 | Grid sync (spawned) | 5.0s | fixed | Spawned profiles |
| 11 (lowest) | Auto-budget recalc | 2.0s | — | — |

### Implementation Plan

Files to create in `addons/atlas_main/functions/`:
- `fnc_initScheduler.sqf` — stagger timers, set initial budgets, start single PFH
- `fnc_schedulerTick.sqf` — priority `exitWith` chain, dispatch to subsystems
- `fnc_autoBudget.sqf` — EMA-smoothed FPS monitoring, budget adjustment

The scheduler replaces all individual module PFHs. Modules register their tick function with the scheduler rather than calling `CBA_fnc_addPerFrameHandler` themselves.

### Reference Files (athena)
- `P:/athena/addons/core/functions/fnc_initScheduler.sqf` — staggered init, single PFH
- `P:/athena/addons/core/functions/fnc_schedulerTick.sqf` — priority dispatch chain
- `P:/athena/addons/core/functions/fnc_autoBudget.sqf` — EMA FPS tracking, budget scaling
- `P:/athena/addons/core/functions/fnc_processBrain.sqf` — round-robin within budget
- `P:/athena/addons/core/functions/fnc_updateLOD.sqf` — LOD tier classification with budget guard

---

## How ATLAS.OS Leverages Athena's Scheduler Pattern

### The Problem

Athena manages **individual AI units** — each unit gets a brain tick, physiology update, and memory decay. The scheduler processes N units per frame within a ms budget.

ATLAS.OS manages **entire armies** — 10,000+ virtual profiles, objectives, bases, supply chains, influence maps, morale, weather, diplomacy, convoys, and more. The workloads are fundamentally different:

| Dimension | Athena | ATLAS.OS |
|-----------|--------|----------|
| Work items | ~200 AI units | 10,000+ profiles + objectives + bases + convoys |
| Item types | Uniform (all units get same tick) | Heterogeneous (profiles, objectives, cells, convoys are different work) |
| Priority | Distance-based LOD | Strategic importance + proximity |
| Tick rate | 0.25s–5s per unit based on LOD | 0.25s–60s per subsystem based on urgency |
| Budget consumers | 2 (brain + tactics) | 8+ subsystems competing for frame time |

### Adaptation: Multi-Pool Scheduler

Instead of athena's single round-robin pool, ATLAS.OS uses **multiple pools** within the same single-PFH dispatcher. Each pool has its own:
- Round-robin index
- Auto-budget allocation (ms)
- Interval timer
- Item count
- Per-item cost EMA

The auto-budget divides the total frame budget (from `schedulerFramePct`) across pools proportional to their item count and urgency weight.

### Budget Allocation Algorithm

```
Total budget = (1000 / targetFPS) * (framePct / 100)
Example: (1000/40) * (15/100) = 3.75ms per frame

Pool allocation:
  profileMove:  weight 3.0 × itemCount → proportional share
  opcom:        weight 2.0 × itemCount → proportional share
  influence:    weight 1.0 × cellCount → proportional share
  morale:       weight 1.5 × itemCount → proportional share
  convoy:       weight 1.0 × itemCount → proportional share

Each pool gets: (poolWeight × poolItems) / totalWeightedItems × totalBudget
Clamped to [1.0ms floor, poolCeiling]
```

### LOD Concept for Profiles (from athena's LOD tiers)

Athena classifies units by distance: hot (full processing), warm (reduced), cold (minimal), frozen (skip). ATLAS.OS applies the same concept to **profiles**:

| Tier | Condition | Virtual Move Rate | Morale Check | OPCOM Priority |
|------|-----------|-------------------|--------------|----------------|
| HOT | Profile within 2000m of any player | Every tick (0.25s) | Every tick | Highest |
| WARM | Profile within 5000m of any player | Every 4th tick (1s) | Every 2nd tick | Normal |
| COLD | Profile beyond 5000m | Every 16th tick (4s) | Every 8th tick | Low |
| FROZEN | Profile idle (no waypoints, garrisoned) | Skip | Every 30s | Skip |

This means 10,000 profiles don't all need processing every tick. At any given time:
- ~200 HOT profiles (near players) get full attention
- ~800 WARM profiles get reduced attention
- ~5000 COLD profiles get minimal attention
- ~4000 FROZEN profiles are skipped entirely

**Effective work per tick**: ~200 HOT + 200 WARM/4 + 313 COLD/16 = **~270 items**, not 10,000.

### EMA Cost Tracking Per Pool

Each pool tracks its per-item cost using Exponential Moving Average (from athena's `autoBudgetSmoothedCost`):

```sqf
// After processing N items in pool:
private _elapsed = (diag_tickTime - _start) * 1000;
private _costPerItem = _elapsed / (_processed max 1);
GVAR(poolCost_profileMove) = GVAR(poolCost_profileMove) * 0.8 + _costPerItem * 0.2;
```

This lets the auto-budget predict how many items it can process within budget:
```sqf
private _maxItems = floor (GVAR(profileMoveBudget) / GVAR(poolCost_profileMove));
```

### Pressure Response (from athena's headroom calculation)

When FPS drops below target:

1. **Mild pressure** (FPS 5-15% below target): Reduce all pool budgets by pressure × 0.3
2. **Heavy pressure** (FPS 15-30% below target): Reduce budgets by pressure × 0.5, promote COLD→FROZEN for distant profiles
3. **Critical pressure** (FPS >30% below target): Emergency — only process HOT profiles, skip all WARM/COLD, fire `atlas_performance_degraded` event

Recovery requires 5 consecutive ticks above target (from athena's hysteresis approach, adapted from §27.6).

### Event-Driven vs Scheduled

Some ATLAS subsystems should NOT be in the scheduler — they should remain event-driven:

| Subsystem | Pattern | Why |
|-----------|---------|-----|
| Spawn/despawn | Event (`ATLAS_player_areaChanged`) | Only fires when player crosses grid cell — zero cost when stationary |
| CQB garrison | Event (`ATLAS_player_areaChanged`) | Same — no polling needed |
| Profile destroyed | Event (`EntityKilled` EH) | Instant response, not periodic |
| Objective captured | Event (presence check) | Driven by profile proximity events |
| Base supply shortage | Event (threshold check in supply consumption) | Fires only when supply drops below threshold |

The scheduler handles the **periodic bulk work**: virtual movement, morale updates, influence map recalculation, convoy routing, grid sync. Events handle the **reactive instant work**.

### Implementation: Module Registration

Instead of modules calling `CBA_fnc_addPerFrameHandler`, they register a tick function with the scheduler:

```sqf
// In atlas_profile XEH_postInit.sqf:
[
    "profileMove",              // pool name
    FUNC(virtualMoveTick),      // tick function
    0.25,                       // interval (seconds)
    3.0,                        // urgency weight
    "profileRegistry"           // items source (registry key or function)
] call EFUNC(main,registerSchedulerPool);
```

The scheduler owns the PFH. Modules just provide their tick function and config. This means:
- Adding a new subsystem = one `registerSchedulerPool` call
- Removing a subsystem = comment out the registration
- No module ever touches `CBA_fnc_addPerFrameHandler` directly
- Auto-budget automatically incorporates new pools

### Debug Overlay

When `atlas_main_perfMonitor` is enabled, the perf overlay shows per-pool stats:

```
ATLAS.OS Scheduler
─────────────────────────
Pool            Budget   Used    Items   Cost/Item
profileMove     1.20ms   0.95ms  47/200  0.020ms
opcom           0.80ms   0.12ms  3/50    0.040ms
influence       0.50ms   0.38ms  10/3600 0.038ms
morale          0.40ms   0.15ms  5/200   0.030ms
convoy          0.20ms   0.02ms  2/3     0.010ms
─────────────────────────
Total           3.10ms   1.62ms  FPS: 48.2
Headroom        +1.48ms  Target: 40 FPS
```

### Files to Create

| File | Description |
|------|-------------|
| `fnc_initScheduler.sqf` | Stagger timers, create pool registry, start single PFH |
| `fnc_schedulerTick.sqf` | Priority `exitWith` chain, dispatch pools by timer |
| `fnc_autoBudget.sqf` | EMA FPS, per-pool cost tracking, budget reallocation |
| `fnc_registerSchedulerPool.sqf` | Module API to register a tick function with the scheduler |
| `fnc_schedulerDebug.sqf` | Perf overlay rendering (client-side) |

### Migration Plan

1. Implement scheduler in `atlas_main`
2. Remove the 3 existing PFHs (player grid check, perf monitor, profile grid sync)
3. Register them as scheduler pools instead
4. As new modules are implemented (OPCOM, LOGCOM, etc.), they register pools — never create PFHs

---

## Testing in Arma 3

### Quick Test
1. `hemtt build` (builds PBOs)
2. Launch Arma 3
3. Enable `@ATLAS_OS` and `@CBA` in the launcher
4. Open Eden Editor, place ATLAS.OS modules from the modules panel
5. Preview mission

### Dev Mode (File Patching)
```bash
hemtt dev
```
This creates a file-patched build. Launch Arma 3 with `-filePatching` parameter. You can edit SQF files live and use `#include` reloading.

### Integration Tests
See `tests/integration.VR/` — run via the CI workflow or manually:
1. Build with `hemtt dev`
2. Start Arma 3 dedicated server with the test mission
3. Results are logged to RPT with `[ATLAS_TEST]` markers

---

## GitHub Actions CI/CD

### CI (`.github/workflows/ci.yml`)
- Triggers on push/PR to main
- Installs HEMTT, runs `hemtt check` (lint) and `hemtt build`
- Uploads build artifacts on main pushes

### Release (`.github/workflows/release.yml`)
- Triggers on `v*` tags
- Builds signed release with `hemtt release`
- Creates GitHub Release with auto-generated notes
- Pre-release detection for `-rc`, `-alpha`, `-beta` tags

### Creating a Release
```bash
git tag v0.1.0
git push origin v0.1.0
```

---

## Eden Editor Module Fix Log (2026-03-19)

### Problem
Modules were not appearing in the Eden Editor. Three root causes:

1. **Missing icon files** — `icon` properties pointed to `.paa` files that didn't exist, causing RPT errors
2. **Wrong function references** — Used `ATLAS_fnc_xxx_moduleInit` instead of the correct `atlas_xxx_fnc_moduleInit` (CBA macro expansion format)
3. **Missing parent class declarations** — HEMTT validates configs per-PBO. Child PBOs inheriting `ATLAS_ModuleBase` couldn't resolve `AttributesBase`, `Combo`, `Edit`, `CheckboxNumber` because those classes are defined in `Module_F` which wasn't redeclared

### Solution (Derived from ALiVE Pattern)

Referenced `github.com/ALiVEOS/ALiVE.OS/master/addons/main/CfgVehicles.hpp`:

1. `CfgFactionClasses` with `side = 7` (Logic) creates the ATLAS.OS category in Eden
2. `ATLAS_ModuleBase : Module_F` with `scope = 1` provides shared defaults (hidden)
3. **Every module PBO** must redeclare the full `Module_F` → `AttributesBase` hierarchy
4. Icons temporarily use vanilla fallback: `\a3\Modules_F\data\iconModule_ca.paa`
5. Function references use: `atlas_<component>_fnc_moduleInit`

### Config Pattern (Template for New Modules)

```cpp
class CfgVehicles {
    class Logic;
    class Module_F : Logic {
        class AttributesBase {
            class Default;
            class Edit;
            class Combo;
            class Checkbox;
            class CheckboxNumber;
            class ModuleDescription;
            class Units;
        };
        class ModuleDescription;
    };

    class ATLAS_ModuleBase : Module_F {
        scope = 1;
        category = "ATLAS_Modules";
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 1;
        curatorCanAttach = 1;
        author = "ATLAS.OS Team";
    };

    class ATLAS_Module_XXX : ATLAS_ModuleBase {
        scope = 2;
        displayName = "ATLAS - Module Name";
        icon = "\a3\Modules_F\data\iconModule_ca.paa";
        picture = "\a3\Modules_F\data\iconModule_ca.paa";
        function = "atlas_xxx_fnc_moduleInit";
        functionPriority = 2;

        class Attributes : AttributesBase {
            // module-specific attributes here
            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Description text.";
            sync[] = {};
        };
    };
};
```

### Files Modified

| File | Key Changes |
|------|-------------|
| `atlas_main/config.cpp` | Added `A3_Modules_F` to requiredAddons, created `ATLAS_ModuleBase`, fixed icon, added `CfgFactionClasses` |
| `atlas_placement/config.cpp` | Full Module_F hierarchy, fixed function ref, fixed icon |
| `atlas_ato/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_ato_fnc_moduleInit` |
| `atlas_civilian/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_civilian_fnc_moduleInit` |
| `atlas_cqb/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_cqb_fnc_moduleInit` |
| `atlas_insertion/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_insertion_fnc_moduleInit` |
| `atlas_opcom/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_opcom_fnc_moduleInit` |
| `atlas_persistence/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_persistence_fnc_moduleInit` |
| `atlas_support/config.cpp` | Added ATLAS_ModuleBase, fixed `atlas_support_fnc_moduleInit` |

### TODO
- [ ] Create custom military-styled PAA icons for each module
- [ ] Verify modules appear correctly in Eden Editor in-game

---

## Arma 3 Install Location

```
D:\Program Files\Steam\steamapps\common\Arma 3
```

## Project Location

```
P:\ATLAS.OS
```

## HEMTT Location

```
C:\Users\chimi\Downloads\windows-x64\hemtt.exe
```
