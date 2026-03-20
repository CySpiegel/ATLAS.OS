// ============================================================================
// ATLAS.OS Combat Support — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Initialize support assets after module init
    [{
        {
            [_x] call FUNC(init);
        } forEach GVAR(assets);
        LOG("Support assets initialized: " + str count GVAR(assets));
    }, [], 5] call CBA_fnc_waitAndExecute;
};

// Client-side — add support request action to players
if (hasInterface) then {
    ["ATLAS_support_assetsReady", {
        LOG("Support menu available to player.");
    }] call CBA_fnc_addEventHandler;
};

LOG("Post-initialization complete.");
