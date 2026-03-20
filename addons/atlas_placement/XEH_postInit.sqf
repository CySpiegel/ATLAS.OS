// ============================================================================
// ATLAS.OS Military Placement — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Process placement queue after all modules have initialized
    [{
        if (count GVAR(instances) > 0) then {
            {
                [_x] spawn FUNC(init);
            } forEach GVAR(instances);
            GVAR(instances) = [];
            LOG("All placement requests processed.");
        };
    }, [], 3] call CBA_fnc_waitAndExecute;

    LOG("Server-side initialization complete.");
};

LOG("Post-initialization complete.");
