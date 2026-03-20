// ============================================================================
// ATLAS.OS Persistence — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Attempt to load saved state
    [{
        private _config = GVAR(config);
        if (count _config > 0) then {
            private _backend = _config getOrDefault ["backend", "profileNamespace"];
            LOG("Loading state from backend: " + _backend);
            [_backend] call FUNC(load);
        };
    }, [], 5] call CBA_fnc_waitAndExecute;

    // Auto-save handler
    [{
        private _config = GVAR(config);
        if (count _config == 0) exitWith {};

        private _autoSave = _config getOrDefault ["autoSaveEnabled", true];
        if (!_autoSave) exitWith {};

        private _interval = _config getOrDefault ["autoSaveInterval", 180];
        if (diag_tickTime - GVAR(lastSave) >= _interval) then {
            [] call FUNC(save);
            GVAR(lastSave) = diag_tickTime;
        };
    }, 10] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side auto-save handler started.");
};

LOG("Post-initialization complete.");
