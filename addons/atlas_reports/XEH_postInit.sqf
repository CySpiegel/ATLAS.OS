// ============================================================================
// ATLAS.OS Reporting System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Reports] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_reports_init;

    // Auto SPOTREP on contact
    if (ATLAS_reports_autoSpotrep) then {
        ["ATLAS_profile_spawned", {
            params ["_profileID"];
            // Hook contact events for spawned groups
        }] call CBA_fnc_addEventHandler;
    };

    // Periodic SITREP generation
    [{
        [] call ATLAS_fnc_reports_sitrep;
    }, ATLAS_reports_sitrepInterval] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::Reports] Server-side report handlers registered.";
};

diag_log "[ATLAS::Reports] Post-initialization complete.";
