// ============================================================================
// ATLAS.OS Garbage Collection — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::GC] Post-initialization starting...";

if (isServer) then {
    // Register killed event handler for automatic corpse tracking
    addMissionEventHandler ["EntityKilled", {
        params ["_unit", "_killer", "_instigator", "_useEffects"];
        if (_unit isKindOf "Man") then {
            [_unit] call ATLAS_fnc_gc_addCorpse;
        } else {
            if (_unit isKindOf "AllVehicles") then {
                [_unit] call ATLAS_fnc_gc_addVehicle;
            };
        };
    }];

    // Garbage collection cycle
    [{
        [] call ATLAS_fnc_gc_collect;
    }, 10] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::GC] Server-side cleanup handler started (10s cycle).";
};

diag_log "[ATLAS::GC] Post-initialization complete.";
