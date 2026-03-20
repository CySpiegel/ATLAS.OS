#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_create
// ============================================================================
// Creates a new unit profile and registers it in the profile registry
// and spatial grid. Fires "ATLAS_profile_created" on success.
//
// @param  _type        STRING   "infantry", "motorized", "mechanized", "armor", "air", "naval"
// @param  _side        SIDE     west, east, resistance, civilian
// @param  _pos         ARRAY    World position [x, y, z]
// @param  _classnames  ARRAY    Unit classname strings for this group
// @param  _faction     STRING   (Optional) Faction classname. Default: ""
//
// @return HASHMAP  The created profile, or empty HashMap on failure
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_type",       "",   [""]],
    ["_side",       west, [west]],
    ["_pos",        [],   [[]]],
    ["_classnames", [],   [[]]],
    ["_faction",    "",   [""]]
];

if (_type isEqualTo "") exitWith {
    LOG("create: Empty type — aborting");
    createHashMap
};

if (_classnames isEqualTo []) exitWith {
    LOG("create: No classnames — aborting");
    createHashMap
};

if (count _pos < 2) exitWith {
    LOG("create: Invalid position — aborting");
    createHashMap
};

private _id = ["P"] call EFUNC(main,nextID);

private _profile = createHashMapFromArray [
    ["id",          _id],
    ["type",        _type],
    ["side",        _side],
    ["pos",         _pos],
    ["classnames",  _classnames],
    ["faction",     _faction],
    ["waypoints",   []],
    ["wpIndex",     0],
    ["state",       "virtual"],
    ["strength",    1.0],
    ["damage",      createHashMapFromArray [["hull", 1.0]]],
    ["cargo",       []],
    ["groupData",   createHashMapFromArray [
        ["behaviour",  "AWARE"],
        ["speed",      "NORMAL"],
        ["formation",  "WEDGE"],
        ["combatMode", "YELLOW"]
    ]],
    ["spawnedGroup", grpNull],
    ["spawnedUnits", []],
    ["objectiveId", ""],
    ["orderId",     ""],
    ["_dirty",      true],
    ["_createdAt",  serverTime]
];

// Register in global registry
EGVAR(main,profileRegistry) set [_id, _profile];

// Insert into spatial grid
[_profile] call EFUNC(main,gridInsert);

// Publish event
["ATLAS_profile_created", [_id, _type, _side, _pos]] call CBA_fnc_localEvent;

LOG_1("Profile created: %1", _id);

_profile
