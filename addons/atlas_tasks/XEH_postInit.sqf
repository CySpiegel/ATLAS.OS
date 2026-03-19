// ============================================================================
// ATLAS.OS Task System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Tasks] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_tasks_init;

    // Subscribe to OPCOM objective events to generate tasks
    ["ATLAS_opcom_orderIssued", {
        params ["_opcomID", "_order", "_objectiveID"];
        [_order, _objectiveID] call ATLAS_fnc_tasks_create;
    }] call CBA_fnc_addEventHandler;

    ["ATLAS_opcom_objectiveCaptured", {
        params ["_objectiveID", "_side"];
        [_objectiveID, "SUCCEEDED"] call ATLAS_fnc_tasks_complete;
    }] call CBA_fnc_addEventHandler;

    diag_log "[ATLAS::Tasks] Server-side task handler registered.";
};

diag_log "[ATLAS::Tasks] Post-initialization complete.";
