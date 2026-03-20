#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_destroy
// ============================================================================
// Removes a profile from the registry and spatial grid.
// If spawned, despawns first. Fires "ATLAS_profile_destroyed".
//
// @param  _profileID  STRING  The profile ID to destroy
// @param  _reason     STRING  (Optional) Reason for destruction. Default: "killed"
//
// @return BOOL  true if destroyed successfully
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID", "", [""]],
    ["_reason",    "killed", [""]]
];

if (_profileID isEqualTo "") exitWith {
    LOG("destroy: Empty profileID — aborting");
    false
};

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith {
    LOG_1("destroy: Profile %1 not found", _profileID);
    false
};

// Despawn if currently spawned
if (_profile get "state" isEqualTo "spawned") then {
    [_profileID, true] call FUNC(despawn);
};

// Remove from spatial grid
[_profile] call EFUNC(main,gridRemove);

// Remove from registry
EGVAR(main,profileRegistry) deleteAt _profileID;

// Publish event
["ATLAS_profile_destroyed", [_profileID, _reason, _profile get "side"]] call CBA_fnc_localEvent;

LOG_1("Profile destroyed: %1", _profileID);

true
