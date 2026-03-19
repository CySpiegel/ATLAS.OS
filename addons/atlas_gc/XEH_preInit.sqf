// ============================================================================
// ATLAS.OS Garbage Collection — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::GC] Pre-initialization starting...";

// Register module
[
    "gc",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["garbageCollection", "cleanup"]],
        ["events", [
            "ATLAS_gc_collected"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// Cleanup queues
ATLAS_gc_corpseQueue = [];
ATLAS_gc_vehicleQueue = [];

// ---------------------------------------------------------------------------
// CBA Settings — Garbage Collection
// ---------------------------------------------------------------------------

// Corpse cleanup delay
[
    "ATLAS_gc_corpseDelay",
    "SLIDER",
    ["Corpse Cleanup Delay (s)", "Time in seconds before dead units are removed from the game world. Bodies remain visible for this duration after death, then fade out. Lower values (30-60s) improve performance in heavy combat. Higher values (300-600s) preserve battlefield immersion. Bodies near players are never removed."],
    ["ATLAS.OS", "Garbage Collection"],
    [30, 600, 120, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// Vehicle wreck cleanup delay
[
    "ATLAS_gc_vehicleDelay",
    "SLIDER",
    ["Vehicle Wreck Delay (s)", "Time in seconds before destroyed vehicle wrecks are removed. Vehicle wrecks consume more resources than corpses, so shorter delays help performance. However, wrecks provide cover and battlefield atmosphere. Wrecks near players are preserved."],
    ["ATLAS.OS", "Garbage Collection"],
    [60, 900, 300, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// Max cleanup per frame
[
    "ATLAS_gc_maxPerFrame",
    "SLIDER",
    ["Max Cleanup Per Cycle", "Maximum number of objects to clean up in a single garbage collection cycle. Higher values clean faster but may cause frame hitches. Lower values spread the load over more frames for smoother performance. Recommended: 3 for most servers, increase only if objects accumulate faster than they are cleaned."],
    ["ATLAS.OS", "Garbage Collection"],
    [1, 10, 3, 0],
    1,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::GC] Pre-initialization complete.";
