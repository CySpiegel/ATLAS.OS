// ============================================================================
// ATLAS.OS Combat Support — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "support",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["combatSupport", "CAS", "transport", "artillery"]],
        ["events", [
            "ATLAS_support_requested",
            "ATLAS_support_dispatched",
            "ATLAS_support_complete",
            "ATLAS_support_denied"
        ]]
    ]
] call EFUNC(main,registerModule);

// Support asset registry
GVAR(assets) = [];

LOG("Pre-initialization complete.");
