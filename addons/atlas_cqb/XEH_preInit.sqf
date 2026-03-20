// ============================================================================
// ATLAS.OS CQB — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

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
] call EFUNC(main,registerModule);

// CQB zone registry
GVAR(zones) = createHashMap;

// Building cache — avoids re-scanning buildings
GVAR(buildingCache) = createHashMap;

LOG("Pre-initialization complete.");
