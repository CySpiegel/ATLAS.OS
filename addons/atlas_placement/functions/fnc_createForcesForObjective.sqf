#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_createForcesForObjective
// ============================================================================
// Creates a set of profiles for a single objective position.
//
// @param  _objPos     ARRAY   Objective position [x, y, z]
// @param  _groupCount NUMBER  Number of groups to create here
// @param  _side       SIDE    Side for the profiles
// @param  _faction    STRING  Faction classname
//
// @return ARRAY  Created profile IDs
// @context Server only
// @scheduled false
// ============================================================================

params ["_objPos", "_groupCount", "_side", "_faction"];

private _profileIDs = [];

for "_i" from 1 to _groupCount do {
    private _spawnPos = _objPos vectorAdd [
        -300 + random 600,
        -300 + random 600,
        0
    ];

    // Mix of unit types weighted toward infantry
    private _type = selectRandomWeighted ["infantry", 0.6, "motorized", 0.25, "mechanized", 0.1, "armor", 0.05];
    private _classnames = [_type, _faction, _side] call FUNC(getClassnames);

    if !(_classnames isEqualTo []) then {
        private _profile = [_type, _side, _spawnPos, _classnames, _faction] call EFUNC(profile,create);
        if (count _profile > 0) then {
            _profileIDs pushBack (_profile get "id");
        };
    };
};

_profileIDs
