// ============================================================================
// ATLAS.OS Statistics — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Stats] Post-initialization starting...";

if (isServer) then {
    if (ATLAS_stats_enabled) then {
        [] call ATLAS_fnc_stats_init;

        // Track kill events
        addMissionEventHandler ["EntityKilled", {
            params ["_unit", "_killer", "_instigator"];
            ["kill", [_unit, _killer, _instigator]] call ATLAS_fnc_stats_track;
        }];

        // Periodic stat save
        [{
            if (ATLAS_stats_enabled) then {
                [] call ATLAS_fnc_stats_save;
            };
        }, ATLAS_stats_saveInterval] call CBA_fnc_addPerFrameHandler;

        diag_log "[ATLAS::Stats] Server-side stat tracking active.";
    } else {
        diag_log "[ATLAS::Stats] Stat tracking disabled via settings.";
    };
};

diag_log "[ATLAS::Stats] Post-initialization complete.";
