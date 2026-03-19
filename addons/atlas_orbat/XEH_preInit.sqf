// ============================================================================
// ATLAS.OS ORBAT — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::ORBAT] Pre-initialization starting...";

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
] call ATLAS_fnc_registerModule;

// ORBAT data store — per-side force structure
ATLAS_orbat_data = createHashMap;

diag_log "[ATLAS::ORBAT] Pre-initialization complete.";
