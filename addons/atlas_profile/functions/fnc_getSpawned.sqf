#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getSpawned
// ============================================================================
// Returns all profile IDs currently in the spawned state.
//
// @param  _side  SIDE  (Optional) Filter by side. Default: sideUnknown (all)
//
// @return ARRAY  Profile IDs of spawned profiles
// @context Server
// @scheduled false
// ============================================================================

params [["_side", sideUnknown, [west]]];

private _results = [];
{
    private _profile = _y;
    if (_profile get "state" isEqualTo "spawned") then {
        if (_side isEqualTo sideUnknown || {(_profile get "side") isEqualTo _side}) then {
            _results pushBack _x;
        };
    };
} forEach EGVAR(main,profileRegistry);

_results
