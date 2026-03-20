// ============================================================================
// ATLAS.OS Civilian Population — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "civilian",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["civilianPopulation", "ambientLife"]],
        ["events", [
            "ATLAS_civilian_spawned",
            "ATLAS_civilian_despawned",
            "ATLAS_civilian_killed",
            "ATLAS_civilian_hostilityChanged"
        ]]
    ]
] call EFUNC(main,registerModule);

// Civilian zone registry
GVAR(zones) = [];

// Active civilian count
GVAR(activeCount) = 0;

// Hostility tracking per side
GVAR(hostility) = createHashMap;

LOG("Pre-initialization complete.");
