// ============================================================================
// ATLAS.OS Persistence — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Persistence] Post-initialization starting...";

if (isServer) then {
    // Attempt to load saved state
    [{
        private _config = ATLAS_persistence_config;
        if (count _config > 0) then {
            private _backend = _config getOrDefault ["backend", "profileNamespace"];
            diag_log format ["[ATLAS::Persistence] Loading state from backend: %1", _backend];
            [_backend] call ATLAS_fnc_persistence_load;
        };
    }, [], 5] call CBA_fnc_waitAndExecute;

    // Auto-save handler
    [{
        private _config = ATLAS_persistence_config;
        if (count _config == 0) exitWith {};

        private _autoSave = _config getOrDefault ["autoSaveEnabled", true];
        if (!_autoSave) exitWith {};

        private _interval = _config getOrDefault ["autoSaveInterval", 180];
        if (diag_tickTime - ATLAS_persistence_lastSave >= _interval) then {
            [] call ATLAS_fnc_persistence_save;
            ATLAS_persistence_lastSave = diag_tickTime;
        };
    }, 10] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::Persistence] Server-side auto-save handler started.";
};

diag_log "[ATLAS::Persistence] Post-initialization complete.";
