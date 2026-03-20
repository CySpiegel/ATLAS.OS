#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getByObjective
// ============================================================================
// Returns all profile IDs assigned to a given objective.
//
// @param  _objectiveID  STRING  The objective ID
//
// @return ARRAY  Profile IDs assigned to this objective
// @context Server
// @scheduled false
// ============================================================================

params [["_objectiveID", "", [""]]];

private _results = [];
{
    if ((_y getOrDefault ["objectiveId", ""]) isEqualTo _objectiveID) then {
        _results pushBack _x;
    };
} forEach EGVAR(main,profileRegistry);

_results
