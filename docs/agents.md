# ATLAS.OS — Developer Workflow & Build Guide

## Current Implementation Status (as of 2026-03-19)

### What's Implemented and Working

| Module | Functions | Status |
|--------|-----------|--------|
| `atlas_main` | 18 functions | Core framework, registries, spatial grid, scheduler, auto-budget |
| `atlas_profile` | 27 functions | Virtual profiles, spawn/despawn, FSM, virtual combat, movement |
| `atlas_placement` | 10 functions | Eden module, force generation, objective auto-detection |
| **Total** | **55 functions** | **104 SQF files compiled, 24 PBOs building clean** |

### Architecture (Three Layers)

```
┌─────────────────────────────────────────────────┐
│  UNSCHEDULED (Single PFH — scheduler)           │
│  atlas_main_fnc_schedulerTick                   │
│  ─ Player grid cell tracking (every 2s)         │
│  ─ Spawned profile grid sync (every 5s)         │
│  ─ Auto-budget recalculation (every 2s)         │
│  ─ Spawn/despawn (event-driven, max 1/frame)    │
├─────────────────────────────────────────────────┤
│  SCHEDULED (spawn — virtual simulator)          │
│  atlas_profile_fnc_virtualSimulator             │
│  ─ Profile FSM tick (7 states)                  │
│  ─ Virtual movement (time-delta, road/speed)    │
│  ─ Contact detection (spatial grid)             │
│  ─ Lanchester combat resolution                 │
│  ─ Morale/withdrawal/rout                       │
│  ─ Yields every 50 profiles (sleep 0.001)       │
├─────────────────────────────────────────────────┤
│  EVENT-DRIVEN (CBA events — zero idle cost)     │
│  ─ ATLAS_player_areaChanged → spawn/despawn     │
│  ─ ATLAS_profile_destroyed → cleanup            │
│  ─ ATLAS_placement_complete → OPCOM notify      │
│  ─ ATLAS_performance_tierChanged → degrade      │
└─────────────────────────────────────────────────┘
```

### Key Files for New Agents

If you're an agent picking up development, start here:

| File | What it does |
|------|-------------|
| `addons/atlas_main/XEH_preInit.sqf` | All PREP calls, CBA settings, registries, module self-registration |
| `addons/atlas_main/XEH_postInit.sqf` | Server init, scheduler start, perf overlay |
| `addons/atlas_main/functions/fnc_schedulerTick.sqf` | The single PFH — priority exitWith chain |
| `addons/atlas_main/functions/fnc_autoBudget.sqf` | EMA FPS tracking, budget scaling |
| `addons/atlas_profile/functions/fnc_virtualSimulator.sqf` | Virtual world simulation loop (scheduled) |
| `addons/atlas_profile/functions/fnc_virtualFSMTick.sqf` | Per-profile 7-state FSM |
| `addons/atlas_profile/functions/fnc_resolveVirtualCombat.sqf` | Lanchester combat model |
| `addons/atlas_placement/functions/fnc_moduleInit.sqf` | Eden module callback pattern |
| `docs/ARCHITECTURE.md` | Full 11,478-line architecture spec (29 sections) |

### What Needs To Be Done Next

1. **`atlas_opcom`** — AI commander. ASSESS→PLAN→EXECUTE state machine. Scores objectives, allocates profiles as task forces, issues waypoint orders. Should run in the **scheduled** virtual simulator, not as a PFH.

2. **Custom PAA icons** — All Eden modules currently use vanilla fallback icon (`\a3\Modules_F\data\iconModule_ca.paa`). Need military-styled icons per module.

3. **Eden module testing** — Modules now appear under Logic → ATLAS.OS in Eden. Need to verify all 9 modules (Main, Placement, OPCOM, CQB, ATO, Civilian, Insertion, Persistence, Support) show and configure correctly.

4. **Objective module** — `ATLAS_Module_Objective` needs a config.cpp entry so mission makers can place objective markers and sync them to OPCOM/Placement.

5. **Persistence** — Save/load virtual profile state to profileNamespace so campaigns survive restarts.

### Known Issues

- **PBO naming** — HEMTT produces `atlas_atlas_main.pbo` (double prefix). This works but looks odd. The `$PBOPREFIX$` files are correct (`z\atlas\addons\atlas_main`), so internal paths resolve fine.
- **Module function callback** — Eden 3DEN calls module `function` with a string `_this` (classname), not `[logic, units, activated]`. All moduleInit functions handle this with `if (_this isEqualType "") exitWith {}`.
- **No individual module PFHs** — ALL periodic work goes through the scheduler or virtual simulator. Modules must NOT call `CBA_fnc_addPerFrameHandler` directly.

### Rules for Implementing New Modules

1. **Never create a PFH** — register with the scheduler or add to the virtual simulator loop
2. **Use events** for reactive work — subscribe to CBA events, don't poll
3. **Scheduled for virtual work** — pure HashMap math goes in the scheduled virtual simulator
4. **Unscheduled for real-world work** — anything touching actual game objects goes through the scheduler PFH
5. **moduleInit must handle string _this** — Eden 3DEN passes classname string, not array
6. **Redeclare Module_F hierarchy** — every CfgVehicles module must redeclare the full `Module_F` → `AttributesBase` class chain for HEMTT validation
7. **Icons use vanilla fallback** — `\a3\Modules_F\data\iconModule_ca.paa` until custom PAAs are created

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

## Virtual Simulation Engine (Scheduled Environment)

### Architecture Decision: Scheduled vs Unscheduled

After reviewing athena's PFH pattern and ALiVE's profile simulator, the correct split is:

**Unscheduled (PFH / events)** — things that touch the real game world:
- Spawn/despawn (creates actual Arma units — max 1 per frame)
- Player grid cell tracking (reads `getPosATL`)
- Grid sync for spawned profiles (reads real unit positions)
- Perf overlay (renders HUD)
- Killed/connected/disconnected event handlers

**Scheduled (`spawn`)** — the virtual simulation layer (pure data, no engine objects):
- Virtual profile movement (updating `[x,y]` in HashMaps — just math)
- Virtual combat detection and resolution (spatial grid queries + dice rolls)
- Morale calculation (number crunching)
- Influence map recalculation (grid cell iteration)
- OPCOM decision cycle (objective scoring, force allocation)
- Convoy routing (waypoint advancement)
- Intel decay (confidence value degradation)

**Why scheduled works here:** Virtual profiles are HashMap data. Moving one is `_profile set ["pos", _newPos]` — microseconds. There's no rendering, no AI pathfinding, no collision. The scheduled environment's yielding (`sleep 0.001`) is perfect because we're doing 10,000 tiny operations that don't need frame-precise timing.

### ALiVE's Virtual Simulator (Reference)

ALiVE's `fnc_profileSimulator.sqf` processes profiles in a scheduled loop:
- **4 profiles per tick** for movement simulation
- **3 attacks per tick** for virtual combat resolution
- Uses `diag_tickTime` delta for time-normalized movement
- Combat detection via faction relationship checks + proximity
- Damage applied to individual unit classnames within profiles
- Vehicle hitpoint tracking for virtual vehicle combat
- Amphibious detection (auto-assigns boats when crossing water)

ALiVE's `fnc_profileGetDamageOutput.sqf` calculates damage per second:
- Base damage scales with unit count: `0.015 × unitCount` for infantry
- Hit chance varies by matchup (0.30–0.90)
- Critical hit system with type-dependent crit damage
- Vehicle type matrix (tank vs infantry, plane vs vehicle, etc.)
- Artillery gets distance-based accuracy modifier

### ATLAS.OS Virtual Simulation Design

ATLAS improves on ALiVE's approach in several ways:

#### 1. Lightweight Profile FSM (HashMap-based, no CBA/Arma FSM)

Each virtual profile carries a `state` key that drives behavior. Transitions are a simple `switch` — zero overhead:

```sqf
// Virtual profile state machine — runs in scheduled loop
// States: IDLE, MOVING, ENGAGING, WITHDRAWING, GARRISONED, RETREATING, ROUTED
switch (_profile get "state") do {
    case "IDLE": {
        if (count (_profile get "waypoints") > 0) then {
            _profile set ["state", "MOVING"];
        };
    };
    case "MOVING": {
        [_profile, _dt] call fnc_virtualMove;
        // Check for contacts in current/adjacent grid cells
        private _contacts = [_profile] call fnc_detectVirtualContacts;
        if (count _contacts > 0) then {
            _profile set ["state", "ENGAGING"];
            _profile set ["engagedWith", _contacts];
        };
    };
    case "ENGAGING": {
        private _result = [_profile, _dt] call fnc_resolveVirtualCombat;
        switch (_result) do {
            case "WON":        { _profile set ["state", "MOVING"] };
            case "LOST":       { _profile set ["state", "WITHDRAWING"] };
            case "DRAW":       { /* stay engaging */ };
            case "ROUTED":     { _profile set ["state", "ROUTED"] };
        };
    };
    case "WITHDRAWING": {
        [_profile, _dt, true] call fnc_virtualMove;  // move toward retreat waypoint
        if (_profile get "morale" > 40) then {
            _profile set ["state", "MOVING"];
        };
    };
    case "GARRISONED": {
        // Do nothing — waiting for OPCOM orders
    };
    case "ROUTED": {
        // Flee at max speed toward nearest friendly objective
        [_profile, _dt, true] call fnc_virtualMove;
    };
};
```

No FSM file, no CBA state machine, no overhead — just a string key and a switch.

#### 2. Virtual Movement (Time-Delta Normalized)

```sqf
// fnc_virtualMove — scheduled, called per profile per sim tick
params ["_profile", "_dt", ["_isRetreating", false]];

private _waypoints = _profile get "waypoints";
private _wpIdx = _profile get "wpIndex";
if (_wpIdx >= count _waypoints) exitWith {};

private _target = if (_isRetreating) then {
    _profile get "retreatPos"
} else {
    (_waypoints select _wpIdx) get "pos"
};

private _pos = _profile get "pos";
private _type = _profile get "type";

// Speed from type lookup (m/s)
private _baseSpeed = switch (_type) do {
    case "infantry":    { 1.4 };
    case "motorized":   { 11.0 };
    case "mechanized":  { 8.3 };
    case "armor":       { 7.2 };
    case "air":         { 44.0 };
    default             { 1.4 };
};

// Road bonus (1.4x if near road)
private _roadBonus = if (_profile getOrDefault ["onRoad", false]) then { 1.4 } else { 1.0 };

// Strength penalty (wounded units move slower)
private _strengthMod = linearConversion [0, 1, _profile get "strength", 0.5, 1.0, true];

private _speed = _baseSpeed * _roadBonus * _strengthMod;
private _moveDist = _speed * _dt;

private _dist = _pos distance2D _target;
if (_moveDist >= _dist) then {
    // Arrived at waypoint
    _profile set ["pos", _target];
    if (!_isRetreating) then {
        _profile set ["wpIndex", _wpIdx + 1];
    };
    [_profile, _target] call EFUNC(main,gridMove);
} else {
    // Move toward target
    private _dir = _pos getDir _target;
    private _newPos = [
        (_pos#0) + (sin _dir) * _moveDist,
        (_pos#1) + (cos _dir) * _moveDist,
        0
    ];
    _profile set ["pos", _newPos];
    [_profile, _newPos] call EFUNC(main,gridMove);
};
```

#### 3. Virtual Combat Detection (Spatial Grid)

```sqf
// fnc_detectVirtualContacts — uses spatial grid, not O(n²) scan
params ["_profile"];

private _pos = _profile get "pos";
private _side = _profile get "side";
private _contactRange = switch (_profile get "type") do {
    case "infantry":    { 400 };
    case "motorized":   { 600 };
    case "armor":       { 800 };
    case "air":         { 1500 };
    default             { 400 };
};

private _nearbyIDs = [_pos, _contactRange] call EFUNC(main,gridQuery);
private _contacts = [];

{
    if (_x == (_profile get "id")) then { continue };
    private _other = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_other isEqualType createHashMap) then { continue };
    if ((_other get "side") isEqualTo _side) then { continue };
    if ((_other get "state") in ["ROUTED", "GARRISONED"]) then { continue };

    private _otherPos = _other get "pos";
    if (_pos distance2D _otherPos <= _contactRange) then {
        _contacts pushBack _x;
    };
} forEach _nearbyIDs;

_contacts
```

#### 4. Virtual Combat Resolution (Improved over ALiVE)

ALiVE uses flat damage-per-second with hit chance. ATLAS adds:
- **Force ratio** — 3:1 advantage = faster attrition on the weaker side
- **Morale** — low morale profiles deal less damage, break faster
- **Supply** — low ammo = reduced damage output
- **Terrain** — defender in urban/forest gets defensive bonus
- **Type effectiveness** — armor matrix (AT vs armor, AA vs air, etc.)

```sqf
// fnc_resolveVirtualCombat — called per engaging profile per sim tick
params ["_profile", "_dt"];

private _engaged = _profile getOrDefault ["engagedWith", []];
if (_engaged isEqualTo []) exitWith { "WON" };

// Calculate own combat power
private _ownStrength = _profile get "strength";
private _ownCount = count (_profile get "classnames");
private _ownMorale = (_profile getOrDefault ["morale", 80]) / 100;
private _ownAmmo = (_profile getOrDefault ["ammoLevel", 1.0]);
private _ownType = _profile get "type";

private _ownPower = _ownCount * _ownStrength * _ownMorale * _ownAmmo;

// Apply type effectiveness
private _typeMultiplier = 1.0;

// Sum enemy combat power
private _enemyPower = 0;
private _aliveContacts = [];
{
    private _enemy = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_enemy isEqualType createHashMap) then { continue };
    if ((_enemy get "strength") <= 0) then { continue };

    private _eCount = count (_enemy get "classnames");
    private _eStr = _enemy get "strength";
    private _eMorale = (_enemy getOrDefault ["morale", 80]) / 100;
    private _eAmmo = (_enemy getOrDefault ["ammoLevel", 1.0]);

    _enemyPower = _enemyPower + (_eCount * _eStr * _eMorale * _eAmmo);
    _aliveContacts pushBack _x;
} forEach _engaged;

if (_aliveContacts isEqualTo []) exitWith { "WON" };
_profile set ["engagedWith", _aliveContacts];

// Force ratio attrition
private _totalPower = _ownPower + _enemyPower;
if (_totalPower <= 0) exitWith { "DRAW" };

// Lanchester-style: damage proportional to enemy power / total
private _damageToSelf = ((_enemyPower / _totalPower) * 0.05 * _dt) + (random 0.01 * _dt);
private _damageToEnemy = ((_ownPower / _totalPower) * 0.05 * _dt) + (random 0.01 * _dt);

// Apply damage to self
private _newStrength = ((_profile get "strength") - _damageToSelf) max 0;
_profile set ["strength", _newStrength];

// Apply damage to enemies (distributed evenly)
{
    private _enemy = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if (_enemy isEqualType createHashMap) then {
        private _eStr = ((_enemy get "strength") - (_damageToEnemy / count _aliveContacts)) max 0;
        _enemy set ["strength", _eStr];
        if (_eStr <= 0.05) then {
            [_x, "virtualCombat"] call EFUNC(profile,destroy);
        };
    };
} forEach _aliveContacts;

// Check morale-based outcomes
private _morale = _profile getOrDefault ["morale", 80];
if (_newStrength <= 0.05) exitWith { "LOST" };
if (_newStrength < 0.3 && _morale < 30) exitWith { "ROUTED" };
if (_newStrength < 0.5 && _morale < 50) exitWith { "LOST" };

"DRAW"
```

#### 5. Main Simulation Loop (Scheduled)

```sqf
// fnc_virtualSimulator.sqf — THE virtual world simulation loop
// Runs in scheduled environment. Yields every N profiles.
// This is the heart of ATLAS.OS — the virtual battlefield.

if (!isServer) exitWith {};

private _simInterval = 0.1;  // 100ms between full passes

while {GVAR(simulatorRunning)} do {
    private _now = diag_tickTime;
    private _registry = EGVAR(main,profileRegistry);
    private _count = count _registry;
    private _processed = 0;

    {
        private _profile = _y;

        // Skip spawned profiles (real Arma AI handles them)
        if (_profile get "state" isEqualTo "spawned") then { continue };
        // Skip profiles with no work to do
        if (_profile get "state" isEqualTo "GARRISONED") then { continue };

        // Time delta since this profile was last simulated
        private _lastSim = _profile getOrDefault ["_lastSimTime", _now];
        private _dt = _now - _lastSim;
        if (_dt < 0.05) then { continue };  // min 50ms between ticks per profile

        // Run the lightweight FSM
        [_profile, _dt] call FUNC(virtualFSMTick);

        _profile set ["_lastSimTime", _now];
        _processed = _processed + 1;

        // Yield every 50 profiles to prevent scheduler starvation
        if (_processed % 50 == 0) then {
            sleep 0.001;
        };
    } forEach _registry;

    // Wait before next full pass
    sleep _simInterval;
};
```

### Key Differences from ALiVE

| Aspect | ALiVE | ATLAS.OS |
|--------|-------|----------|
| Processing | 4 profiles/tick, unscheduled PFH | All eligible profiles, scheduled with yield |
| Combat model | Flat DPS with hit chance | Lanchester force-ratio with morale/ammo/type modifiers |
| States | spawned/virtual binary | 7-state FSM (IDLE/MOVING/ENGAGING/WITHDRAWING/GARRISONED/RETREATING/ROUTED) |
| Detection | Faction friendship + proximity scan | Spatial grid query (O(nearby) not O(n)) |
| Morale | Not modeled | Affects combat output, causes withdrawal/rout |
| Supply | Not modeled | Low ammo reduces combat effectiveness |
| Resolution | Damage accumulates per unit | Force ratio determines attrition rate both sides |
| Movement | Speed × time delta | Speed × road × strength × time delta |
| Yielding | Bounded by frame budget | `sleep 0.001` every 50 profiles — never blocks frames |

### Hybrid Architecture Summary

```
┌─────────────────────────────────────────────────┐
│  UNSCHEDULED (PFH)                              │
│  Athena-style auto-budget scheduler             │
│  ─ Spawn/despawn (1 per frame max)              │
│  ─ Player grid tracking (every 2s)             │
│  ─ Spawned profile grid sync (every 5s)         │
│  ─ Perf overlay                                 │
├─────────────────────────────────────────────────┤
│  SCHEDULED (spawn)                              │
│  Virtual simulator loop                         │
│  ─ Profile FSM tick (movement, combat, morale)  │
│  ─ OPCOM decision cycle                         │
│  ─ Influence map recalculation                  │
│  ─ Convoy routing                               │
│  ─ Intel decay                                  │
│  ─ Yields every 50 items (sleep 0.001)          │
├─────────────────────────────────────────────────┤
│  EVENT-DRIVEN (CBA events)                      │
│  Zero cost when idle                            │
│  ─ Player area changed → spawn/despawn check    │
│  ─ Profile destroyed → GC queue                 │
│  ─ Objective captured → OPCOM re-evaluate       │
│  ─ Supply threshold → LOGCOM request            │
└─────────────────────────────────────────────────┘
```

### Files to Create (Virtual Simulator)

| File | Module | Description |
|------|--------|-------------|
| `fnc_virtualSimulator.sqf` | atlas_profile | Main scheduled loop — iterates all virtual profiles |
| `fnc_virtualFSMTick.sqf` | atlas_profile | Per-profile FSM switch (IDLE/MOVING/ENGAGING/etc.) |
| `fnc_virtualMove.sqf` | atlas_profile | Position update along waypoints with speed model |
| `fnc_detectVirtualContacts.sqf` | atlas_profile | Spatial grid query for nearby enemy profiles |
| `fnc_resolveVirtualCombat.sqf` | atlas_profile | Lanchester force-ratio combat resolution |
| `fnc_virtualCombatDamage.sqf` | atlas_profile | Type effectiveness matrix and damage calculation |

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
