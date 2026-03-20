#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_removeWaypoint
// ============================================================================
// Removes a waypoint by index from the profile's waypoint list.
//
// @param  _profileID  STRING  The profile ID
// @param  _index      NUMBER  Waypoint index to remove
//
// @return BOOL  true if removed
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID", "", [""]],
    ["_index",     -1, [0]]
];

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith { false };

private _waypoints = _profile get "waypoints";
if (_index < 0 || _index >= count _waypoints) exitWith { false };

_waypoints deleteAt _index;

// Adjust wpIndex if needed
private _wpIndex = _profile getOrDefault ["wpIndex", 0];
if (_wpIndex > _index) then {
    _profile set ["wpIndex", _wpIndex - 1];
};

_profile set ["_dirty", true];
true
