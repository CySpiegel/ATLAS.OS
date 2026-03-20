#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getBySide
// ============================================================================
// Returns all profile IDs matching a given side.
//
// @param  _side  SIDE  The side to filter by
//
// @return ARRAY  Profile IDs matching the side
// @context Server
// @scheduled false
// ============================================================================

params [["_side", west, [west]]];

private _results = [];
{
    if ((_y get "side") isEqualTo _side) then {
        _results pushBack _x;
    };
} forEach EGVAR(main,profileRegistry);

_results
