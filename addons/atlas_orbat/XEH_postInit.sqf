// ============================================================================
// ATLAS.OS ORBAT — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Rebuild ORBAT when force composition changes
    ["ATLAS_profile_created", {
        [] call FUNC(build);
    }] call CBA_fnc_addEventHandler;

    ["ATLAS_profile_destroyed", {
        [] call FUNC(build);
    }] call CBA_fnc_addEventHandler;

    LOG("Server-side ORBAT tracking initialized.");
};

LOG("Post-initialization complete.");
