// ============================================================================
// ATLAS.OS Weather System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Weather update cycle
    [{
        [] call FUNC(update);
    }, 60] call CBA_fnc_addPerFrameHandler;

    // Sync weather to JIP players
    if (ATLAS_weather_forceSync) then {
        ["ATLAS_player_connected", {
            params ["_uid", "_name", "_jip", "_owner"];
            if (_jip) then {
                [_owner] call FUNC(sync);
            };
        }] call CBA_fnc_addEventHandler;
    };

    LOG("Server-side weather handler started (60s cycle).");
};

LOG("Post-initialization complete.");
