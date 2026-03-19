// ============================================================================
// ATLAS.OS Civilian Population — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Civilian] Pre-initialization starting...";

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
] call ATLAS_fnc_registerModule;

// Civilian zone registry
ATLAS_civilian_zones = [];

// Active civilian count
ATLAS_civilian_activeCount = 0;

// Hostility tracking per side
ATLAS_civilian_hostility = createHashMap;

diag_log "[ATLAS::Civilian] Pre-initialization complete.";
