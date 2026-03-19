// ============================================================================
// ATLAS.OS Combat Support — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Support] Pre-initialization starting...";

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
] call ATLAS_fnc_registerModule;

// Support asset registry
ATLAS_support_assets = [];

diag_log "[ATLAS::Support] Pre-initialization complete.";
