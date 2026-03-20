// ============================================================================
// ATLAS.OS ATO — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

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
] call EFUNC(main,registerModule);

// ATO instance registry
GVAR(instances) = createHashMap;

// Active air missions
GVAR(activeMissions) = [];

// Subscribe to OPCOM air support requests
["ATLAS_opcom_requestAirSupport", {
    params ["_side", "_type", "_targetPos", "_priority"];
    {
        private _ato = _y;
        if ((_ato get "side") isEqualTo _side) then {
            [_ato, _type, _targetPos, _priority] call FUNC(requestMission);
        };
    } forEach GVAR(instances);
}] call CBA_fnc_addEventHandler;

LOG("Pre-initialization complete.");
