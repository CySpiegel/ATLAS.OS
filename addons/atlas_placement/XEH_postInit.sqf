// ============================================================================
// ATLAS.OS Military Placement — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Placement] Post-initialization starting...";

if (isServer) then {
    // Process placement queue after all modules have initialized
    [{
        if (count ATLAS_placement_instances > 0) then {
            {
                [_x] call ATLAS_fnc_placement_init;
            } forEach ATLAS_placement_instances;
            ATLAS_placement_instances = [];
            diag_log "[ATLAS::Placement] All placement requests processed.";
        };
    }, [], 3] call CBA_fnc_waitAndExecute;

    diag_log "[ATLAS::Placement] Server-side initialization complete.";
};

diag_log "[ATLAS::Placement] Post-initialization complete.";
