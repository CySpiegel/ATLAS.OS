#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_findRetreatPosition
// ============================================================================
// Finds the nearest friendly objective for a profile to retreat toward.
//
// @param  _profile  HASHMAP  The retreating profile
//
// @return ARRAY  Position [x,y,z] of nearest friendly objective, or 1km behind current pos
// @context Server only
// @scheduled true
// ============================================================================

params ["_profile"];

private _pos = _profile get "pos";
private _side = _profile get "side";

// Find nearest friendly objective
private _bestPos = [];
private _bestDist = 1e10;

{
    private _obj = _y;
    if ((_obj get "side") isEqualTo _side) then {
        private _d = (_obj get "pos") distance2D _pos;
        if (_d < _bestDist) then {
            _bestDist = _d;
            _bestPos = _obj get "pos";
        };
    };
} forEach EGVAR(main,objectiveRegistry);

// Fallback: retreat 1km away from nearest enemy
if (_bestPos isEqualTo []) then {
    private _engaged = _profile getOrDefault ["engagedWith", []];
    if (count _engaged > 0) then {
        private _enemy = EGVAR(main,profileRegistry) getOrDefault [_engaged#0, ""];
        if (_enemy isEqualType createHashMap) then {
            private _enemyPos = _enemy get "pos";
            private _dx = (_pos#0) - (_enemyPos#0);
            private _dy = (_pos#1) - (_enemyPos#1);
            private _len = sqrt (_dx * _dx + _dy * _dy);
            if (_len > 0) then {
                _bestPos = [
                    (_pos#0) + (_dx / _len) * 1000,
                    (_pos#1) + (_dy / _len) * 1000,
                    0
                ];
            };
        };
    };
};

// Last resort: random direction 1km away
if (_bestPos isEqualTo []) then {
    private _dir = random 360;
    _bestPos = [
        (_pos#0) + (sin _dir) * 1000,
        (_pos#1) + (cos _dir) * 1000,
        0
    ];
};

_bestPos
