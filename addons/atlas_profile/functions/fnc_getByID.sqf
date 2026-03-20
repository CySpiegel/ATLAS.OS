#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getByID
// ============================================================================
// Returns the profile HashMap for a given profile ID.
//
// @param  _profileID  STRING  The profile ID to look up
//
// @return HASHMAP  The profile, or empty HashMap if not found
// @context Both
// @scheduled false
// ============================================================================

params [["_profileID", "", [""]]];

EGVAR(main,profileRegistry) getOrDefault [_profileID, createHashMap]
