// ============================================================================
// ATLAS.OS Insertion/Multispawn — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "insertion",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["insertion", "multispawn", "respawnPoints"]],
        ["events", [
            "ATLAS_insertion_pointAdded",
            "ATLAS_insertion_pointRemoved",
            "ATLAS_insertion_playerSpawned"
        ]]
    ]
] call EFUNC(main,registerModule);

// Spawn point registry
GVAR(points) = [];
GVAR(defaultPoint) = objNull;

LOG("Pre-initialization complete.");
