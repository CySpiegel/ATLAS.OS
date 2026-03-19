// ============================================================================
// ATLAS.OS C2 (Command & Control) — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::C2] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_c2_init;
    diag_log "[ATLAS::C2] Server-side C2 data provider initialized.";
};

// Client-side — register C2 tablet keybind
if (hasInterface) then {
    ["ATLAS.OS", "openC2Tablet", ["Open C2 Tablet", "Opens the ATLAS.OS Command & Control tablet interface. Displays tactical map, intel reports, force disposition, support requests, and ORBAT information."],
    {
        [] call ATLAS_fnc_c2_openTablet;
    }, "", [0, [false, false, false]]] call CBA_fnc_addKeybind;

    // Auto-refresh intel when tablet is open
    [{
        if (!isNil "ATLAS_c2_tabletOpen" && {ATLAS_c2_tabletOpen}) then {
            [] call ATLAS_fnc_c2_refreshIntel;
        };
    }, ATLAS_c2_intelRefreshRate] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::C2] Client-side C2 tablet keybind registered.";
};

diag_log "[ATLAS::C2] Post-initialization complete.";
