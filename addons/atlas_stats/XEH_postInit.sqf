// ============================================================================
// ATLAS.OS Statistics — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    if (ATLAS_stats_enabled) then {
        [] call FUNC(init);

        // Track kill events
        addMissionEventHandler ["EntityKilled", {
            params ["_unit", "_killer", "_instigator"];
            ["kill", [_unit, _killer, _instigator]] call FUNC(track);
        }];

        // Periodic stat save
        [{
            if (ATLAS_stats_enabled) then {
                [] call FUNC(save);
            };
        }, ATLAS_stats_saveInterval] call CBA_fnc_addPerFrameHandler;

        LOG("Server-side stat tracking active.");
    } else {
        LOG("Stat tracking disabled via settings.");
    };
};

LOG("Post-initialization complete.");
