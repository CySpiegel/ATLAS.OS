#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getByArea
// ============================================================================
// Returns profile IDs within a radius of a position.
// Uses the spatial grid for efficient lookup, then filters by precise distance.
//
// @param  _pos     ARRAY   Center position [x, y, z]
// @param  _radius  NUMBER  Search radius in meters
// @param  _side    SIDE    (Optional) Filter by side. Default: sideUnknown (all sides)
//
// @return ARRAY  Profile IDs within the radius
// @context Server
// @scheduled false
// ============================================================================

params [
    ["_pos",    [], [[]]],
    ["_radius", 500, [0]],
    ["_side",   sideUnknown, [west]]
];

private _candidates = [_pos, _radius] call EFUNC(main,gridQuery);
private _results = [];

{
    private _profile = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_profile isEqualType createHashMap) then { continue };

    // Side filter
    if !(_side isEqualTo sideUnknown) then {
        if !((_profile get "side") isEqualTo _side) then { continue };
    };

    // Precise distance check
    if ((_profile get "pos") distance2D _pos <= _radius) then {
        _results pushBack _x;
    };
} forEach _candidates;

_results
