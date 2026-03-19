// ============================================================================
// ATLAS.OS Military Placement — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Placement] Pre-initialization starting...";

// Register module
[
    "placement",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["militaryPlacement", "forceGeneration"]],
        ["events", [
            "ATLAS_placement_complete",
            "ATLAS_placement_groupSpawned"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// Placement instance registry
ATLAS_placement_instances = [];

diag_log "[ATLAS::Placement] Pre-initialization complete.";
