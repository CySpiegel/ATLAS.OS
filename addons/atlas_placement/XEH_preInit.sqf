// ============================================================================
// ATLAS.OS Military Placement — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

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
] call EFUNC(main,registerModule);

// Placement instance registry
GVAR(instances) = [];

LOG("Pre-initialization complete.");
