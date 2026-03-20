// ============================================================================
// ATLAS.OS Admin Actions — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "admin",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["adminActions", "adminPanel"]],
        ["events", [
            "ATLAS_admin_actionExecuted",
            "ATLAS_admin_stateReset"
        ]]
    ]
] call EFUNC(main,registerModule);

// ---------------------------------------------------------------------------
// CBA Settings — Admin Actions
// ---------------------------------------------------------------------------

// Admin Panel Keybind (registered as CBA keybind, not a setting)
// Keybind is registered in postInit since it needs hasInterface

LOG("Pre-initialization complete.");
