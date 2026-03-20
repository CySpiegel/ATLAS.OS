// ============================================================================
// ATLAS.OS C2 (Command & Control) — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);
    LOG("Server-side C2 data provider initialized.");
};

// Client-side — register C2 tablet keybind
if (hasInterface) then {
    ["ATLAS.OS", "openC2Tablet", ["Open C2 Tablet", "Opens the ATLAS.OS Command & Control tablet interface. Displays tactical map, intel reports, force disposition, support requests, and ORBAT information."],
    {
        [] call FUNC(openTablet);
    }, "", [0, [false, false, false]]] call CBA_fnc_addKeybind;

    // Auto-refresh intel when tablet is open
    [{
        if (!isNil "GVAR(tabletOpen)" && {GVAR(tabletOpen)}) then {
            [] call FUNC(refreshIntel);
        };
    }, ATLAS_c2_intelRefreshRate] call CBA_fnc_addPerFrameHandler;

    LOG("Client-side C2 tablet keybind registered.");
};

LOG("Post-initialization complete.");
