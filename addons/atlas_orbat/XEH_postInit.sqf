// ============================================================================
// ATLAS.OS ORBAT — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::ORBAT] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_orbat_init;

    // Rebuild ORBAT when force composition changes
    ["ATLAS_profile_created", {
        [] call ATLAS_fnc_orbat_build;
    }] call CBA_fnc_addEventHandler;

    ["ATLAS_profile_destroyed", {
        [] call ATLAS_fnc_orbat_build;
    }] call CBA_fnc_addEventHandler;

    diag_log "[ATLAS::ORBAT] Server-side ORBAT tracking initialized.";
};

diag_log "[ATLAS::ORBAT] Post-initialization complete.";
