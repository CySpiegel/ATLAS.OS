// ============================================================================
// ATLAS.OS ATO — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::ATO] Post-initialization starting...";

if (isServer) then {
    // ATO mission handler — manages active air missions
    [{
        {
            private _ato = _y;
            if (_ato getOrDefault ["active", false]) then {
                [_ato] call ATLAS_fnc_ato_handler;
            };
        } forEach ATLAS_ato_instances;
    }, 15] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::ATO] Server-side mission handler started (15s cycle).";
};

diag_log "[ATLAS::ATO] Post-initialization complete.";
