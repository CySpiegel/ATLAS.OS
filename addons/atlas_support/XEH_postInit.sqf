// ============================================================================
// ATLAS.OS Combat Support — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Support] Post-initialization starting...";

if (isServer) then {
    // Initialize support assets after module init
    [{
        {
            [_x] call ATLAS_fnc_support_init;
        } forEach ATLAS_support_assets;
        diag_log format ["[ATLAS::Support] %1 support asset(s) initialized.", count ATLAS_support_assets];
    }, [], 5] call CBA_fnc_waitAndExecute;
};

// Client-side — add support request action to players
if (hasInterface) then {
    ["ATLAS_support_assetsReady", {
        diag_log "[ATLAS::Support] Support menu available to player.";
    }] call CBA_fnc_addEventHandler;
};

diag_log "[ATLAS::Support] Post-initialization complete.";
