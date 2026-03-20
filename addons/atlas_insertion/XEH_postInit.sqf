// ============================================================================
// ATLAS.OS Insertion/Multispawn — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Initialize all insertion points
    [{
        {
            [_x] call FUNC(init);
        } forEach GVAR(points);
        LOG("Spawn points registered: " + str count GVAR(points));

        // Broadcast spawn points to all clients
        publicVariable "GVAR(points)";
        publicVariable "GVAR(defaultPoint)";
    }, [], 3] call CBA_fnc_waitAndExecute;
};

// Client-side — respawn handler
if (hasInterface) then {
    player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        if (count GVAR(points) > 1) then {
            [] call FUNC(showScreen);
        };
    }];
};

LOG("Post-initialization complete.");
