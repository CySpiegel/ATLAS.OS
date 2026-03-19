// ============================================================================
// ATLAS.OS CQB — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::CQB] Pre-initialization starting...";

// Register module
[
    "cqb",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["cqbGarrison", "buildingDefense"]],
        ["events", [
            "ATLAS_cqb_garrisoned",
            "ATLAS_cqb_cleared",
            "ATLAS_cqb_despawned"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// CQB zone registry
ATLAS_cqb_zones = createHashMap;

// Building cache — avoids re-scanning buildings
ATLAS_cqb_buildingCache = createHashMap;

diag_log "[ATLAS::CQB] Pre-initialization complete.";
