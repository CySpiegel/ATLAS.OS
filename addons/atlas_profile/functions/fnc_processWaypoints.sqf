#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_processWaypoints
// ============================================================================
// Advances a spawned profile's group to its next pending waypoint.
// Creates Arma waypoints on the group from the profile's waypoint list.
//
// @param  _profileID  STRING  The profile ID
//
// @return BOOL  true if waypoints were applied
// @context Server only
// @scheduled false
// ============================================================================

params [["_profileID", "", [""]]];

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith { false };
if !(_profile get "state" isEqualTo "spawned") exitWith { false };

private _group = _profile getOrDefault ["spawnedGroup", grpNull];
if (isNull _group) exitWith { false };

private _waypoints = _profile get "waypoints";
private _wpIndex = _profile getOrDefault ["wpIndex", 0];

if (_wpIndex >= count _waypoints) exitWith { false };

// Clear existing waypoints
while {count waypoints _group > 0} do {
    deleteWaypoint [_group, 0];
};

// Add remaining waypoints from current index
for "_i" from _wpIndex to (count _waypoints - 1) do {
    private _wp = _waypoints select _i;
    private _pos = _wp get "pos";
    private _type = _wp getOrDefault ["type", "MOVE"];
    private _armaWP = _group addWaypoint [_pos, 0];
    _armaWP setWaypointType _type;
    _armaWP setWaypointCompletionRadius 30;
};

true
