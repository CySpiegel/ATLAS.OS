// ============================================================================
// ATLAS.OS Reporting System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Auto SPOTREP on contact
    if (ATLAS_reports_autoSpotrep) then {
        ["ATLAS_profile_spawned", {
            params ["_profileID"];
            // Hook contact events for spawned groups
        }] call CBA_fnc_addEventHandler;
    };

    // Periodic SITREP generation
    [{
        [] call FUNC(sitrep);
    }, ATLAS_reports_sitrepInterval] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side report handlers registered.");
};

LOG("Post-initialization complete.");
