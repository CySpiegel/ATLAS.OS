// ============================================================================
// ATLAS.OS Cargo System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);
    LOG("Server-side cargo system initialized.");
};

// Client-side — add cargo interaction actions
if (hasInterface) then {
    ["ATLAS_profile_spawned", {
        params ["_profileID"];
        // Add cargo actions to spawned vehicles
    }] call CBA_fnc_addEventHandler;
};

LOG("Post-initialization complete.");
