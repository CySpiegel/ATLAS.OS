#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_spawn
// ============================================================================
// Materializes a virtual profile into actual AI units on the ground.
// Creates the group, units, and applies group settings from the profile.
//
// @param  _profileID  STRING  The profile ID to spawn
//
// @return GROUP  The created group, or grpNull on failure
// @context Server only
// @scheduled false
// ============================================================================

params [["_profileID", "", [""]]];

if (_profileID isEqualTo "") exitWith {
    LOG("spawn: Empty profileID — aborting");
    grpNull
};

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith {
    LOG_1("spawn: Profile %1 not found", _profileID);
    grpNull
};

if (_profile get "state" isEqualTo "spawned") exitWith {
    _profile get "spawnedGroup"
};

private _side = _profile get "side";
private _pos = _profile get "pos";
private _classnames = _profile get "classnames";
private _groupData = _profile get "groupData";

// Create group
private _group = createGroup [_side, true];
if (isNull _group) exitWith {
    LOG_1("spawn: Failed to create group for %1", _profileID);
    grpNull
};

// Create units
private _units = [];
{
    private _unit = _group createUnit [_x, _pos, [], 5, "NONE"];
    if (!isNull _unit) then {
        _unit setVariable [QGVAR(profileID), _profileID];
        _units pushBack _unit;
    };
} forEach _classnames;

if (_units isEqualTo []) exitWith {
    LOG_1("spawn: No units created for %1", _profileID);
    deleteGroup _group;
    grpNull
};

// Apply group settings
_group setBehaviourStrong (_groupData getOrDefault ["behaviour", "AWARE"]);
_group setSpeedMode (_groupData getOrDefault ["speed", "NORMAL"]);
_group setFormation (_groupData getOrDefault ["formation", "WEDGE"]);
_group setCombatMode (_groupData getOrDefault ["combatMode", "YELLOW"]);

// Update profile state
_profile set ["state", "spawned"];
_profile set ["spawnedGroup", _group];
_profile set ["spawnedUnits", _units];
_profile set ["_dirty", true];

// Add killed EH to track casualties
{
    _x addEventHandler ["Killed", {
        params ["_unit", "_killer"];
        private _pid = _unit getVariable [QGVAR(profileID), ""];
        if (_pid isEqualTo "") exitWith {};
        private _grp = group _unit;
        // If all units in group are dead, destroy the profile
        if ({alive _x} count (units _grp) == 0) then {
            [_pid, "killed"] call FUNC(destroy);
        } else {
            // Update strength
            private _prof = EGVAR(main,profileRegistry) getOrDefault [_pid, ""];
            if (_prof isEqualType createHashMap) then {
                private _aliveCount = {alive _x} count (units _grp);
                private _totalCount = count (_prof get "classnames");
                _prof set ["strength", _aliveCount / (_totalCount max 1)];
                _prof set ["_dirty", true];
            };
        };
    }];
} forEach _units;

// Fire event
["ATLAS_profile_spawned", [_profileID, _group]] call CBA_fnc_localEvent;

LOG_1("Profile spawned: %1", _profileID);

_group
