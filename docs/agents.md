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
