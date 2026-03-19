// ============================================================================
// ATLAS.OS ATO — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::ATO] Pre-initialization starting...";

// Register module
[
    "ato",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["airTasking", "casSupport", "airTransport"]],
        ["events", [
            "ATLAS_ato_missionAssigned",
            "ATLAS_ato_missionComplete",
            "ATLAS_ato_aircraftLost",
            "ATLAS_ato_aircraftRTB"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// ATO instance registry
ATLAS_ato_instances = createHashMap;

// Active air missions
ATLAS_ato_activeMissions = [];

// Subscribe to OPCOM air support requests
["ATLAS_opcom_requestAirSupport", {
    params ["_side", "_type", "_targetPos", "_priority"];
    {
        private _ato = _y;
        if ((_ato get "side") isEqualTo _side) then {
            [_ato, _type, _targetPos, _priority] call ATLAS_fnc_ato_requestMission;
        };
    } forEach ATLAS_ato_instances;
}] call CBA_fnc_addEventHandler;

diag_log "[ATLAS::ATO] Pre-initialization complete.";
