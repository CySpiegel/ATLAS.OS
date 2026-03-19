// ============================================================================
// ATLAS.OS OPCOM — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::OPCOM] Post-initialization starting...";

if (isServer) then {
    // OPCOM decision cycle — runs periodically to evaluate strategic situation
    [{
        {
            private _opcom = _y;
            if (_opcom getOrDefault ["active", false]) then {
                [_opcom] call ATLAS_fnc_opcom_handler;
            };
        } forEach ATLAS_opcom_instances;
    }, 30] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::OPCOM] Server-side decision loop started (30s cycle).";
};

diag_log "[ATLAS::OPCOM] Post-initialization complete.";
