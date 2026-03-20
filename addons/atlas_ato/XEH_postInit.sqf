// ============================================================================
// ATLAS.OS ATO — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // ATO mission handler — manages active air missions
    [{
        {
            private _ato = _y;
            if (_ato getOrDefault ["active", false]) then {
                [_ato] call FUNC(handler);
            };
        } forEach GVAR(instances);
    }, 15] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side mission handler started (15s cycle).");
};

LOG("Post-initialization complete.");
