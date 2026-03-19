// ============================================================================
// ATLAS.OS Insertion/Multispawn — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Insertion] Pre-initialization starting...";

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
] call ATLAS_fnc_registerModule;

// Spawn point registry
ATLAS_insertion_points = [];
ATLAS_insertion_defaultPoint = objNull;

diag_log "[ATLAS::Insertion] Pre-initialization complete.";
