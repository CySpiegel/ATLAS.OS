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

*This document is the blueprint for ATLAS.OS development. Implementation begins with `atlas_core` and `atlas_profile`, as all other modules depend on them.*
