// ============================================================================
// ATLAS.OS ORBAT — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "orbat",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["orbat", "orderOfBattle", "forceComposition"]],
        ["events", [
            "ATLAS_orbat_updated"
        ]]
    ]
] call EFUNC(main,registerModule);

// ORBAT data store — per-side force structure
GVAR(data) = createHashMap;

LOG("Pre-initialization complete.");
