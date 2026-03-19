# ATLAS.OS

### Advanced Tactical Lifecycle & Asymmetric Simulation Operating System

A ground-up redesign of the [ALiVE](https://alivemod.com/) military simulation framework for Arma 3, built on modern SQF capabilities.

---

## Situation

ALiVE has been the gold standard for persistent military simulation in Arma 3 for over a decade. However, its architecture predates many modern engine features — most critically, native HashMaps (added in Arma 3 v2.02, April 2021). The result is a codebase built on custom parallel-array "hashes" with O(n) lookups, spin-wait polling loops in the scheduled environment, and brute-force O(n*m) proximity checks across all profiles and players. These architectural decisions made sense at the time, but now cause significant performance bottlenecks at scale: scheduler congestion, stale data from polling delays, spawn/despawn thrashing, and fragile index-based data access throughout.

## Task

Build a complete replacement that achieves **full feature parity** with every ALiVE module (OPCOM, LOGCOM, CQB, Civilian, C2ISTAR, persistence, and more — 24 modules total) while fundamentally rearchitecting every system for performance, maintainability, and scalability. The framework must support large-scale persistent operations with hundreds of virtual profiles and dozens of players without the performance degradation seen in ALiVE.

## Action

ATLAS.OS rebuilds every system using three core architectural shifts:

**1. Native HashMap Data Model**
All entity state (profiles, objectives, civilians) stored in native Arma 3 HashMaps with O(1) access, replacing ALiVE's parallel-array hashes that required O(n) linear scans per lookup.

```sqf
// ALiVE — O(n) linear scan
_side = (_profile select 2) select ((_profile select 1) find "side");

// ATLAS.OS — O(1) direct access
_side = _profile get "side";
```

**2. Event-Driven Architecture**
A CBA-based publish/subscribe event bus replaces ALiVE's polling loops. Systems react to state changes instantly rather than discovering them on 10-120 second polling intervals. OPCOM subscribes to battlefield events, spawn/despawn triggers on player grid-cell changes, and the UI refreshes on relevant state mutations — all without polling.

**3. Spatial Grid Indexing**
Grid-based spatial partitioning replaces ALiVE's brute-force distance checks. Instead of checking every profile against every player each cycle (O(n*m)), ATLAS.OS queries only the nearby grid cells around each player, reducing proximity checks by orders of magnitude.

### Module Architecture

```
ATLAS.OS Core
├── Event Bus (CBA)          — publish/subscribe, namespaced, typed payloads
├── Data Layer (HashMaps)    — native O(1) registries + spatial grid
├── Scheduler Manager        — scheduled only for heavy batch computation
└── Module Loader & Registry — self-registering, decoupled modules

Module Layer
├── atlas_profile      — Virtual unit profiles with spatial indexing
├── atlas_opcom        — AI Operational Commander (CBA state machine)
├── atlas_logcom       — Logistics Commander (event-driven pipeline)
├── atlas_cqb          — Close Quarters Battle (event-driven garrison spawning)
├── atlas_civilian     — Civilian population (agent pooling)
├── atlas_ato          — Air Tasking Order
├── atlas_placement    — Military force placement
├── atlas_persistence  — Incremental dirty-flag save/load
├── atlas_c2           — C2ISTAR command interface
├── atlas_support      — Combat support (CAS/transport/artillery)
├── atlas_gc           — Garbage collection (event queue + per-frame budget)
├── atlas_ai           — AI skill/behavior management
├── atlas_orbat        — ORBAT creator/editor
├── atlas_tasks        — Task framework
├── atlas_weather      — Weather persistence
├── atlas_stats        — Player statistics
├── atlas_admin        — Admin tools
├── atlas_markers      — Map marker management
├── atlas_reports      — SPOTREP/SITREP/PATROLREP
├── atlas_cargo        — Object logistics (cargo/sling)
├── atlas_insertion    — Multi-spawn/insertion
└── atlas_compat       — ALiVE mission migration layer
```

### Key Design Decisions

- **Scheduled only when necessary** — Only batch AI computation (OPCOM planning, bulk profile movement, persistence serialization) uses `spawn`. All reactive logic runs unscheduled via `call`, CBA per-frame handlers, or CBA event handlers.
- **Hysteresis for spawn/despawn** — Spawn at 1500m, despawn at 1800m. Eliminates the rapid cycling caused by ALiVE's single-threshold approach.
- **Dirty-flag optimization** — OPCOM only re-scores objectives whose inputs changed. Persistence only serializes modified profiles. This converts O(n) operations to O(dirty).
- **Civilian agent pooling** — Reuses civilian agents from a pool instead of constant create/destroy cycles, reducing GC pressure.
- **Immutable event payloads** — Events carry snapshots, preventing race conditions between scheduled and unscheduled contexts.

## Result

| Dimension | ALiVE | ATLAS.OS |
|---|---|---|
| **Data access** | O(n) linear scan per lookup | O(1) native HashMap |
| **Proximity checks** | O(n*m) all profiles x all players | O(m*k) spatial grid, nearby cells only |
| **Reactivity** | Poll every 10-120s | Instant event-driven response |
| **OPCOM scoring** | Full recalculation every cycle | Incremental, dirty-flag only |
| **Persistence** | Serialize entire world state | Incremental, only changed profiles |
| **Spawn management** | Fixed radius, thrashing | Hysteresis + event-driven |
| **Civilian lifecycle** | Create/destroy constantly | Object pooling and reuse |
| **Modularity** | Tightly coupled via globals | Event bus decoupling |

For a mission with 300 profiles and 20 players, the spatial grid reduces proximity distance checks from **6,000 per cycle to ~60** — a reduction of two orders of magnitude. These are algorithmic projections; actual benchmarks will be published once core systems are implemented.

**Full feature parity: all 24 ALiVE modules covered.**

---

## Requirements

| Dependency | Version | Purpose |
|---|---|---|
| **Arma 3** | 2.16+ | Native HashMap support, latest engine features |
| **CBA_A3** | 3.16+ | Event system, per-frame handlers, state machines, settings |
| **ACE3** | Optional | Enhanced interaction, medical integration |

## Project Structure

```
@ATLAS_OS/
├── addons/              # PBO addon modules (one per system)
│   ├── atlas_main/      # Core framework, event bus, data layer, spatial grid
│   ├── atlas_profile/   # Virtual profile system
│   ├── atlas_opcom/     # AI operational commander
│   └── ...              # (see module list above)
├── optionals/
│   └── atlas_ace_compat/  # ACE3 integration
├── mod.cpp
└── meta.cpp
```

Each module follows the CBA Extended Event Handler (XEH) lifecycle pattern with `XEH_preInit.sqf` and `XEH_postInit.sqf`, and registers functions via `CfgFunctions`.

## Building

ATLAS.OS uses [HEMTT](https://hemtt.dev/) for building. See the CI/CD pipeline in `.github/workflows/` for automated builds, SQF-VM linting, and Steam Workshop publishing.

```bash
hemtt build         # Development build
hemtt release       # Release build with signed PBOs
```

## Documentation

- [Architecture Design Document](docs/ARCHITECTURE.md) — Full technical specification covering every system, data structure, and design decision.

## Status

**Version:** 0.1.0-DRAFT — Architecture phase. Core systems are being designed and specified prior to implementation.

## License

TBD
