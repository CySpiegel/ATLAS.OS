// ============================================================================
// ATLAS.OS Task System — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Subscribe to OPCOM objective events to generate tasks
    ["ATLAS_opcom_orderIssued", {
        params ["_opcomID", "_order", "_objectiveID"];
        [_order, _objectiveID] call FUNC(create);
    }] call CBA_fnc_addEventHandler;

    ["ATLAS_opcom_objectiveCaptured", {
        params ["_objectiveID", "_side"];
        [_objectiveID, "SUCCEEDED"] call FUNC(complete);
    }] call CBA_fnc_addEventHandler;

    LOG("Server-side task handler registered.");
};

LOG("Post-initialization complete.");
