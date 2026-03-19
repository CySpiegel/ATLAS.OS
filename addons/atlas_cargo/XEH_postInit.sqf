// ============================================================================
// ATLAS.OS Cargo System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Cargo] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_cargo_init;
    diag_log "[ATLAS::Cargo] Server-side cargo system initialized.";
};

// Client-side — add cargo interaction actions
if (hasInterface) then {
    ["ATLAS_profile_spawned", {
        params ["_profileID"];
        // Add cargo actions to spawned vehicles
    }] call CBA_fnc_addEventHandler;
};

diag_log "[ATLAS::Cargo] Post-initialization complete.";
