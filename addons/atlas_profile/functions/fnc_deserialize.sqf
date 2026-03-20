#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_deserialize
// ============================================================================
// Reconstructs a profile HashMap from persisted data.
// Delegates to atlas_main_fnc_deserialize, then restores runtime state.
//
// @param  _data  ARRAY  Serialized profile data from fnc_serialize
//
// @return HASHMAP  Reconstructed profile
// @context Server only
// @scheduled false
// ============================================================================

params ["_data"];

private _profile = [_data] call EFUNC(main,deserialize);

// Restore runtime-only keys that aren't persisted
_profile set ["spawnedGroup", grpNull];
_profile set ["spawnedUnits", []];
_profile set ["_dirty", false];

if !(_profile getOrDefault ["state", ""] isEqualTo "spawned") then {
    _profile set ["state", "virtual"];
};

_profile
