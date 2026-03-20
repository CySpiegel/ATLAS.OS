#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_serialize
// ============================================================================
// Converts a profile to a persistence-safe array.
// Delegates to atlas_main_fnc_serialize with profile-specific handling.
//
// @param  _profile  HASHMAP  The profile to serialize
//
// @return ARRAY  Serialized profile data
// @context Server only
// @scheduled false
// ============================================================================

params ["_profile"];

[_profile, true] call EFUNC(main,serialize)
