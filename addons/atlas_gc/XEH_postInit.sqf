// ============================================================================
// ATLAS.OS Garbage Collection — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Register killed event handler for automatic corpse tracking
    addMissionEventHandler ["EntityKilled", {
        params ["_unit", "_killer", "_instigator", "_useEffects"];
        if (_unit isKindOf "Man") then {
            [_unit] call FUNC(addCorpse);
        } else {
            if (_unit isKindOf "AllVehicles") then {
                [_unit] call FUNC(addVehicle);
            };
        };
    }];

    // Garbage collection cycle
    [{
        [] call FUNC(collect);
    }, 10] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side cleanup handler started (10s cycle).");
};

LOG("Post-initialization complete.");
