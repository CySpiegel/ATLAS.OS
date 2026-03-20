#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_setPosition
// ============================================================================
// Updates a profile's position and moves it in the spatial grid.
//
// @param  _profileID  STRING  The profile ID
// @param  _newPos     ARRAY   New position [x, y, z]
//
// @return BOOL  true if position changed grid cells
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID", "", [""]],
    ["_newPos",    [], [[]]]
];

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith {
    LOG_1("setPosition: Profile %1 not found", _profileID);
    false
};

private _changed = [_profile, _newPos] call EFUNC(main,gridMove);
_profile set ["_dirty", true];

_changed
