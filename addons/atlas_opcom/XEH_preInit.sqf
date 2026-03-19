// ============================================================================
// ATLAS.OS OPCOM — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::OPCOM] Pre-initialization starting...";

// Register module with core framework
[
    "opcom",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile", "placement"]],
        ["provides", ["aiCommander", "strategicAI"]],
        ["events", [
            "ATLAS_opcom_orderIssued",
            "ATLAS_opcom_objectiveCaptured",
            "ATLAS_opcom_objectiveLost",
            "ATLAS_opcom_phaseChanged"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// OPCOM instance registry — one per side
ATLAS_opcom_instances = createHashMap;

// Subscribe to objective events
["ATLAS_objective_statusChanged", {
    params ["_objectiveID", "_newStatus", "_side"];
    {
        private _opcom = _y;
        if ((_opcom get "side") isEqualTo _side) then {
            [_opcom, _objectiveID, _newStatus] call ATLAS_fnc_opcom_evaluate;
        };
    } forEach ATLAS_opcom_instances;
}] call CBA_fnc_addEventHandler;

diag_log "[ATLAS::OPCOM] Pre-initialization complete.";
