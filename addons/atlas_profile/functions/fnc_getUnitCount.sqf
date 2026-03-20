#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_getUnitCount
// ============================================================================
// Returns the total unit count across all profiles, optionally filtered by side.
//
// @param  _side  SIDE  (Optional) Filter by side. Default: sideUnknown (all)
//
// @return NUMBER  Total unit count
// @context Server
// @scheduled false
// ============================================================================

params [["_side", sideUnknown, [west]]];

private _count = 0;
{
    private _profile = _y;
    if (_side isEqualTo sideUnknown || {(_profile get "side") isEqualTo _side}) then {
        _count = _count + count (_profile get "classnames");
    };
} forEach EGVAR(main,profileRegistry);

_count
