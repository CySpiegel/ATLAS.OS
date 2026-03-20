// ============================================================================
// ATLAS.OS Admin Actions — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Register admin event handlers
    ["ATLAS_admin_forceSave", {
        [] call FUNC(forceSave);
    }] call CBA_fnc_addEventHandler;

    ["ATLAS_admin_resetState", {
        params ["_scope"];
        [_scope] call FUNC(resetState);
    }] call CBA_fnc_addEventHandler;
};

// Client-side — admin panel keybind (only for logged-in admins)
if (hasInterface) then {
    ["ATLAS.OS", "openAdminPanel", ["Open Admin Panel", "Opens the ATLAS.OS admin control panel for server administrators."],
    {
        if (serverCommandAvailable "#kick") then {
            [] call FUNC(openPanel);
        } else {
            hint "ATLAS: Admin access required.";
        };
    }, "", [0, [false, false, false]]] call CBA_fnc_addKeybind;
};

LOG("Post-initialization complete.");
