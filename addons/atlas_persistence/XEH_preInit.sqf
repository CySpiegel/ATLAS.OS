// ============================================================================
// ATLAS.OS Persistence — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Persistence] Pre-initialization starting...";

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
] call ATLAS_fnc_registerModule;

// Persistence state
ATLAS_persistence_config = createHashMap;
ATLAS_persistence_lastSave = 0;
ATLAS_persistence_dirty = false;

// Subscribe to mission ending event for final save
["ATLAS_mission_ending", {
    if (isServer) then {
        diag_log "[ATLAS::Persistence] Mission ending — performing final save...";
        [] call ATLAS_fnc_persistence_save;
    };
}] call CBA_fnc_addEventHandler;

diag_log "[ATLAS::Persistence] Pre-initialization complete.";
