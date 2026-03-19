# ATLAS.OS — Architecture Design Document
### Advanced Tactical Lifecycle & Asymmetric Simulation Operating System
**Version:** 0.2.0-DRAFT
**Date:** 2026-03-18
**Supersedes:** ALiVE.OS (Arma 3)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [ALiVE.OS Analysis — What We're Replacing](#2-aliveOS-analysis)
3. [Performance Audit: ALiVE Bottlenecks](#3-performance-audit)
4. [ATLAS.OS Architecture Overview](#4-atlasOS-architecture-overview)
5. [Core Engine: Data Layer](#5-core-engine-data-layer)
6. [Scheduling Strategy: Scheduled vs Unscheduled](#6-scheduling-strategy)
7. [Event-Driven Architecture](#7-event-driven-architecture)
8. [Hosting Models & Headless Client Distribution](#8-hosting-models)
9. [Module Architecture — 16 PBOs](#9-module-architecture)
10. [Module Specifications](#10-module-specifications)
11. [Cross-Server Persistence Architecture](#11-cross-server-persistence)
12. [Event Taxonomy](#12-event-taxonomy)
13. [Module Initialization Order](#13-initialization-order)
14. [PBO Directory Structure](#14-pbo-directory-structure)
15. [Performance Projections](#15-performance-projections)
16. [Key Architectural Decisions](#16-architectural-decisions)

---

## 1. Executive Summary

ATLAS.OS is a ground-up redesign of the ALiVE military simulation framework for Arma 3. Rather than patching a decade-old codebase, ATLAS.OS rebuilds every system using modern SQF capabilities — native HashMaps, event-driven patterns, CBA state machines, and a disciplined scheduled/unscheduled execution strategy.

**Key design goals:**

- **Feature parity** with every core ALiVE module (OPCOM, LOGCOM, CQB, Civilian, C2ISTAR, persistence, etc.)
- **Significant performance improvement** through native data structures, spatial indexing, and elimination of polling loops
- **Event-driven core** replacing ALiVE's spin-wait architecture in unscheduled contexts
- **Scheduled execution** only where large-batch AI computation genuinely benefits from yielding
- **Cross-server persistence** via PostgreSQL — multiple Arma 3 servers sharing theater state
- **All hosting models** — single player, listen server, dedicated server, and dedicated server with headless clients
- **Headless client AI distribution** — automatic load-balanced transfer of spawned AI groups to connected headless clients
- **Clean, maintainable architecture** replacing ALiVE's fragile index-based data access

**Module count:** ALiVE's 63+ modules consolidated into **16 cohesive PBOs**.

---

## 2. ALiVE.OS Analysis — What We're Replacing

### 2.1 ALiVE Module Inventory

ALiVE is organized into 63+ separate PBO addons. The core modules:

| ALiVE Module | Function |
|---|---|
| **sys_data** | Core data storage, database connectivity (War Room) |
| **sys_profile** | Virtual unit profile system — the heart of ALiVE |
| **sys_profileHandler** | Creates, destroys, and manages unit profiles |
| **mil_OPCOM** | Operational Commander — AI strategic decision-making |
| **mil_command** | Tactical AI behaviors (patrol, garrison, ambush) |
| **mil_CQB** | Close Quarters Battle — garrison spawning |
| **mil_logistics (LOGCOM)** | Logistics Commander — supply, reinforcement |
| **mil_placement** | Military unit placement on map at mission start |
| **mil_ato** | Air Tasking Order — AI air operations |
| **mil_convoy** | Convoy operations and escort |
| **mil_ied** | IED/VBIED/suicide bomber placement |
| **mil_intelligence** | Intelligence gathering and processing |
| **civ_population** | Civilian ambient population |
| **civ_placement** | Civilian placement and density |
| **amb_civ_command** | Civilian AI behaviors (20+ behavior functions) |
| **amb_civ_population** | Civilian interaction system |
| **C2ISTAR** | Command, Control, Intelligence tablet interface |
| **sys_data_couchdb / sys_data_pns** | Persistence backends |
| **sup_combatsupport** | Player-requested CAS, transport, artillery |
| **sup_multispawn** | Multiple insertion points |
| **sup_player_resupply** | Player logistics requests |
| **sup_group_manager** | Squad management |
| **sys_tasks** | Task assignment framework |
| **sys_spotrep / sys_sitrep / sys_patrolrep** | Reporting systems |
| **sys_GC** | Garbage collection |
| **sys_aiskill** | AI skill management |
| **sys_weather** | Weather persistence |
| **sys_marker** | Map marker management |
| **sys_statistics** | Player statistics (42 files) |
| **sys_adminactions** | Admin/debug tools |
| **sys_orbatcreator** | ORBAT creator (312KB) |
| **fnc_analysis** | Map sector analysis (50+ functions) |
| **fnc_strategic** | Cluster detection, target finding |

Plus ~30 additional modules for UI, assets, compatibility, compositions, and group definitions.

### 2.2 ALiVE's Custom Hash Implementation

**This is the single biggest architectural debt in ALiVE.** Before Arma 3 had native HashMaps (added in v2.02, April 2021), ALiVE implemented its own hash system using **parallel arrays**:

```sqf
// ALiVE "hash" — two parallel arrays
_hash = [
    ["keys", "values"],          // metadata at index 0
    ["name", "side", "pos"],     // keys at index 1
    ["Alpha", "west", [0,0,0]]   // values at index 2
];

// Access pattern — fragile, O(n) lookup:
_keyIndex = (_hash select 1) find "name";
_value = (_hash select 2) select _keyIndex;
```

**Problems:**

1. **O(n) lookup time** — Every value access requires a linear `find` across the keys array
2. **Index-based fragility** — All code depends on array position; any structural change breaks everything
3. **No type safety** — Everything is raw array manipulation
4. **Deep nesting hell** — Profiles contain hashes of hashes, leading to chains like `(_hash select 2) select ((_hash select 1) find "key")`
5. **Copy semantics confusion** — SQF arrays are passed by reference, but ALiVE's hash operations sometimes create unintended shared state
6. **Serialization overhead** — Converting these nested arrays to/from storage format is expensive

### 2.3 ALiVE's Execution Model

ALiVE runs most of its core logic in the **scheduled environment** (using `spawn`):

```sqf
// Typical ALiVE main loop pattern
[] spawn {
    while {true} do {
        {
            _profile = _x;
            // ... heavy computation ...
        } forEach ALIVE_profileHandler;

        sleep 10; // Fixed interval polling
    };
};
```

**Problems:**

1. **Spin-wait polling** — Most systems poll on fixed intervals rather than reacting to events
2. **Sleep granularity issues** — `sleep` in scheduled environment is not precise; actual delay can be 2-10x the requested value under load
3. **Scheduled suspension** — Long loops get suspended mid-execution by the scheduler, leading to inconsistent state
4. **No priority system** — All scheduled scripts compete equally for execution time
5. **Stale data** — Polling with 10-30 second intervals means systems operate on data that can be half a minute old

### 2.4 ALiVE's Profile System Architecture

The profile system is ALiVE's core innovation — virtualizing units as data when no player is near:

```
Real World (Spawned)          Virtual World (Data Only)
┌─────────────────┐          ┌──────────────────────┐
│ Actual AI units  │◄────────►│ Profile HashMap       │
│ on the ground    │ Spawn/   │ - Position            │
│ with full AI     │ Despawn  │ - Type/Classname      │
│ simulation       │          │ - Side                │
└─────────────────┘          │ - Waypoints           │
                              │ - Damage state        │
                              │ - Cargo/Loadout       │
                              └──────────────────────┘
```

**The spawn/despawn radius** is checked via continuous polling of all profiles against all player positions — an O(n×m) operation every cycle.

---

## 3. Performance Audit: ALiVE Bottlenecks

### 3.1 Quantified Performance Issues

| Bottleneck | Cause | Impact | Frequency |
|---|---|---|---|
| **Profile distance checks** | O(n×m) polling: all profiles × all players | 15-40ms per cycle with 200+ profiles | Every 10-30s |
| **Custom hash lookups** | Linear `find` on keys array | 0.0116ms per lookup (vs 0.0018ms HashMap) | Thousands/frame |
| **OPCOM decision loop** | Iterates all objectives, all profiles, scores each | 50-200ms per OPCOM cycle | Every 30-120s |
| **Serialization for persistence** | Deep recursive array traversal to flatten hashes | 100-500ms per save cycle | Every 60-300s |
| **Spawn/despawn thrashing** | Binary spawn/despawn at fixed radius, no hysteresis | Creates/destroys dozens of units in bursts | On player movement |
| **Civilian spawning** | Creates individual agents with full AI | High object count, AI computation | Continuous near players |
| **String comparisons** | Side/type checks use string matching | Adds up with thousands of checks | Per-profile operations |
| **forEach everywhere** | No use of `apply`, `select` with conditions, or early exit | Processes entire arrays even when subset needed | All loops |
| **Global variable pollution** | Hundreds of ALIVE_* globals | Namespace pollution, accidental overwrites | Always |

### 3.2 Measured Data Structure Performance (Arma 3 Engine Benchmarks)

| Operation | Native HashMap | ALiVE Dual-Array "Hash" | ALiVE Nested-Array Format |
|---|---|---|---|
| **Key-Value Lookup** | **0.0018ms** | 0.0038ms | 0.0116ms |
| **Scaling** | O(1) constant | O(n) linear | O(n) linear |
| **100 lookups** | 0.18ms | 0.38ms | 1.16ms |
| **1,000 lookups** | 1.8ms | 3.8ms | 11.6ms |
| **10,000 lookups** | 18ms | 38ms | 116ms |

### 3.3 Scheduled Environment Overhead

The Arma 3 scheduled environment:
- Scripts run via `spawn` or `execVM` enter the **scheduler queue**
- The scheduler gives each script a **time slice** (~3ms by default) per frame
- When a script's slice expires, it is **suspended** and resumed next opportunity
- `sleep` does NOT guarantee timing — under load, `sleep 1` can take 5-30 seconds
- `canSuspend` returns true — scripts can be interrupted at any `sleep`, `waitUntil`, or between statements

---

## 4. ATLAS.OS Architecture Overview

### 4.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          ATLAS.OS Core                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                      Event Bus (CBA)                           │  │
│  │   publish/subscribe • namespaced • typed payloads              │  │
│  └────────┬──────────────┬──────────────┬────────────────────────┘  │
│           │              │              │                             │
│  ┌────────▼────┐  ┌──────▼──────┐  ┌───▼──────────┐  ┌───────────┐ │
│  │  Data Layer │  │  Scheduler  │  │  Module      │  │ HC        │ │
│  │  (HashMaps) │  │  Manager    │  │  Loader &    │  │ Distrib.  │ │
│  │  + Spatial  │  │  (PFH/      │  │  Registry    │  │ Manager   │ │
│  │    Grid     │  │   Spawn)    │  │              │  │           │ │
│  └─────────────┘  └─────────────┘  └──────────────┘  └───────────┘ │
│                                                                       │
├───────────────────────────────────────────────────────────────────────┤
│                        Module Layer                                    │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐           │
│  │ OPCOM  │ │PROFILE │ │LOGIST. │ │  CQB   │ │ CIVILIAN │           │
│  └────────┘ └────────┘ └────────┘ └────────┘ └──────────┘           │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐           │
│  │  AIR   │ │  C2    │ │PERSIST │ │  GC    │ │ASYMMETRIC│           │
│  └────────┘ └────────┘ └────────┘ └────────┘ └──────────┘           │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                        │
│  │SUPPORT │ │  AI    │ │ STATS  │ │ ADMIN  │                        │
│  └────────┘ └────────┘ └────────┘ └────────┘                        │
├───────────────────────────────────────────────────────────────────────┤
│                      Integration Layer                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────────┐ │
│  │  CBA A3    │  │  Extension  │  │  Network    │  │  HC Transfer   │ │
│  │  Framework  │  │  Bridge     │  │  Sync Layer │  │  Layer         │ │
│  │            │  │  (atlas_db) │  │  (JIP/PV)   │  │  (AI Offload)  │ │
│  └────────────┘  └────────────┘  └────────────┘  └────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

### 4.2 Core Design Principles

1. **HashMap-First Data Model** — All entity state stored in native HashMaps. No parallel arrays. No index-based access.
2. **Event-Driven by Default** — Systems react to state changes via CBA events, not polling loops.
3. **Scheduled Only When Necessary** — Only batch AI computation uses scheduled environment. All reactive logic runs unscheduled.
4. **Spatial Indexing** — Grid-based spatial partitioning replaces O(n×m) distance checks.
5. **State Machines** — CBA state machines replace hand-rolled FSM loops for AI commander logic.
6. **Immutable Event Payloads** — Events carry snapshots, preventing race conditions.
7. **Modular Registration** — Modules self-register capabilities; core has zero knowledge of module internals.
8. **Hosting-Agnostic** — All systems detect and adapt to the hosting model (SP, listen, dedicated, HC).
9. **HC-Aware AI** — Spawned AI groups are automatically distributed to headless clients for load balancing.

---

## 5. Core Engine: Data Layer

### 5.1 Native HashMap Entity Model

Every entity in ATLAS.OS (unit profile, vehicle, objective, civilian) is a native HashMap:

```sqf
// ATLAS.OS profile — native HashMap, O(1) access
private _profile = createHashMapFromArray [
    ["id",         "ATLAS_P_001"],
    ["type",       "infantry"],
    ["classnames", ["B_Soldier_F", "B_Soldier_AR_F", "B_Soldier_GL_F"]],
    ["side",       west],
    ["pos",        [4500, 5200, 0]],
    ["waypoints",  []],
    ["damage",     createHashMapFromArray [["hull", 1], ["engine", 1]]],
    ["state",      "virtual"],    // "virtual" | "spawning" | "spawned" | "despawning"
    ["cargo",      []],
    ["groupData",  createHashMapFromArray [
        ["behaviour", "AWARE"],
        ["speed",     "NORMAL"],
        ["formation", "WEDGE"]
    ]],
    ["_lastUpdate", serverTime],
    ["_gridCell",   [45, 52]],    // spatial index reference
    ["_dirty",      false],
    ["_hcOwner",    0]            // 0 = server, >0 = HC clientOwner ID
];
```

**Comparison:**

```sqf
// ALiVE — fragile, slow (0.0116ms per access)
_side = (_profile select 2) select ((_profile select 1) find "side");

// ATLAS.OS — clean, fast (0.0018ms per access, 6.4x faster)
_side = _profile get "side";
```

### 5.2 Registry System

```sqf
// Global registries
ATLAS_profileRegistry    = createHashMap;  // profileID -> profile HashMap
ATLAS_objectiveRegistry  = createHashMap;  // objectiveID -> objective HashMap
ATLAS_civilianRegistry   = createHashMap;  // civID -> civilian HashMap
ATLAS_moduleRegistry     = createHashMap;  // moduleName -> module config HashMap

// O(1) registration and lookup
ATLAS_profileRegistry set [_id, _profile];
private _profile = ATLAS_profileRegistry get "ATLAS_P_001";

// Efficient iteration
{
    private _id = _x;
    private _profile = _y;
    // process...
} forEach ATLAS_profileRegistry;
```

### 5.3 Spatial Index — Grid-Based Partitioning

```sqf
#define ATLAS_GRID_SIZE 500  // 500m cells

// Spatial grid — HashMap of grid coordinates to typed buckets
ATLAS_spatialGrid = createHashMap;
// Key: str [cx, cy]
// Value: HashMap { "profiles"→[], "objectives"→[], "buildings"→[], "ieds"→[], "civilians"→[] }

ATLAS_fnc_gridInsert = {
    params ["_entityId", "_entityType", "_pos"];
    private _cell = [floor ((_pos#0) / ATLAS_GRID_SIZE), floor ((_pos#1) / ATLAS_GRID_SIZE)];
    private _key = str _cell;
    private _bucket = ATLAS_spatialGrid getOrDefault [_key, createHashMap];
    private _list = _bucket getOrDefault [_entityType, []];
    _list pushBack _entityId;
    _bucket set [_entityType, _list];
    ATLAS_spatialGrid set [_key, _bucket];
    _cell
};

ATLAS_fnc_gridQuery = {
    params ["_pos", "_radius", ["_entityType", "profiles"]];
    private _cellRadius = ceil (_radius / ATLAS_GRID_SIZE);
    private _centerX = floor ((_pos#0) / ATLAS_GRID_SIZE);
    private _centerY = floor ((_pos#1) / ATLAS_GRID_SIZE);
    private _results = [];

    for "_dx" from -_cellRadius to _cellRadius do {
        for "_dy" from -_cellRadius to _cellRadius do {
            private _key = str [_centerX + _dx, _centerY + _dy];
            private _bucket = ATLAS_spatialGrid getOrDefault [_key, createHashMap];
            _results append (_bucket getOrDefault [_entityType, []]);
        };
    };
    _results
};

ATLAS_fnc_gridMove = {
    params ["_entityId", "_entityType", "_oldCell", "_newCell"];
    if (_oldCell isEqualTo _newCell) exitWith {};

    private _oldKey = str _oldCell;
    private _oldBucket = ATLAS_spatialGrid getOrDefault [_oldKey, createHashMap];
    private _oldList = _oldBucket getOrDefault [_entityType, []];
    _oldList deleteAt (_oldList find _entityId);

    private _newKey = str _newCell;
    private _newBucket = ATLAS_spatialGrid getOrDefault [_newKey, createHashMap];
    private _newList = _newBucket getOrDefault [_entityType, []];
    _newList pushBack _entityId;
    _newBucket set [_entityType, _newList];
    ATLAS_spatialGrid set [_newKey, _newBucket];

    ["atlas_grid_cellUpdated", [_oldCell, _newCell, _entityId, _entityType]] call CBA_fnc_localEvent;
};
```

**Performance comparison:**

| Scenario | ALiVE Distance Checks | ATLAS.OS Distance Checks | Reduction |
|---|---|---|---|
| 200 profiles, 10 players | 2,000 | ~30 | ~67x fewer |
| 500 profiles, 20 players | 10,000 | ~60 | ~167x fewer |
| 1000 profiles, 40 players | 40,000 | ~120 | ~333x fewer |

### 5.4 Profile ID Generation

```sqf
ATLAS_profileCounter = 0;
ATLAS_fnc_nextProfileID = {
    ATLAS_profileCounter = ATLAS_profileCounter + 1;
    format ["ATLAS_P_%1", ATLAS_profileCounter]
};
```

---

## 6. Scheduling Strategy: Scheduled vs Unscheduled

### 6.1 Decision Framework

```
┌─────────────────────────────────────────────────────────┐
│               SHOULD THIS RUN SCHEDULED?                │
│                                                         │
│  Does it process large batches (100+ items)?            │
│     YES ──► Does it need to yield to avoid frame lag?   │
│                YES ──► SCHEDULED (spawn) ✓              │
│                NO  ──► UNSCHEDULED (call) ✓             │
│     NO  ──► UNSCHEDULED (call) ✓                        │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Unscheduled Systems

| System | Why Unscheduled |
|---|---|
| Event handlers | Must react immediately |
| Spawn/despawn triggers | Need consistent state |
| Profile state updates | Must be atomic |
| CQB garrison management | Atomic spawning |
| Garbage collection | PFH budget, few per frame |
| Network sync | publicVariable runs unscheduled |
| UI/C2 updates | Immediate response to input |
| HC distribution | Group transfer must be atomic |

### 6.3 Scheduled Systems

| System | Why Scheduled |
|---|---|
| OPCOM strategic planning | Heavy: all objectives × forces |
| Bulk profile movement | Hundreds of virtual profiles |
| Persistence serialization | Large data conversion |
| Initial placement | Creates hundreds of profiles |
| Map sector analysis | One-time startup |

### 6.4 Hybrid: Event-Triggered Scheduled Work

```sqf
["ATLAS_objective_captured", {
    params ["_objectiveId", "_newOwner"];
    // Light unscheduled: update registry
    private _obj = ATLAS_objectiveRegistry get _objectiveId;
    _obj set ["owner", _newOwner];
    _obj set ["capturedAt", serverTime];
    // Heavy scheduled: OPCOM re-evaluation
    [_objectiveId, _newOwner] spawn ATLAS_fnc_OPCOM_reactToCapture;
}] call CBA_fnc_addEventHandler;
```

---

## 7. Event-Driven Architecture

### 7.1 Spawn/Despawn: Polling vs Event-Driven

```sqf
// ═══ ALiVE: Polls ALL profiles every 15s ═══
[] spawn {
    while {true} do {
        { /* check every profile vs every player */ } forEach ALIVE_allProfiles;
        sleep 15;
    };
};

// ═══ ATLAS.OS: Event-driven, only on player grid-cell change ═══
// 1. Detect cell changes (1Hz PFH)
[{
    {
        private _player = _x;
        private _pos = getPosATL _player;
        private _cell = [floor ((_pos#0) / ATLAS_GRID_SIZE), floor ((_pos#1) / ATLAS_GRID_SIZE)];
        private _lastCell = _player getVariable ["ATLAS_lastCell", [-1,-1]];
        if (!(_cell isEqualTo _lastCell)) then {
            _player setVariable ["ATLAS_lastCell", _cell];
            ["ATLAS_player_cellChanged", [_player, _cell, _lastCell]] call CBA_fnc_localEvent;
        };
    } forEach allPlayers;
}, 1] call CBA_fnc_addPerFrameHandler;

// 2. React: only check nearby cells
["ATLAS_player_cellChanged", {
    params ["_player", "_newCell", "_oldCell"];
    private _nearbyIDs = [getPosATL _player, ATLAS_SPAWN_RADIUS] call ATLAS_fnc_gridQuery;
    { /* spawn/despawn only candidates */ } forEach _nearbyIDs;
}] call CBA_fnc_addEventHandler;
```

### 7.2 Hysteresis

```sqf
#define ATLAS_SPAWN_RADIUS   1500
#define ATLAS_DESPAWN_RADIUS 1800   // 300m buffer prevents thrashing
```

---

## 8. Hosting Models & Headless Client Distribution

### 8.1 Supported Hosting Models

| Model | `isServer` | `isDedicated` | `hasInterface` | HC? |
|---|---|---|---|---|
| **Single Player** | true | false | true | No |
| **Listen Server** | true | false | true | Rare |
| **Dedicated Server** | true | true | false | Yes |
| **Dedicated + HC** | true (srv) | true | false (both) | Yes |

### 8.2 Locality Detection

```sqf
// atlas_core XEH_preInit.sqf
ATLAS_isServer       = isServer;
ATLAS_isDedicated    = isDedicated;
ATLAS_hasInterface   = hasInterface;
ATLAS_isHC           = !hasInterface && !isServer;
ATLAS_isSP           = !isMultiplayer;
ATLAS_isServerOrSP   = ATLAS_isServer || ATLAS_isSP;
ATLAS_hcAvailable    = false;
ATLAS_hcClients      = createHashMap;  // clientOwnerStr -> load HashMap
```

### 8.3 Execution Locality Rules

| System | Where It Runs | Why |
|---|---|---|
| Registries, spatial grid | Server | Authoritative data |
| OPCOM, LOGCOM, placement | Server | Strategic AI |
| Spawn/despawn decisions | Server | Server decides |
| Spawned AI simulation | Server OR HC | Load balanced |
| CQB garrison spawn | Server | Groups may transfer to HC |
| C2 tablet UI | Client (`hasInterface`) | Player UI |
| Persistence | Server | Server owns data |
| Extension (PostgreSQL) | Server | DLL on server |
| GC (deleteVehicle) | Server | Server-authoritative |

### 8.4 Headless Client AI Distribution

#### HC Registration

```sqf
// HC side: announce to server
if (ATLAS_isHC) then {
    ["ATLAS_hc_register", [clientOwner]] call CBA_fnc_serverEvent;
};

// Server side: register HC
["ATLAS_hc_register", {
    params ["_hcClientOwner"];
    ATLAS_hcAvailable = true;
    ATLAS_hcClients set [str _hcClientOwner, createHashMapFromArray [
        ["clientOwner", _hcClientOwner],
        ["groupCount", 0],
        ["unitCount", 0],
        ["lastUpdate", serverTime]
    ]];
    diag_log format ["[ATLAS][HC] Headless client registered: %1 (total: %2)",
        _hcClientOwner, count ATLAS_hcClients];
}] call CBA_fnc_addEventHandler;
```

#### Group Transfer to Least-Loaded HC

```sqf
ATLAS_fnc_hc_transferGroup = {
    params ["_group", "_profileId"];
    if (!ATLAS_hcAvailable || count ATLAS_hcClients == 0) exitWith {};

    // Find least-loaded HC
    private _bestHC = -1;
    private _bestLoad = 1e10;
    {
        private _load = _y get "unitCount";
        if (_load < _bestLoad) then {
            _bestLoad = _load;
            _bestHC = _y get "clientOwner";
        };
    } forEach ATLAS_hcClients;

    if (_bestHC < 0) exitWith {};

    // Transfer
    _group setGroupOwner _bestHC;

    // Update tracking
    private _hcData = ATLAS_hcClients get (str _bestHC);
    _hcData set ["groupCount", (_hcData get "groupCount") + 1];
    _hcData set ["unitCount", (_hcData get "unitCount") + count units _group];

    // Track in profile
    private _profile = ATLAS_profileRegistry get _profileId;
    _profile set ["_hcOwner", _bestHC];

    ["atlas_hc_groupTransferred", [_profileId, _bestHC, _group]] call CBA_fnc_localEvent;
};
```

#### Transfer Eligibility

```sqf
ATLAS_fnc_hc_shouldTransfer = {
    params ["_group", "_profile"];
    if (count ATLAS_hcClients == 0) exitWith { false };
    if (isPlayer leader _group) exitWith { false };      // Player-led stays
    if (_profile get "type" == "static") exitWith { false }; // Static weapons stay
    if (count units _group == 0) exitWith { false };

    // Don't transfer mid-combat near players
    private _nearPlayer = false;
    {
        if (leader _group distance _x < 300) exitWith { _nearPlayer = true };
    } forEach allPlayers;
    if (_nearPlayer && behaviour leader _group == "COMBAT") exitWith { false };

    true
};
```

#### Rebalancing (Every 30s)

```sqf
ATLAS_fnc_hc_rebalance = {
    if (count ATLAS_hcClients < 2) exitWith {};

    private _loads = [];
    { _loads pushBack [_y get "unitCount", _y get "clientOwner"] } forEach ATLAS_hcClients;
    _loads sort true;

    private _minLoad = (_loads#0)#0;
    private _maxLoad = (_loads#(count _loads - 1))#0;

    if (_maxLoad < _minLoad * 2) exitWith {}; // Balanced enough

    private _maxHC = (_loads#(count _loads - 1))#1;
    private _minHC = (_loads#0)#1;
    private _target = floor ((_maxLoad - _minLoad) / 2);
    private _transferred = 0;

    {
        private _profile = _y;
        if (_profile get "_hcOwner" == _maxHC && _profile get "state" == "spawned") then {
            private _group = _profile get "group";
            if (!isNull _group) then {
                _group setGroupOwner _minHC;
                _profile set ["_hcOwner", _minHC];
                _transferred = _transferred + count units _group;
            };
        };
        if (_transferred >= _target) exitWith {};
    } forEach ATLAS_profileRegistry;
};
```

#### HC Disconnect Handling

When an HC disconnects, Arma automatically reverts group ownership to the server. ATLAS updates tracking and redistributes to remaining HCs if available.

### 8.5 Network Synchronization

```sqf
// JIP: new player gets full state dump
["ATLAS_player_connected", {
    params ["_player"];
    private _objectiveStates = [];
    {
        _objectiveStates pushBack [_x, _y get "owner", _y get "state"];
    } forEach ATLAS_objectiveRegistry;
    ["ATLAS_sync_fullState", [_objectiveStates], _player] call CBA_fnc_targetEvent;
}] call CBA_fnc_addEventHandler;
```

---

## 9. Module Architecture — 16 PBOs

| # | PBO | Replaces (ALiVE) | Purpose |
|---|-----|-------------------|---------|
| 1 | `atlas_core` | sys_data, fnc_analysis, fnc_strategic, sys_marker | Foundation: spatial grid, map analysis, registries, event bus, markers, HC manager |
| 2 | `atlas_profile` | sys_profile, sys_profileHandler | Virtual unit lifecycle |
| 3 | `atlas_opcom` | mil_opcom, mil_command | AI commander (OPCOM + TACOM as CBA state machine) |
| 4 | `atlas_logistics` | mil_logistics, mil_convoy, sup_player_resupply | All logistics |
| 5 | `atlas_air` | mil_ato, air parts of sup_combatsupport | Air tasking: CAS, CAP, SEAD, transport |
| 6 | `atlas_cqb` | mil_CQB | Building garrisons |
| 7 | `atlas_placement` | mil_placement | Initial force placement |
| 8 | `atlas_civilian` | civ_population, civ_placement, amb_civ_* | Civilian simulation |
| 9 | `atlas_asymmetric` | mil_ied, mil_intelligence, insurgency | IEDs, cells, intel |
| 10 | `atlas_persist` | sys_data, sys_data_pns/couchdb, sys_player, sys_weather | Two-tier persistence |
| 11 | `atlas_c2` | C2ISTAR, sys_tasks, spotrep/sitrep/patrolrep | Command interface, tasks, reports |
| 12 | `atlas_support` | sup_combatsupport (arty), sup_multispawn, sup_group_manager | Artillery, insertion, squads |
| 13 | `atlas_gc` | sys_GC | Garbage collection |
| 14 | `atlas_ai` | sys_aiskill | AI skill management |
| 15 | `atlas_stats` | sys_statistics | Statistics |
| 16 | `atlas_admin` | sys_adminactions | Debug/admin |

### Consolidation Rationale

- **OPCOM + TACOM**: TACOM is OPCOM's execute phase. One CBA state machine, no IPC.
- **Logistics + Convoy + Player Resupply**: One pipeline for all supply chain operations.
- **ATO + air combat support**: All air ops in one module.
- **IED + Intel + Insurgency**: Tightly coupled domain.
- **C2ISTAR + Tasks + 3 report modules**: The tablet is the UI for all of them.
- **Core absorbs analysis + markers**: Foundational algorithms.
- **4 civilian modules → 1**: Population, placement, behaviors, interactions = one domain.

---

## 10. Module Specifications

### 10.1 `atlas_core`

**Purpose**: Spatial grid, map analysis, registries, event bus, markers, HC manager, locality detection.

**Events Published**: `core_ready`, `grid_cellUpdated`, `objective_registered`, `objective_stateChanged`, `player_cellChanged`, `player_connected/disconnected`, `marker_*`, `hc_registered/disconnected/groupTransferred`

**Dependencies**: CBA_A3 only | **Init Phase**: 0

**Data**: `ATLAS_spatialGrid`, `ATLAS_objectiveRegistry`, `ATLAS_sectorAnalysis`, `ATLAS_hcClients`

---

### 10.2 `atlas_profile`

**Purpose**: Virtual unit profiles. HashMap entities that spawn/despawn based on player proximity. HC transfer on spawn.

**Events Published**: `profile_created/destroyed/spawned/despawned/moved/damaged/orderReceived`

**Subscriptions**: `core_ready`, `player_cellChanged`, `opcom_orderIssued`

**Dependencies**: `atlas_core` | **Init Phase**: 1

**Data**: `ATLAS_profileRegistry` — HashMap of profile HashMaps (see §5.1)

---

### 10.3 `atlas_opcom`

**Purpose**: AI strategic + tactical commander. CBA state machine: ASSESS → PLAN → EXECUTE → MONITOR.

**Events Published**: `opcom_orderIssued/priorityChanged/phaseChanged/forceAllocated/reinforcementRequested/retreatOrdered`

**Subscriptions**: `core_ready`, `profile_created/destroyed/damaged`, `objective_stateChanged`, `logistics_delivered`, `asymmetric_cellDiscovered`, `persist_theaterStateReceived`

**Dependencies**: `atlas_core`, `atlas_profile` | **Init Phase**: 2

**Data**: `ATLAS_opcomRegistry` — opcom state + orders (see §10 in plan)

---

### 10.4 `atlas_logistics`

**Purpose**: Supply chain. AI resupply, convoys, player requests.

**Events Published**: `logistics_requestCreated/convoyDispatched/convoyArrived/delivered/convoyDestroyed/supplyLevelChanged`

**Subscriptions**: `opcom_reinforcementRequested/orderIssued`, `profile_destroyed`, `objective_stateChanged`, `persist_theaterStateReceived`

**Dependencies**: `atlas_core`, `atlas_profile` | **Init Phase**: 3

---

### 10.5 `atlas_air`

**Purpose**: Air tasking — CAS, CAP, SEAD, transport.

**Events Published**: `air_missionAssigned/missionComplete/aircraftLost/casOnStation/transportReady`

**Dependencies**: `atlas_core`, `atlas_profile` | **Init Phase**: 3

---

### 10.6 `atlas_cqb`

**Purpose**: Building garrisons. Event-driven, unscheduled.

**Events Published**: `cqb_garrisoned`, `cqb_cleared`

**Dependencies**: `atlas_core`, `atlas_profile` | **Init Phase**: 3

---

### 10.7 `atlas_placement`

**Purpose**: Initial force placement. Runs once at mission start.

**Events Published**: `placement_started`, `placement_complete`

**Dependencies**: `atlas_core`, `atlas_profile` | **Init Phase**: 2

---

### 10.8 `atlas_civilian`

**Purpose**: Ambient civilians. Agent pooling, CBA state machine behaviors, hostility, interactions.

**Events Published**: `civ_hostilityChanged/agentFleeing/agentQuestioned/populationChanged`

**Dependencies**: `atlas_core` | **Init Phase**: 3

---

### 10.9 `atlas_asymmetric`

**Purpose**: IEDs, VBIEDs, insurgent cells, recruitment, intel.

**Events Published**: `asymmetric_iedPlaced/iedDetonated/iedDisarmed/cellDiscovered/cellRecruited/intelGathered`

**Dependencies**: `atlas_core`, `atlas_profile`, `atlas_civilian` | **Init Phase**: 4

---

### 10.10 `atlas_persist`

**Purpose**: Two-tier persistence. PNS (local) + PostgreSQL (cross-server via DLL extension).

**Events Published**: `persist_saveStarted/saveComplete/loadComplete/theaterStateReceived/playerLoaded/playerSaved`

**Dependencies**: `atlas_core` | **Init Phase**: 1

**See §11 for full cross-server architecture.**

---

### 10.11 `atlas_c2`

**Purpose**: Tablet UI, task framework, SPOTREP/SITREP/PATROLREP.

**Events Published**: `c2_taskCreated/taskCompleted/casRequested/transportRequested/resupplyRequested/reportSubmitted`

**Runs on**: Client only (`hasInterface`) | **Init Phase**: 5

---

### 10.12 `atlas_support`

**Purpose**: Artillery, insertion points, squad management.

**Init Phase**: 4

---

### 10.13-10.16 Utility Modules

- **`atlas_gc`**: Event queue + PFH budget, 3 corpses/frame max
- **`atlas_ai`**: CBA Settings for AI skill, applies on `profile_spawned`
- **`atlas_stats`**: Event-driven tallying, persists to PNS + PostgreSQL
- **`atlas_admin`**: Debug menu, force save/load, teleport

All init Phase 5.

---

## 11. Cross-Server Persistence Architecture

### 11.1 Two-Tier Model

```
                    ┌──────────────────────────────────────────┐
                    │            PostgreSQL Database             │
                    │    (Shared Theater State - Cross-Server)   │
                    │                                            │
                    │  theater_state   - war status per server   │
                    │  faction_forces  - aggregate force levels   │
                    │  reinforcements  - shared reserve pool      │
                    │  cross_events    - inter-server event queue │
                    │  player_state    - roaming player data      │
                    │  objectives      - strategic objective state│
                    │  server_registry - active server heartbeats │
                    └──────┬────────────────────┬───────────────┘
                           │                    │
                  Extension DLL calls    Extension DLL calls
                           │                    │
                    ┌──────▼──────┐      ┌──────▼──────┐
                    │  Server 1   │      │  Server 2   │
                    │  (Altis)    │      │  (Stratis)  │
                    │  PNS: local │      │  PNS: local │
                    │  profiles,  │      │  profiles,  │
                    │  convoys,   │      │  convoys,   │
                    │  CQB, IEDs  │      │  CQB, IEDs  │
                    └─────────────┘      └─────────────┘
```

### 11.2 Data Distribution

| Data | PNS | PostgreSQL | Rationale |
|------|:---:|:----------:|-----------|
| Individual profiles | Yes | Aggregates | Map-specific |
| Force strength | — | Yes | Theater tracking |
| Objective state | Yes | Yes | Cross-server strategy |
| Reinforcement pool | — | Yes | Shared across servers |
| Convoys | Yes | — | Map-specific |
| Player state | Backup | Yes | Players switch servers |
| CQB garrisons | Yes | — | Map-specific |
| IEDs | Yes | Density only | Map-specific |
| Civilian hostility | Yes | Yes | Cross-server sentiment |
| Weather | Yes | — | Per-map |
| Statistics | Backup | Yes | Persistent |

### 11.3 Extension (DLL) Interface

**Extension**: `atlas_db` (C++ or Rust)

| Function | Purpose | Async? |
|----------|---------|--------|
| `INIT` | Connection pool setup | No |
| `HEARTBEAT` | Server registration | No |
| `THEATER_READ` | Read theater state | No |
| `THEATER_WRITE` | Write local theater data | Yes |
| `OBJECTIVES_SYNC` | Read/write objectives | No |
| `FORCES_WRITE` | Write force aggregates | Yes |
| `REINFORCEMENTS_READ` | Read reserve pool | No |
| `REINFORCEMENTS_DEDUCT` | Atomic pool deduction | No |
| `EVENTS_POLL` | Poll cross-server events | No |
| `EVENTS_PUSH` | Push event for other servers | Yes |
| `PLAYER_LOAD/SAVE` | Player state CRUD | No/Yes |
| `STATS_WRITE` | Write statistics | Yes |

### 11.4 Cross-Server Events

Polling every 30-60 seconds via extension.

| Event | Effect |
|-------|--------|
| `theater_objective_lost` | Other OPCOMs shift defensive |
| `theater_objective_captured` | Other OPCOMs go offensive |
| `theater_major_loss` | Triggers reinforcement allocation |
| `theater_reinforcement_dispatched` | Receiving server pool boost |
| `theater_supply_cut` | Theater-wide supply impact |
| `theater_air_superiority_changed` | ATO availability change |

### 11.5 PostgreSQL Schema

```sql
CREATE TABLE theater_state (
    server_id VARCHAR(64) PRIMARY KEY,
    map_name VARCHAR(64) NOT NULL,
    faction_data JSONB NOT NULL,
    objective_summary JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE faction_forces (
    faction VARCHAR(64) NOT NULL,
    server_id VARCHAR(64) NOT NULL,
    force_type VARCHAR(32) NOT NULL,
    count INTEGER NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (faction, server_id, force_type)
);

CREATE TABLE reinforcements (
    faction VARCHAR(64) PRIMARY KEY,
    infantry INTEGER DEFAULT 0,
    motorized INTEGER DEFAULT 0,
    mechanized INTEGER DEFAULT 0,
    armor INTEGER DEFAULT 0,
    air INTEGER DEFAULT 0,
    last_modified TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE player_state (
    player_uid VARCHAR(64) PRIMARY KEY,
    display_name VARCHAR(128),
    loadout TEXT,
    medical_state JSONB,
    position JSONB,
    last_server VARCHAR(64),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE server_registry (
    server_id VARCHAR(64) PRIMARY KEY,
    map_name VARCHAR(64),
    player_count INTEGER,
    last_heartbeat TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE objectives (
    objective_id VARCHAR(128) NOT NULL,
    server_id VARCHAR(64) NOT NULL,
    map_name VARCHAR(64) NOT NULL,
    owner VARCHAR(64),
    state VARCHAR(32),
    priority INTEGER,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (objective_id, server_id)
);

CREATE TABLE cross_events (
    id BIGSERIAL PRIMARY KEY,
    source_server VARCHAR(64) NOT NULL,
    event_type VARCHAR(128) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    consumed_by JSONB DEFAULT '[]'::jsonb
);
CREATE INDEX idx_cross_events_type ON cross_events(event_type);
CREATE INDEX idx_cross_events_created ON cross_events(created_at);
```

### 11.6 Graceful Degradation

If PostgreSQL connection fails:
- Mission continues with PNS-only persistence
- Cross-server events queue locally, flush on reconnect
- Player state falls back to PNS
- OPCOM uses local data only
- Extension retries every 60 seconds

---

## 12. Event Taxonomy

All events: `atlas_<domain>_<action>` (camelCase)

**Routing:**
- `CBA_fnc_localEvent` — server-only
- `CBA_fnc_globalEvent` — clients need it
- `CBA_fnc_serverEvent` — client → server
- `CBA_fnc_targetEvent` — server → specific client
- PostgreSQL `cross_events` — inter-server

**Complete list:**

| Domain | Events |
|--------|--------|
| **core** | `ready`, `grid_cellUpdated`, `objective_registered`, `objective_stateChanged`, `player_cellChanged`, `player_connected`, `player_disconnected`, `marker_*`, `hc_*` |
| **profile** | `created`, `destroyed`, `spawned`, `despawned`, `moved`, `damaged`, `orderReceived` |
| **opcom** | `orderIssued`, `priorityChanged`, `phaseChanged`, `forceAllocated`, `reinforcementRequested`, `retreatOrdered` |
| **logistics** | `requestCreated`, `convoyDispatched`, `convoyArrived`, `delivered`, `convoyDestroyed`, `supplyLevelChanged` |
| **air** | `missionAssigned`, `missionComplete`, `aircraftLost`, `casOnStation`, `transportReady` |
| **cqb** | `garrisoned`, `cleared` |
| **civ** | `hostilityChanged`, `agentFleeing`, `agentQuestioned`, `populationChanged` |
| **asymmetric** | `iedPlaced`, `iedDetonated`, `iedDisarmed`, `cellDiscovered`, `cellRecruited`, `intelGathered` |
| **persist** | `saveStarted`, `saveComplete`, `loadComplete`, `theaterStateReceived`, `playerLoaded`, `playerSaved` |
| **c2** | `taskCreated`, `taskCompleted`, `casRequested`, `transportRequested`, `resupplyRequested`, `reportSubmitted` |
| **support** | `fireMission`, `fireMissionComplete`, `insertionUsed` |
| **gc** | `cleaned` |

---

## 13. Module Initialization Order

```
Phase 0: atlas_core                                        [Server + Client]
         ├── Spatial grid, sector analysis, objective registry
         ├── Hosting model detection, HC manager ready
         └── Fires: atlas_core_ready

Phase 1: atlas_persist                                     [Server only]
         ├── Check save data → load PNS / connect PostgreSQL
         └── Fires: atlas_persist_loadComplete

Phase 2: atlas_profile + atlas_placement                   [Server only]
         ├── Profile registry, spawn/despawn handlers
         ├── If no persistence: create initial profiles
         └── Fires: atlas_placement_complete

Phase 3: atlas_opcom, atlas_logistics, atlas_air,          [Server only]
         atlas_cqb, atlas_civilian
         └── All init in parallel

Phase 4: atlas_asymmetric, atlas_support                   [Server only]
         └── After OPCOM and civilian

Phase 5: atlas_c2 (client), atlas_gc, atlas_ai,            [Mixed]
         atlas_stats, atlas_admin
```

Modules gate on CBA events, not polling:
```sqf
["atlas_placement_complete", {
    if (!ATLAS_isServerOrSP) exitWith {};
    call ATLAS_fnc_opcom_init;
}, true] call CBA_fnc_addEventHandlerArgs;
```

---

## 14. PBO Directory Structure

```
@ATLAS_OS/
├── addons/
│   ├── atlas_core/          → fn_init, fn_grid*, fn_sector*, fn_cluster*, fn_objective*, fn_hc*, fn_log, fn_moduleRegister
│   ├── atlas_profile/       → fn_init, fn_create, fn_destroy, fn_spawn, fn_despawn, fn_moveTo, fn_virtualMove, fn_syncFromSpawned, fn_serialize, fn_deserialize, fn_nextId
│   ├── atlas_opcom/         → fn_init, fn_createSM, fn_assess, fn_plan, fn_execute, fn_monitor, fn_scoreObjective, fn_allocateForces, fn_handle*, fn_generateOrder, fn_insurgency*
│   ├── atlas_logistics/     → fn_init, fn_processRequest, fn_routeConvoy, fn_dispatchConvoy, fn_playerRequest, fn_supplyCheck, fn_reinforcementPool
│   ├── atlas_air/           → fn_init, fn_queueMission, fn_assignAircraft, fn_monitorMission, fn_cas, fn_cap, fn_transport, fn_sead
│   ├── atlas_cqb/           → fn_init, fn_scanBuildings, fn_spawnGarrison, fn_despawnGarrison, fn_cachePositions
│   ├── atlas_placement/     → fn_init, fn_parseOrbat, fn_distributeForces, fn_createProfiles
│   ├── atlas_civilian/      → fn_init, fn_computeDensity, fn_spawnAgent, fn_returnAgent, fn_behaviorFSM, fn_interact, fn_hostility
│   ├── atlas_asymmetric/    → fn_init, fn_placeIED, fn_detonateIED, fn_disarmIED, fn_cellManage, fn_cellRecruit, fn_intelProcess
│   ├── atlas_persist/       → fn_init, fn_savePNS, fn_loadPNS, fn_serialize, fn_deserialize, fn_extension*, fn_theater*, fn_player*, fn_saveAll, fn_loadAll
│   ├── atlas_c2/            → fn_init, fn_tablet*, fn_task*, fn_report*, fn_request*
│   ├── atlas_support/       → fn_init, fn_fireMission, fn_insertionManager, fn_groupManager
│   ├── atlas_gc/            → fn_init, fn_enqueue, fn_processQueue
│   ├── atlas_ai/            → fn_init, fn_applySkill, fn_settingsInit
│   ├── atlas_stats/         → fn_init, fn_recordEvent, fn_serialize
│   └── atlas_admin/         → fn_init, fn_debugMenu, fn_teleport, fn_forceSpawn, fn_forceSave
├── extensions/
│   └── atlas_db/            → C++/Rust PostgreSQL bridge DLL
├── mod.cpp
├── meta.cpp
└── README.md
```

---

## 15. Performance Projections

### Algorithmic Improvements

| System | ALiVE | ATLAS.OS | Complexity Change |
|---|---|---|---|
| Data Access | Parallel-array hash (linear) | Native HashMap | **O(n) → O(1)** |
| Profile Proximity | All × all players | Spatial grid: nearby cells | **O(n×m) → O(m×k)** |
| OPCOM Decisions | Full recalculation | Dirty-flag skip | **O(n) → O(dirty)** |
| Spawn/Despawn | Timer polling | Event-driven | **Polling → event** |
| Civilian Agents | Create/destroy | Object pooling | **Fewer engine calls** |
| Persistence | Serialize all | Incremental dirty-save | **O(n) → O(dirty)** |
| GC | Scheduled bulk loop | PFH budget queue | **Bounded per-frame** |
| AI Computation | All on server | HC distribution | **Linear with HC count** |

### HC Distribution Impact

| Setup | Server AI Load | Expected Throughput |
|---|---|---|
| No HC | 100% | Baseline |
| 1 HC | ~50% | ~2x |
| 2 HCs | ~33% | ~3x |
| 3 HCs | ~25% | ~4x |

*All projections require validation through benchmarking.*

---

## 16. Key Architectural Decisions

1. **OPCOM + TACOM merged** — Eliminates IPC, one CBA state machine.
2. **`atlas_asymmetric` separate** — IED/intel mechanics distinct from strategy. OPCOM publishes, asymmetric implements.
3. **Two-tier persistence** — PNS fast/local, PostgreSQL cross-server. Graceful degradation if DB fails.
4. **Polling for cross-server events** — Arma extensions can't receive push. 30-60s adequate for strategic events.
5. **16 PBOs** — Balanced cohesion. Optional exclusion. HEMTT-friendly.
6. **HC distribution in core** — Cross-cutting. All spawning modules benefit automatically.
7. **All hosting models from day one** — Every module checks `ATLAS_isServerOrSP`. No dedicated-only surprises.

---

## 17. Coding Standards — No God Objects

### 17.1 Hard Rules

These rules exist specifically to prevent ALiVE's god-object anti-patterns from recurring. They are non-negotiable.

| Rule | Limit | ALiVE Violation Example |
|------|-------|------------------------|
| **Max lines per `.sqf` file** | **200 lines** (excluding comments/blank lines) | `fnc_OPCOM.sqf` = 4,500+ lines |
| **Max function parameters** | **6** (use a HashMap for more) | ALiVE routinely passes 10+ positional params |
| **No method-dispatch switches** | Zero `switch (_operation)` god-functions | Every major ALiVE module uses this pattern |
| **One function, one file** | Every `fn_*.sqf` contains exactly one function | ALiVE nests helpers inside monolithic functions |
| **No direct cross-module data access** | Modules communicate via events only | ALiVE's OPCOM directly reads profile internals |
| **No global variables beyond registries** | Only `ATLAS_*Registry`, `ATLAS_spatialGrid`, `ATLAS_is*` flags | ALiVE has 200+ `ALIVE_*` globals |
| **Function naming** | `ATLAS_fnc_<module>_<verb><Noun>` | Clear, discoverable, grep-friendly |

### 17.2 Function Design Principles

**Single Responsibility**: Each function does exactly one thing. If you can't describe what it does in one sentence without "and", split it.

```sqf
// BAD — does two things
ATLAS_fnc_opcom_assessAndPlan = { /* scores objectives AND allocates forces */ };

// GOOD — separate concerns
ATLAS_fnc_opcom_scoreObjective = { /* scores one objective */ };
ATLAS_fnc_opcom_allocateForces = { /* allocates forces based on scored objectives */ };
```

**Compose, Don't Nest**: Complex operations are pipelines of small functions, not nested logic.

```sqf
// BAD — monolithic
ATLAS_fnc_opcom_assess = {
    // 500 lines of inline force counting, threat assessment, terrain analysis...
};

// GOOD — composed pipeline
ATLAS_fnc_opcom_assess = {
    params ["_opcom"];
    private _forces = [_opcom] call ATLAS_fnc_opcom_countForces;
    private _threats = [_opcom] call ATLAS_fnc_opcom_assessThreats;
    private _terrain = [_opcom] call ATLAS_fnc_opcom_assessTerrain;
    private _supply = [_opcom] call ATLAS_fnc_opcom_assessSupply;
    [_opcom, _forces, _threats, _terrain, _supply] call ATLAS_fnc_opcom_synthesizeAssessment;
};
```

**Data In, Data Out**: Functions take parameters and return values. Avoid side effects where possible. When side effects are necessary (setting registry data, firing events), do them at the end.

```sqf
// BAD — hidden side effects throughout
ATLAS_fnc_logistics_processRequest = {
    // ... modifies globals mid-function, fires events in the middle ...
};

// GOOD — pure computation, then effects
ATLAS_fnc_logistics_processRequest = {
    params ["_request"];
    // 1. Pure computation
    private _route = [_request] call ATLAS_fnc_logistics_calculateRoute;
    private _convoy = [_request, _route] call ATLAS_fnc_logistics_buildConvoy;
    // 2. Effects at the end
    ATLAS_logisticsRegistry set [_convoy get "id", _convoy];
    ["atlas_logistics_convoyDispatched", [_convoy]] call CBA_fnc_localEvent;
    _convoy
};
```

### 17.3 File Organization Pattern

Every module follows this exact structure:

```
atlas_<module>/
  config.cpp              # CfgPatches, required addons
  CfgEventHandlers.hpp    # XEH registration
  CfgFunctions.hpp        # Function registration
  XEH_preInit.sqf         # Registry creation, event handler registration
  XEH_postInit.sqf        # Initialization gate (wait for dependencies)
  XEH_postServerInit.sqf  # Server-only init (optional)
  fnc/
    fn_init.sqf           # Module initialization logic
    fn_<verb><Noun>.sqf   # One function per file
    ...
```

### 17.4 HashMap Contract Pattern

Every data structure has a documented "contract" — a creation function that defines the shape:

```sqf
// fn_createProfile.sqf — this IS the schema documentation
ATLAS_fnc_profile_create = {
    params [
        "_type",        // "infantry"|"motorized"|"mechanized"|"armor"|"air"|"naval"|"static"
        "_unitClasses", // Array<classname>
        "_side",        // side
        "_faction",     // string
        "_pos",         // [x,y,z]
        ["_vehicleType", ""],     // classname or ""
        ["_dir", 0]               // 0-360
    ];

    private _id = call ATLAS_fnc_profile_nextId;
    private _profile = createHashMapFromArray [
        ["id", _id],
        ["type", _type],
        // ... every field with its default value ...
    ];

    // Register
    ATLAS_profileRegistry set [_id, _profile];
    [_id, "profiles", _pos] call ATLAS_fnc_core_gridInsert;

    // Event
    ["atlas_profile_created", [_id, _profile]] call CBA_fnc_localEvent;

    _profile
};
```

An agent implementing any function that reads a profile can look at `fn_create.sqf` to know exactly what fields exist.

---

## 18. Detailed Module Internal Breakdowns

Each section below specifies every function an implementing agent needs to write, with its signature, responsibility, and expected size.

---

### 18.1 `atlas_core` — Internal Structure

```
atlas_core/fnc/
  fn_init.sqf                    # Initialize all registries, spatial grid, detect hosting model
  fn_gridInsert.sqf              # Insert entity into spatial grid
  fn_gridRemove.sqf              # Remove entity from spatial grid
  fn_gridQuery.sqf               # Query entities near position by type
  fn_gridMove.sqf                # Move entity between grid cells
  fn_sectorAnalyze.sqf           # Analyze one sector cell (terrain, roads, buildings)
  fn_sectorAnalyzeAll.sqf        # Scheduled: iterate all cells, call fn_sectorAnalyze each
  fn_sectorGetTerrain.sqf        # Classify terrain type at position
  fn_sectorGetBuildings.sqf      # Get building positions in a sector cell
  fn_sectorGetRoads.sqf          # Get road segments in a sector cell
  fn_clusterDetect.sqf           # Find clusters of buildings/objects on map
  fn_clusterFindCenter.sqf       # Calculate center of a cluster
  fn_objectiveCreate.sqf         # Create objective HashMap, register in registry + grid
  fn_objectiveUpdate.sqf         # Update objective state, fire stateChanged event
  fn_objectiveGetNearest.sqf     # Find nearest objective to a position
  fn_objectiveGetByOwner.sqf     # Get all objectives owned by a side
  fn_playerTrackCells.sqf        # PFH: detect player grid-cell changes, fire events
  fn_hcRegister.sqf              # Handle HC registration event
  fn_hcTransferGroup.sqf         # Transfer group to least-loaded HC
  fn_hcShouldTransfer.sqf        # Check if group is eligible for HC transfer
  fn_hcRebalance.sqf             # Rebalance groups across HCs
  fn_hcUpdateLoad.sqf            # Recalculate unit counts per HC
  fn_log.sqf                     # Structured logging: [ATLAS][MODULE] message
  fn_moduleRegister.sqf          # Register a module in ATLAS_moduleRegistry
  fn_markerCreate.sqf            # Create map marker with persistence tracking
  fn_markerUpdate.sqf            # Update marker properties
  fn_markerDelete.sqf            # Delete marker
```

**Function signatures:**

```sqf
// fn_gridInsert.sqf
// Params: [entityId (string), entityType (string), pos (array)]
// Returns: cell ([cx, cy])

// fn_gridQuery.sqf
// Params: [pos (array), radius (number), entityType (string, default "profiles")]
// Returns: Array<entityId>

// fn_gridMove.sqf
// Params: [entityId (string), entityType (string), oldCell (array), newCell (array)]
// Returns: nothing. Fires atlas_grid_cellUpdated.

// fn_sectorAnalyze.sqf
// Params: [cellKey (string), cellCenter ([x,y,z])]
// Returns: sectorHashMap { terrain, elevation, roadCount, buildingCount, buildingPositions, dominantHeight, nearestRoad }

// fn_objectiveCreate.sqf
// Params: [pos, type ("strategic"|"tactical"|"civilian"), size, ownerSide]
// Returns: objectiveHashMap (registered in ATLAS_objectiveRegistry)

// fn_hcTransferGroup.sqf
// Params: [group, profileId (string)]
// Returns: boolean (true if transferred)

// fn_playerTrackCells.sqf
// This is a PFH (no params). Runs every 1 second.
// For each player, checks if grid cell changed. Fires atlas_player_cellChanged.
```

---

### 18.2 `atlas_profile` — Internal Structure

```
atlas_profile/fnc/
  fn_init.sqf                    # Register event handlers, start virtual movement PFH
  fn_create.sqf                  # Create profile HashMap, register in grid + registry
  fn_destroy.sqf                 # Remove profile from registry + grid, fire destroyed event
  fn_spawn.sqf                   # Materialize virtual profile into real Arma units
  fn_despawn.sqf                 # Virtualize real units back to profile data
  fn_syncFromSpawned.sqf         # Copy current unit state (pos, damage, ammo) back to profile
  fn_moveTo.sqf                  # Set waypoints on a profile (virtual or spawned)
  fn_virtualMove.sqf             # PFH/scheduled: advance virtual profiles along waypoints
  fn_virtualMoveStep.sqf         # Move one profile one step along its route
  fn_applyWaypoints.sqf          # Apply profile waypoints to a spawned group
  fn_applyGroupBehavior.sqf      # Apply groupData (behaviour, speed, formation) to group
  fn_getById.sqf                 # Lookup profile by ID (wrapper around registry get)
  fn_getInArea.sqf               # Get profiles near position using spatial grid
  fn_getBySide.sqf               # Get all profiles for a side (iterate registry)
  fn_getByObjective.sqf          # Get profiles assigned to an objective
  fn_serialize.sqf               # Convert profile HashMap to serializable array
  fn_deserialize.sqf             # Restore profile HashMap from serialized array
  fn_nextId.sqf                  # Generate next monotonic profile ID
  fn_handleSpawnDespawn.sqf      # Event handler for player_cellChanged: evaluate spawn/despawn
  fn_spawnGroup.sqf              # Create the actual group + units from classnames
  fn_spawnVehicle.sqf            # Create vehicle and assign crew from profile
  fn_calculateDamage.sqf         # Apply stored damage state to spawned units
  fn_calculateAmmo.sqf           # Apply stored ammo level to spawned units
```

**Key function signatures:**

```sqf
// fn_create.sqf
// Params: [type, unitClasses, side, faction, pos, vehicleType (default ""), dir (default 0)]
// Returns: profile HashMap
// Effects: registers in ATLAS_profileRegistry, inserts in grid, fires atlas_profile_created

// fn_spawn.sqf
// Params: [profileIdOrHashMap]
// Returns: group
// Effects: creates units, sets state to "spawned", calls fn_hcTransferGroup,
//          fires atlas_profile_spawned

// fn_despawn.sqf
// Params: [profileIdOrHashMap]
// Returns: nothing
// Effects: calls fn_syncFromSpawned, deletes units, sets state to "virtual",
//          fires atlas_profile_despawned

// fn_syncFromSpawned.sqf
// Params: [profile HashMap]
// Returns: nothing
// Effects: reads pos, damage, ammo, fuel, formation from spawned group back into HashMap

// fn_handleSpawnDespawn.sqf
// This is the atlas_player_cellChanged event handler.
// Params: [player, newCell, oldCell]
// Logic: query grid for profiles in spawn radius around player.
//        Spawn virtual profiles within ATLAS_SPAWN_RADIUS.
//        Despawn spawned profiles beyond ATLAS_DESPAWN_RADIUS of ALL players.

// fn_virtualMoveStep.sqf
// Params: [profile HashMap, deltaTime (seconds)]
// Returns: boolean (true if waypoint reached)
// Logic: move profile position toward next waypoint at speed appropriate for type.
//        Update grid cell if changed. Fire atlas_profile_moved.
```

---

### 18.3 `atlas_opcom` — Internal Structure

This is the most complex module. ALiVE's OPCOM is a 140KB monolith. ATLAS breaks it into ~20 focused functions.

```
atlas_opcom/fnc/
  fn_init.sqf                    # Create OPCOM instance, start state machine
  fn_createInstance.sqf          # Build opcom HashMap with initial state
  fn_createStateMachine.sqf      # Build CBA state machine with 4 phases

  # === ASSESS PHASE (scheduled) ===
  fn_assess.sqf                  # Orchestrate assessment — calls sub-functions
  fn_countForces.sqf             # Count friendly forces by type (infantry, armor, etc.)
  fn_assessThreats.sqf           # Estimate enemy force strength per objective
  fn_assessSupply.sqf            # Calculate supply levels across controlled objectives
  fn_assessTerrain.sqf           # Factor terrain advantage into assessment

  # === PLAN PHASE (scheduled) ===
  fn_plan.sqf                    # Orchestrate planning — score, prioritize, allocate
  fn_scoreObjective.sqf          # Score ONE objective: military value × feasibility
  fn_scoreMilitaryValue.sqf      # Sub-score: strategic importance (size, terrain, resources)
  fn_scoreFeasibility.sqf        # Sub-score: distance, force ratio, supply access
  fn_prioritizeObjectives.sqf    # Sort objectives by score, apply operational tempo filter
  fn_allocateForces.sqf          # Assign profiles to objectives by capability match
  fn_matchForceToObjective.sqf   # Score how well a profile fits an objective's needs

  # === EXECUTE PHASE (unscheduled) ===
  fn_execute.sqf                 # Issue orders for all pending allocations
  fn_generateOrder.sqf           # Create order HashMap for a profile → objective assignment
  fn_issueOrder.sqf              # Apply order to profile, fire atlas_opcom_orderIssued

  # === MONITOR PHASE (unscheduled PFH) ===
  fn_monitor.sqf                 # Check order completion/failure, trigger re-assessment
  fn_checkOrderStatus.sqf        # Evaluate one order: complete? failed? stalled?
  fn_handleOrderComplete.sqf     # Clean up completed order, update objective state
  fn_handleOrderFailed.sqf       # Handle failure: retreat, reassign, request reinforcement

  # === EVENT REACTIONS (unscheduled) ===
  fn_handleCapture.sqf           # React to atlas_objective_stateChanged (capture)
  fn_handleLoss.sqf              # React to objective lost — defensive posture shift
  fn_handleProfileDestroyed.sqf  # React to atlas_profile_destroyed — update force estimates
  fn_handleTheaterUpdate.sqf     # React to atlas_persist_theaterStateReceived

  # === INSURGENCY MODE ===
  fn_insurgencyInit.sqf          # Initialize insurgency-specific state
  fn_insurgencyRecruit.sqf       # Cell recruitment logic (driven by civilian hostility)
  fn_insurgencyPlot.sqf          # Plan insurgent operations (IED placement, ambushes)
  fn_insurgencySelectTarget.sqf  # Pick targets for insurgent attacks
```

**OPCOM State Machine Definition:**

```sqf
// fn_createStateMachine.sqf
ATLAS_fnc_opcom_createStateMachine = {
    params ["_opcom"];

    private _sm = [_opcom, true] call CBA_statemachine_fnc_create; // true = unscheduled transitions

    // States
    private _assess  = [_sm, {}, {}, ATLAS_fnc_opcom_assess,  "ASSESS"]  call CBA_statemachine_fnc_addState;
    private _plan    = [_sm, {}, {}, ATLAS_fnc_opcom_plan,    "PLAN"]    call CBA_statemachine_fnc_addState;
    private _execute = [_sm, {}, {}, ATLAS_fnc_opcom_execute, "EXECUTE"] call CBA_statemachine_fnc_addState;
    private _monitor = [_sm, {}, {}, ATLAS_fnc_opcom_monitor, "MONITOR"] call CBA_statemachine_fnc_addState;

    // Transitions: each phase completes by setting a flag
    [_sm, _assess,  _plan,    { _this getVariable ["ATLAS_assessDone", false]  }] call CBA_statemachine_fnc_addTransition;
    [_sm, _plan,    _execute, { _this getVariable ["ATLAS_planDone", false]    }] call CBA_statemachine_fnc_addTransition;
    [_sm, _execute, _monitor, { _this getVariable ["ATLAS_executeDone", false] }] call CBA_statemachine_fnc_addTransition;
    [_sm, _monitor, _assess,  { _this getVariable ["ATLAS_monitorDone", false] }] call CBA_statemachine_fnc_addTransition;

    _opcom set ["stateMachine", _sm];
    _sm
};
```

**Scoring pipeline (how `fn_plan.sqf` works):**

```sqf
// fn_plan.sqf — orchestrator, not monolith
ATLAS_fnc_opcom_plan = {
    params ["_opcom"];

    private _objectives = _opcom get "objectives";
    private _dirtyOnly = true;

    // 1. Score objectives (only dirty ones unless first cycle)
    {
        private _obj = ATLAS_objectiveRegistry get _x;
        if (!_dirtyOnly || {_obj getOrDefault ["_dirty", true]}) then {
            private _milValue = [_obj] call ATLAS_fnc_opcom_scoreMilitaryValue;
            private _feasibility = [_obj, _opcom] call ATLAS_fnc_opcom_scoreFeasibility;
            _obj set ["_score", _milValue * 0.6 + _feasibility * 0.4];
            _obj set ["_dirty", false];
        };
    } forEach _objectives;

    // 2. Prioritize
    private _prioritized = [_opcom] call ATLAS_fnc_opcom_prioritizeObjectives;

    // 3. Allocate forces to top-priority objectives
    [_opcom, _prioritized] call ATLAS_fnc_opcom_allocateForces;

    _opcom setVariable ["ATLAS_planDone", true];
};
```

---

### 18.4 `atlas_logistics` — Internal Structure

```
atlas_logistics/fnc/
  fn_init.sqf                    # Register event handlers, initialize registries
  fn_createRequest.sqf           # Build logistics request HashMap
  fn_processRequest.sqf          # Evaluate request, decide fulfillment method
  fn_findSupplySource.sqf        # Find nearest depot/base that can fulfill request
  fn_calculateRoute.sqf          # Pathfind along road network from source to destination
  fn_buildConvoy.sqf             # Create convoy profiles (trucks, escort) for a request
  fn_dispatchConvoy.sqf          # Register convoy, assign waypoints, fire event
  fn_monitorConvoys.sqf          # PFH: check convoy arrival/destruction
  fn_checkConvoyArrival.sqf      # Has convoy reached destination?
  fn_deliverSupplies.sqf         # Apply supplies to destination: ammo, fuel, reinforcements
  fn_destroyConvoy.sqf           # Handle convoy loss: clean up, notify OPCOM
  fn_playerRequest.sqf           # Handle player resupply request from atlas_c2
  fn_reinforcementPoolRead.sqf   # Read available reinforcements (local or PostgreSQL)
  fn_reinforcementPoolDeduct.sqf # Deduct from pool (atomic on PostgreSQL)
  fn_assessAmmoLevel.sqf         # Calculate aggregate ammo level for profiles at objective
  fn_assessFuelLevel.sqf         # Calculate aggregate fuel level for profiles at objective
  fn_handleOpcomOrder.sqf        # Event handler: check if ordered forces need resupply first
  fn_handleProfileDestroyed.sqf  # Event handler: was destroyed profile a convoy?
  fn_supplyDepotCreate.sqf       # Register a supply depot (position + capacity)
  fn_supplyDepotGetNearest.sqf   # Find nearest depot to a position
```

**Function signatures:**

```sqf
// fn_calculateRoute.sqf
// Params: [startPos ([x,y,z]), endPos ([x,y,z])]
// Returns: Array<[x,y,z]> — waypoints along road network
// Uses: nearRoads, road segments. Falls back to direct route if no roads.

// fn_buildConvoy.sqf
// Params: [request HashMap, route Array, sourceDepot HashMap]
// Returns: convoy HashMap
// Logic: create 1-3 truck profiles + 0-1 escort profiles via atlas_profile fn_create

// fn_deliverSupplies.sqf
// Params: [convoy HashMap, destinationObjective HashMap]
// Returns: nothing
// Effects: increase ammo/fuel on profiles at destination, add reinforcement profiles,
//          fire atlas_logistics_delivered

// fn_reinforcementPoolDeduct.sqf
// Params: [faction (string), forceType (string), count (number)]
// Returns: boolean (true if pool had enough)
// Effects: if PostgreSQL connected, uses atomic REINFORCEMENTS_DEDUCT.
//          Otherwise uses local ATLAS_reinforcementPool HashMap.
```

---

### 18.5 `atlas_air` — Internal Structure

```
atlas_air/fnc/
  fn_init.sqf                    # Register handlers, initialize ATO queue
  fn_queueMission.sqf            # Add mission to ATO queue with priority
  fn_processQueue.sqf            # PFH: assign aircraft to highest-priority queued mission
  fn_findAvailableAircraft.sqf   # Query profiles for available aircraft by type
  fn_assignAircraft.sqf          # Assign aircraft profile to mission, update status
  fn_monitorMissions.sqf         # PFH: check active mission status
  fn_casExecute.sqf              # CAS behavior: fly to target, engage, RTB
  fn_casSetupAttackRun.sqf       # Calculate attack vector for CAS run
  fn_capExecute.sqf              # CAP behavior: orbit area, engage threats
  fn_capSetupOrbit.sqf           # Calculate orbit parameters (center, radius, altitude)
  fn_seadExecute.sqf             # SEAD behavior: target air defenses
  fn_transportExecute.sqf        # Transport: fly to pickup, load, fly to dropoff, unload
  fn_transportPickup.sqf         # Handle troop loading at pickup zone
  fn_transportDropoff.sqf        # Handle troop unloading at dropoff zone
  fn_missionComplete.sqf         # Clean up completed mission, return aircraft to pool
  fn_missionFailed.sqf           # Handle aircraft loss during mission
  fn_handlePlayerCAS.sqf         # Event handler: player CAS request from atlas_c2
  fn_handlePlayerTransport.sqf   # Event handler: player transport request
  fn_handleOpcomRequest.sqf      # Event handler: OPCOM air support request
  fn_rtb.sqf                     # Return to base behavior for aircraft
```

---

### 18.6 `atlas_civilian` — Internal Structure

ALiVE splits civilians across 4 modules with 20+ behavior functions. ATLAS consolidates but keeps behaviors as separate composable functions.

```
atlas_civilian/fnc/
  fn_init.sqf                    # Compute density, register handlers, start PFHs
  fn_computeDensity.sqf          # Scheduled: calculate population density per grid cell

  # === AGENT POOL ===
  fn_poolGet.sqf                 # Get agent from pool (or create new if empty)
  fn_poolReturn.sqf              # Return agent to pool (disable sim, move to [0,0,0])
  fn_poolPrewarm.sqf             # Pre-create N agents at startup

  # === SPAWN/DESPAWN ===
  fn_spawnForCell.sqf            # Spawn civilians in a grid cell (called on player proximity)
  fn_despawnForCell.sqf          # Return all agents in a cell to pool
  fn_handlePlayerCell.sqf        # Event handler: atlas_player_cellChanged → spawn/despawn

  # === BEHAVIOR STATE MACHINE ===
  fn_behaviorInit.sqf            # Create CBA state machine for one civilian
  fn_behaviorIdle.sqf            # Idle: stand/sit at position, occasionally look around
  fn_behaviorWalk.sqf            # Walk to random nearby position
  fn_behaviorDrive.sqf           # Drive vehicle along road
  fn_behaviorFlee.sqf            # Flee from threat (gunfire, explosion, military)
  fn_behaviorCower.sqf           # Cower in place (under direct threat)
  fn_behaviorGather.sqf          # Gather with other civilians (market, meeting)
  fn_behaviorTransition.sqf      # Evaluate conditions and pick next behavior

  # === HOSTILITY ===
  fn_hostilityUpdate.sqf         # Adjust hostility for a cell based on events
  fn_hostilityGet.sqf            # Get hostility level toward a faction in a cell
  fn_hostilityApplyEvent.sqf     # Process specific event (civilian killed, IED, etc.)

  # === INTERACTION ===
  fn_interactInit.sqf            # Add ACE/action menu interactions to spawned civilians
  fn_interactQuestion.sqf        # Player questions civilian — roll for intel
  fn_interactDetain.sqf          # Player detains civilian
  fn_interactSearch.sqf          # Player searches civilian for intel/weapons
  fn_interactRelease.sqf         # Release detained civilian

  # === TRAFFIC ===
  fn_trafficSpawn.sqf            # Spawn civilian vehicle on road
  fn_trafficRoute.sqf            # Generate random A-to-B road route
  fn_trafficDespawn.sqf          # Return vehicle + driver to pool
```

**Behavior state machine:**

```sqf
// fn_behaviorInit.sqf — creates per-agent CBA state machine
ATLAS_fnc_civ_behaviorInit = {
    params ["_agent"];

    private _sm = [_agent, false] call CBA_statemachine_fnc_create;

    private _idle   = [_sm, {}, {}, ATLAS_fnc_civ_behaviorIdle,   "idle"]   call CBA_statemachine_fnc_addState;
    private _walk   = [_sm, {}, {}, ATLAS_fnc_civ_behaviorWalk,   "walk"]   call CBA_statemachine_fnc_addState;
    private _drive  = [_sm, {}, {}, ATLAS_fnc_civ_behaviorDrive,  "drive"]  call CBA_statemachine_fnc_addState;
    private _flee   = [_sm, {}, {}, ATLAS_fnc_civ_behaviorFlee,   "flee"]   call CBA_statemachine_fnc_addState;
    private _cower  = [_sm, {}, {}, ATLAS_fnc_civ_behaviorCower,  "cower"]  call CBA_statemachine_fnc_addState;
    private _gather = [_sm, {}, {}, ATLAS_fnc_civ_behaviorGather, "gather"] call CBA_statemachine_fnc_addState;

    // Transitions — any state can flee on threat
    {
        [_sm, _x, _flee, {
            _this getVariable ["ATLAS_civ_threatNear", false]
        }] call CBA_statemachine_fnc_addTransition;
    } forEach [_idle, _walk, _drive, _gather];

    // Flee → cower if threat is very close
    [_sm, _flee, _cower, {
        _this getVariable ["ATLAS_civ_threatDist", 999] < 30
    }] call CBA_statemachine_fnc_addTransition;

    // Cower/flee → idle when threat passes
    {
        [_sm, _x, _idle, {
            !(_this getVariable ["ATLAS_civ_threatNear", false])
        }] call CBA_statemachine_fnc_addTransition;
    } forEach [_flee, _cower];

    // Idle → walk/drive/gather (random selection via fn_behaviorTransition)
    [_sm, _idle, _walk, {
        _this getVariable ["ATLAS_civ_nextBehavior", ""] == "walk"
    }] call CBA_statemachine_fnc_addTransition;

    _sm
};
```

---

### 18.7 `atlas_asymmetric` — Internal Structure

```
atlas_asymmetric/fnc/
  fn_init.sqf                    # Initialize cell registry, register handlers

  # === IED MANAGEMENT ===
  fn_iedCreate.sqf               # Create IED HashMap, register in grid
  fn_iedPlace.sqf                # Physically place IED object at position
  fn_iedArm.sqf                  # Arm IED (make it active/dangerous)
  fn_iedDetonate.sqf             # Trigger IED explosion, calculate casualties
  fn_iedDisarm.sqf               # Player disarms IED
  fn_iedDetect.sqf               # Detection check (player skill, equipment, proximity)
  fn_iedSelectPosition.sqf       # Pick IED placement: road intersections, chokepoints
  fn_iedHandleProximity.sqf      # Event handler: player near IED → detonation check

  # === VBIED / SUICIDE BOMBER ===
  fn_vbiedCreate.sqf             # Create vehicle-borne IED profile
  fn_vbiedDispatch.sqf           # Send VBIED toward target
  fn_bomberCreate.sqf            # Create suicide bomber agent
  fn_bomberDispatch.sqf          # Send bomber toward target area

  # === INSURGENT CELLS ===
  fn_cellCreate.sqf              # Create insurgent cell HashMap
  fn_cellRecruit.sqf             # Increase cell strength based on hostility
  fn_cellAttrition.sqf           # Decrease cell strength from losses
  fn_cellDiscoveryCheck.sqf      # Check if accumulated intel reveals a cell
  fn_cellGetActive.sqf           # Get cells with enough strength to operate
  fn_cellSelectOperation.sqf     # Pick operation type for a cell (IED, ambush, VBIED)

  # === INTEL SYSTEM ===
  fn_intelProcess.sqf            # Process intel from various sources
  fn_intelFromQuestioning.sqf    # Intel gained from civilian questioning
  fn_intelFromPatrol.sqf         # Intel gained from patrol near cell
  fn_intelFromSIGINT.sqf         # Intel from electronic/signals intelligence
  fn_intelAccumulate.sqf         # Add intel points toward cell discovery
  fn_intelCreateReport.sqf       # Generate intel report for atlas_c2

  # === EVENT HANDLERS ===
  fn_handleHostilityChanged.sqf  # Civilian hostility change → adjust recruitment
  fn_handleProfileDestroyed.sqf  # Insurgent killed → weaken cell
  fn_handleOpcomOrder.sqf        # OPCOM in insurgency mode requests IED/ambush
```

---

### 18.8 `atlas_persist` — Internal Structure

```
atlas_persist/fnc/
  fn_init.sqf                    # Check for saves, init extension if available

  # === LOCAL (PNS) ===
  fn_pnsSave.sqf                 # Save one registry to profileNamespace
  fn_pnsLoad.sqf                 # Load one registry from profileNamespace
  fn_pnsSaveAll.sqf              # Orchestrate: save profiles, objectives, convoys, etc.
  fn_pnsLoadAll.sqf              # Orchestrate: load all registries from PNS
  fn_pnsClear.sqf                # Wipe saved data (admin action)

  # === SERIALIZATION ===
  fn_serialize.sqf               # Convert HashMap to serializable array
  fn_serializeRegistry.sqf       # Serialize entire registry (HashMap of HashMaps)
  fn_deserialize.sqf             # Convert array back to HashMap
  fn_deserializeRegistry.sqf     # Rebuild registry from serialized data

  # === EXTENSION (PostgreSQL) ===
  fn_extensionInit.sqf           # Initialize DLL, pass connection string, start heartbeat
  fn_extensionCall.sqf           # Synchronous callExtension wrapper with error handling
  fn_extensionCallAsync.sqf      # Async callExtension with callback registration
  fn_extensionHandleCallback.sqf # Process extension callback results

  # === THEATER STATE (cross-server) ===
  fn_theaterRead.sqf             # Read theater state from PostgreSQL
  fn_theaterWrite.sqf            # Write this server's theater data to PostgreSQL
  fn_theaterPoll.sqf             # PFH: poll for cross-server events
  fn_theaterProcessEvent.sqf     # Handle one cross-server event (dispatch to local CBA events)
  fn_theaterPublishEvent.sqf     # Push event to cross-server queue

  # === OBJECTIVES (cross-server) ===
  fn_objectivesSync.sqf          # Sync objective states to/from PostgreSQL

  # === PLAYER STATE ===
  fn_playerLoad.sqf              # Load player state (gear, pos, medical) on connect
  fn_playerSave.sqf              # Save player state on disconnect
  fn_playerAutoSave.sqf          # PFH: periodic player state backup

  # === WEATHER ===
  fn_weatherSave.sqf             # Save current weather state
  fn_weatherLoad.sqf             # Restore weather on mission load

  # === SAVE LIFECYCLE ===
  fn_saveAll.sqf                 # Master save: PNS + PostgreSQL, fires events
  fn_loadAll.sqf                 # Master load: PNS + PostgreSQL, fires events
  fn_autosaveStart.sqf           # Start periodic autosave PFH
  fn_isDirty.sqf                 # Check if any registry has dirty entries
```

**Incremental save pattern:**

```sqf
// fn_pnsSave.sqf — only save dirty entries
ATLAS_fnc_persist_pnsSave = {
    params ["_registryName", "_registry"];
    private _dirtyCount = 0;

    {
        private _entity = _y;
        if (_entity getOrDefault ["_dirty", false]) then {
            private _serialized = [_entity] call ATLAS_fnc_persist_serialize;
            profileNamespace setVariable [format ["ATLAS_%1_%2", _registryName, _x], _serialized];
            _entity set ["_dirty", false];
            _dirtyCount = _dirtyCount + 1;
        };
    } forEach _registry;

    _dirtyCount
};
```

---

### 18.9 `atlas_c2` — Internal Structure

ALiVE's C2ISTAR is 157KB. ATLAS splits it into UI lifecycle, task management, and reporting.

```
atlas_c2/fnc/
  fn_init.sqf                    # Register client-side event handlers

  # === TABLET UI ===
  fn_tabletOpen.sqf              # Open tablet dialog, populate initial data
  fn_tabletClose.sqf             # Close tablet, clean up UI state
  fn_tabletRefresh.sqf           # Refresh all tablet panels with current data
  fn_tabletMapDraw.sqf           # Draw objectives, forces, routes on map control
  fn_tabletMapDrawObjectives.sqf # Draw objective markers on map
  fn_tabletMapDrawForces.sqf     # Draw friendly/enemy force indicators
  fn_tabletMapDrawConvoys.sqf    # Draw active convoy routes
  fn_tabletMapDrawAir.sqf        # Draw air mission indicators
  fn_tabletMapDrawIntel.sqf      # Draw intel/asymmetric markers
  fn_tabletPanelForces.sqf       # Populate forces overview panel
  fn_tabletPanelTasks.sqf        # Populate task list panel
  fn_tabletPanelReports.sqf      # Populate reports panel
  fn_tabletPanelSupport.sqf      # Populate support request panel

  # === TASK MANAGEMENT ===
  fn_taskCreate.sqf              # Create task HashMap, assign to players, fire event
  fn_taskUpdate.sqf              # Update task state (succeeded, failed, canceled)
  fn_taskComplete.sqf            # Mark task complete, notify players
  fn_taskGetActive.sqf           # Get all active tasks for a side/player
  fn_taskSync.sqf                # JIP: sync existing tasks to new player

  # === REPORTS ===
  fn_reportSpotrep.sqf           # Generate SPOTREP from template
  fn_reportSitrep.sqf            # Generate SITREP from template
  fn_reportPatrolrep.sqf         # Generate PATROLREP from template
  fn_reportSubmit.sqf            # Submit report, create diary entry, fire event
  fn_reportGetAll.sqf            # Get all reports for display

  # === SUPPORT REQUESTS (UI → event bridge) ===
  fn_requestCAS.sqf              # Player selects target → fires atlas_c2_casRequested
  fn_requestTransport.sqf        # Player selects pickup/dropoff → fires event
  fn_requestResupply.sqf         # Player selects type → fires event
  fn_requestArtillery.sqf        # Player selects target → fires atlas_support_fireMission

  # === EVENT HANDLERS (data → UI updates) ===
  fn_handleObjectiveUpdate.sqf   # Refresh map when objective changes
  fn_handleForceUpdate.sqf       # Refresh forces when profiles spawn/die
  fn_handleLogisticsUpdate.sqf   # Refresh convoy display
  fn_handleAirUpdate.sqf         # Refresh air mission display
```

---

### 18.10 `atlas_support` — Internal Structure

```
atlas_support/fnc/
  fn_init.sqf                    # Register handlers, initialize battery/insertion registries

  # === ARTILLERY ===
  fn_batteryRegister.sqf         # Register an artillery battery (position, type, ammo count)
  fn_batteryGetNearest.sqf       # Find nearest available battery for a target position
  fn_fireMission.sqf             # Execute fire mission: calculate, delay, spawn rounds
  fn_fireMissionCalculate.sqf    # Calculate time-of-flight, dispersion for battery → target
  fn_fireMissionExecute.sqf      # Spawn artillery rounds with appropriate delay
  fn_fireMissionComplete.sqf     # Clean up, update ammo count, fire event

  # === INSERTION POINTS ===
  fn_insertionCreate.sqf         # Create insertion point (respawn, teleport, HALO)
  fn_insertionRemove.sqf         # Remove insertion point
  fn_insertionGetAvailable.sqf   # Get available insertion points for a side
  fn_insertionUse.sqf            # Player uses insertion point — teleport/HALO logic
  fn_insertionHALO.sqf           # HALO insertion: altitude, opening height, drift

  # === GROUP MANAGEMENT ===
  fn_groupGetComposition.sqf     # Get unit composition for a group
  fn_groupDisplayUI.sqf          # Show group management interface
```

---

### 18.11 `atlas_cqb` — Internal Structure

```
atlas_cqb/fnc/
  fn_init.sqf                    # Register handlers, start building scan
  fn_scanBuildings.sqf           # Scheduled: scan all buildings, cache positions per cell
  fn_scanBuildingPositions.sqf   # Get enterable positions for one building
  fn_cacheGet.sqf                # Get cached buildings for a grid cell
  fn_handlePlayerCell.sqf        # Event handler: player_cellChanged → evaluate garrisons
  fn_evaluateBuildings.sqf       # Decide which buildings in range should be garrisoned
  fn_spawnGarrison.sqf           # Spawn garrison in a building (create profile, place units)
  fn_despawnGarrison.sqf         # Remove garrison when all players leave area
  fn_assignPositions.sqf         # Assign units to specific building positions
  fn_getGarrisonSize.sqf         # Calculate appropriate garrison size for building
  fn_handleProfileDestroyed.sqf  # Garrison wiped out — update building state
  fn_handleObjectiveChanged.sqf  # Ownership changed — regarrison for new owner
```

---

### 18.12 Utility Modules — Internal Structure

**`atlas_gc`:**
```
fn_init.sqf                      # Register atlas_profile_destroyed handler, start PFH
fn_enqueue.sqf                   # Add dead units to GC queue with timestamp
fn_processQueue.sqf              # PFH: delete up to 3 corpse groups per frame
fn_cleanupObjects.sqf            # Delete vehicle wrecks, weapon holders in area
```

**`atlas_ai`:**
```
fn_init.sqf                      # Register CBA settings, subscribe to profile_spawned
fn_settingsInit.sqf              # Define CBA settings (skill, accuracy, etc.)
fn_applySkill.sqf                # Apply AI skill settings to a newly spawned group
fn_calculateSkill.sqf            # Determine skill level based on faction, difficulty setting
```

**`atlas_stats`:**
```
fn_init.sqf                      # Subscribe to combat events
fn_recordKill.sqf                # Record unit kill (player or AI)
fn_recordObjective.sqf           # Record objective capture/loss
fn_recordShot.sqf                # Record shots fired (player only)
fn_aggregate.sqf                 # Aggregate stats for save/display
fn_serialize.sqf                 # Serialize stats for persistence
fn_display.sqf                   # Show stats UI to player
```

**`atlas_admin`:**
```
fn_init.sqf                      # Register admin actions
fn_debugMenu.sqf                 # Show debug menu (CBA settings or custom dialog)
fn_teleport.sqf                  # Teleport to position/objective
fn_forceSpawn.sqf                # Force-spawn all profiles in area (debug)
fn_forceSave.sqf                 # Trigger immediate save
fn_forceLoad.sqf                 # Trigger reload from persistence
fn_markProfiles.sqf              # Toggle debug markers showing all virtual profiles
fn_markObjectives.sqf            # Toggle debug markers for objectives
fn_hcStatus.sqf                  # Show HC load distribution status
```

---

*This document is the blueprint for ATLAS.OS development. Every function listed above should be implementable by an agent reading only this document and the functions it depends on. Implementation begins with `atlas_core` and `atlas_profile`, as all other modules depend on them.*
