#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_despawn
// ============================================================================
// Captures the state of spawned AI units back into the profile HashMap
// and deletes the real units. The profile returns to "virtual" state.
//
// @param  _profileID     STRING  The profile ID to despawn
// @param  _forceDelete   BOOL    (Optional) Skip state capture, just delete. Default: false
//
// @return BOOL  true if despawned successfully
// @context Server only
// @scheduled false
// ============================================================================

params [
    ["_profileID",   "", [""]],
    ["_forceDelete", false, [false]]
];

if (_profileID isEqualTo "") exitWith {
    LOG("despawn: Empty profileID — aborting");
    false
};

private _profile = EGVAR(main,profileRegistry) getOrDefault [_profileID, ""];
if !(_profile isEqualType createHashMap) exitWith {
    LOG_1("despawn: Profile %1 not found", _profileID);
    false
};

if !(_profile get "state" isEqualTo "spawned") exitWith {
    false
};

private _group = _profile getOrDefault ["spawnedGroup", grpNull];

if (!_forceDelete && !isNull _group) then {
    private _leader = leader _group;
    if (!isNull _leader) then {
        // Capture current position
        _profile set ["pos", getPosATL _leader];
        [_profile, getPosATL _leader] call EFUNC(main,gridMove);
    };

    // Capture group state
    private _groupData = _profile get "groupData";
    _groupData set ["behaviour", behaviour _leader];
    _groupData set ["speed", speedMode _group];
    _groupData set ["formation", formation _group];
    _groupData set ["combatMode", combatMode _group];

    // Capture surviving classnames
    private _aliveClassnames = (units _group) select {alive _x} apply {typeOf _x};
    _profile set ["classnames", _aliveClassnames];
    _profile set ["strength", (count _aliveClassnames) / (count (_profile get "classnames")) max 0.01];
};

// Delete real units
private _units = _profile getOrDefault ["spawnedUnits", []];
{
    if (!isNull _x) then { deleteVehicle _x };
} forEach _units;

if (!isNull _group) then {
    deleteGroup _group;
};

// Reset profile state
_profile set ["state", "virtual"];
_profile set ["spawnedGroup", grpNull];
_profile set ["spawnedUnits", []];
_profile set ["_dirty", true];

// Fire event
["ATLAS_profile_despawned", [_profileID]] call CBA_fnc_localEvent;

LOG_1("Profile despawned: %1", _profileID);

true
