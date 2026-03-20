#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_addWaypoint
// ============================================================================
// Appends a waypoint to a profile's waypoint list.
//
// @param  _profileID  STRING  The profile ID
// @param  _pos        ARRAY   Waypoint position [x, y, z]
// @param  _type       STRING  (Optional) Waypoint type: "MOVE","SAD","HOLD". Default: "MOVE"
//
// @return NUMBER  Index of the added waypoint
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID", "", [""]],
    ["_pos",       [], [[]]],
    ["_type",      "MOVE", [""]]
];

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith {
    LOG_1("addWaypoint: Profile %1 not found", _profileID);
    -1
};

private _wp = createHashMapFromArray [
    ["pos",  _pos],
    ["type", _type]
];

private _waypoints = _profile get "waypoints";
_waypoints pushBack _wp;
_profile set ["_dirty", true];

(count _waypoints) - 1
