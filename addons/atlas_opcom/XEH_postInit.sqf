// ============================================================================
// ATLAS.OS OPCOM — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // OPCOM decision cycle — runs periodically to evaluate strategic situation
    [{
        {
            private _opcom = _y;
            if (_opcom getOrDefault ["active", false]) then {
                [_opcom] call FUNC(handler);
            };
        } forEach GVAR(instances);
    }, 30] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side decision loop started (30s cycle).");
};

LOG("Post-initialization complete.");
