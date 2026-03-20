#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_gridRemove
// ============================================================================
// Removes a profile from the spatial grid.
//
// Usage:
//   [_profile] call ATLAS_fnc_gridRemove;
//
// Parameters:
//   _profile - HASHMAP: A profile with "id" and "_gridCell" keys
//
// Returns: BOOL - true if successfully removed
// ============================================================================

params ["_profile"];

private _id = _profile get "id";
private _cell = _profile getOrDefault ["_gridCell", []];

if (_cell isEqualTo []) exitWith {
    ["Core", "WARN", format ["gridRemove: Profile %1 has no grid cell", _id]] call FUNC(log);
    false
};

private _key = str _cell;
private _bucket = GVAR(spatialGrid) getOrDefault [_key, []];

// Remove profile ID from bucket
private _idx = _bucket find _id;
if (_idx >= 0) then {
    _bucket deleteAt _idx;

    // Clean up empty buckets to save memory
    if (_bucket isEqualTo []) then {
        GVAR(spatialGrid) deleteAt _key;
    } else {
        GVAR(spatialGrid) set [_key, _bucket];
    };
};

// Clear grid reference from profile
_profile set ["_gridCell", []];

true
