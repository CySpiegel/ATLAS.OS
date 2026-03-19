// ============================================================================
// ATLAS.OS Weather System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Weather] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_weather_init;

    // Weather update cycle
    [{
        [] call ATLAS_fnc_weather_update;
    }, 60] call CBA_fnc_addPerFrameHandler;

    // Sync weather to JIP players
    if (ATLAS_weather_forceSync) then {
        ["ATLAS_player_connected", {
            params ["_uid", "_name", "_jip", "_owner"];
            if (_jip) then {
                [_owner] call ATLAS_fnc_weather_sync;
            };
        }] call CBA_fnc_addEventHandler;
    };

    diag_log "[ATLAS::Weather] Server-side weather handler started (60s cycle).";
};

diag_log "[ATLAS::Weather] Post-initialization complete.";
