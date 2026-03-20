#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_placeInfantry
// ============================================================================
// Creates infantry profiles around an objective position.
//
// @param  _pos      ARRAY   Center position
// @param  _count    NUMBER  Number of infantry groups
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
    private _spawnPos = _pos vectorAdd [
        -150 + random 300,
        -150 + random 300,
        0
    ];
    private _classnames = ["infantry", _faction, _side] call FUNC(getClassnames);
    if !(_classnames isEqualTo []) then {
        private _profile = ["infantry", _side, _spawnPos, _classnames, _faction] call EFUNC(profile,create);
        if (count _profile > 0) then {
            _profileIDs pushBack (_profile get "id");
        };
    };
};

_profileIDs
