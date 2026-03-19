// ============================================================================
// ATLAS.OS Insertion/Multispawn — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Insertion] Post-initialization starting...";

if (isServer) then {
    // Initialize all insertion points
    [{
        {
            [_x] call ATLAS_fnc_insertion_init;
        } forEach ATLAS_insertion_points;
        diag_log format ["[ATLAS::Insertion] %1 spawn point(s) registered.", count ATLAS_insertion_points];

        // Broadcast spawn points to all clients
        publicVariable "ATLAS_insertion_points";
        publicVariable "ATLAS_insertion_defaultPoint";
    }, [], 3] call CBA_fnc_waitAndExecute;
};

// Client-side — respawn handler
if (hasInterface) then {
    player addEventHandler ["Respawn", {
        params ["_unit", "_corpse"];
        if (count ATLAS_insertion_points > 1) then {
            [] call ATLAS_fnc_insertion_showScreen;
        };
    }];
};

diag_log "[ATLAS::Insertion] Post-initialization complete.";
