#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_init
// ============================================================================
// Processes a single placement instance. Reads objectives from synced entities
// or generates them from nearby locations, then creates profiles.
//
// @param  _cfg  HASHMAP  Placement config from moduleInit
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

params ["_cfg"];

if (!isServer) exitWith {};

private _side = _cfg get "side";
private _faction = _cfg get "faction";
private _size = _cfg get "size";
private _pos = _cfg get "pos";
private _synced = _cfg getOrDefault ["synced", []];
private _objectivesOnly = _cfg getOrDefault ["objectivesOnly", false];

LOG_2("Processing placement: %1 %2", _faction, _size);

// Determine objectives — from synced entities or auto-detect nearby locations
private _objectives = [];

// Check for synced objective modules
{
    if (typeOf _x isEqualTo "ATLAS_Module_Objective") then {
        _objectives pushBack (getPosATL _x);
    };
} forEach _synced;

// If no synced objectives, auto-detect from nearby named locations
if (_objectives isEqualTo []) then {
    _objectives = [_pos, _size] call FUNC(readObjectivesFromEditor);
};

if (_objectives isEqualTo []) exitWith {
    LOG("init: No objectives found — no profiles created");
};

LOG_1("Found %1 objectives for placement", count _objectives);

// Register objectives in the objective registry
{
    private _objID = ["OBJ"] call EFUNC(main,nextID);
    private _objective = createHashMapFromArray [
        ["id",       _objID],
        ["pos",      _x],
        ["side",     _side],
        ["name",     format ["Objective %1", _forEachIndex + 1]],
        ["priority", 5],
        ["type",     "military"],
        ["status",   "held"],
        ["garrison", []],
        ["_dirty",   true]
    ];
    EGVAR(main,objectiveRegistry) set [_objID, _objective];
} forEach _objectives;

// Create forces distributed across objectives
private _groupCount = [_size] call FUNC(determineForceComposition);
private _profileIDs = [];

{
    private _objPos = _x;
    private _groupsForObj = ceil (_groupCount / (count _objectives));

    for "_i" from 1 to _groupsForObj do {
        private _spawnPos = _objPos vectorAdd [
            -200 + random 400,
            -200 + random 400,
            0
        ];

        private _type = selectRandom ["infantry", "infantry", "infantry", "motorized"];
        private _classnames = [_type, _faction, _side] call FUNC(getClassnames);

        if !(_classnames isEqualTo []) then {
            private _profile = [_type, _side, _spawnPos, _classnames, _faction] call EFUNC(profile,create);
            if (count _profile > 0) then {
                private _pid = _profile get "id";
                _profileIDs pushBack _pid;

                // Assign to nearest objective
                private _nearestObjID = "";
                private _nearestDist = 1e10;
                {
                    private _obj = _y;
                    private _d = (_obj get "pos") distance2D _spawnPos;
                    if (_d < _nearestDist) then {
                        _nearestDist = _d;
                        _nearestObjID = _x;
                    };
                } forEach EGVAR(main,objectiveRegistry);

                if (_nearestObjID != "") then {
                    _profile set ["objectiveId", _nearestObjID];
                    private _obj = EGVAR(main,objectiveRegistry) get _nearestObjID;
                    (_obj get "garrison") pushBack _pid;
                };
            };
        };
    };
} forEach _objectives;

LOG_1("Placement complete: %1 profiles created", count _profileIDs);

["ATLAS_placement_complete", [_profileIDs, _side, _faction]] call CBA_fnc_localEvent;
