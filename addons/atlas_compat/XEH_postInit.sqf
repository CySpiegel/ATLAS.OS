// ============================================================================
// ATLAS.OS Compatibility Layer — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Compat] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_compat_init;

    // Run compatibility checks
    [] call ATLAS_fnc_compat_check;

    diag_log "[ATLAS::Compat] Compatibility checks complete.";
};

diag_log "[ATLAS::Compat] Post-initialization complete.";
