#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_placeArmor
// ============================================================================
// Creates armored vehicle profiles near road networks around an objective.
//
// @param  _pos      ARRAY   Center position
// @param  _count    NUMBER  Number of armor groups
// @param  _side     SIDE    Side
// @param  _faction  STRING  Faction classname
//
// @return ARRAY  Created profile IDs
// @context Server only
// @scheduled false
// ============================================================================

params ["_pos", "_count", "_side", "_faction"];

private _profileIDs = [];

for "_i" from 1 to _count do {
    // Place armor near roads
    private _roads = _pos nearRoads 500;
    private _spawnPos = if (count _roads > 0) then {
        getPosATL (selectRandom _roads)
    } else {
        _pos vectorAdd [-200 + random 400, -200 + random 400, 0]
    };

    private _classnames = ["armor", _faction, _side] call FUNC(getClassnames);
    if !(_classnames isEqualTo []) then {
        private _profile = ["armor", _side, _spawnPos, _classnames, _faction] call EFUNC(profile,create);
        if (count _profile > 0) then {
            _profileIDs pushBack (_profile get "id");
        };
    };
};

_profileIDs
