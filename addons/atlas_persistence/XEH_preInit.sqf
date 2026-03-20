// ============================================================================
// ATLAS.OS Persistence — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "persistence",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["persistence", "saveLoad"]],
        ["events", [
            "ATLAS_persistence_saving",
            "ATLAS_persistence_saved",
            "ATLAS_persistence_loading",
            "ATLAS_persistence_loaded"
        ]]
    ]
] call EFUNC(main,registerModule);

// Persistence state
GVAR(config) = createHashMap;
GVAR(lastSave) = 0;
GVAR(dirty) = false;

// Subscribe to mission ending event for final save
["ATLAS_mission_ending", {
    if (isServer) then {
        LOG("Mission ending — performing final save...");
        [] call FUNC(save);
    };
}] call CBA_fnc_addEventHandler;

LOG("Pre-initialization complete.");
