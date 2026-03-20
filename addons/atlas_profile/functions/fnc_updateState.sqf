#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_updateState
// ============================================================================
// Transitions a profile through states: virtual/spawned.
// Validates the transition and fires appropriate events.
//
// @param  _profileID  STRING  The profile ID
// @param  _newState   STRING  "virtual" or "spawned"
//
// @return BOOL  true if state changed
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID", "", [""]],
    ["_newState",  "", [""]]
];

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith { false };

private _oldState = _profile get "state";
if (_oldState isEqualTo _newState) exitWith { false };

_profile set ["state", _newState];
_profile set ["_dirty", true];

["ATLAS_profile_stateChanged", [_profileID, _oldState, _newState]] call CBA_fnc_localEvent;

true
