#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_virtualMove
// ============================================================================
// Moves a virtual profile along its waypoints using time-delta normalization.
// Speed depends on unit type, road proximity, and strength.
//
// @param  _profile      HASHMAP  The profile to move
// @param  _dt           NUMBER   Seconds since last tick
// @param  _isRetreating BOOL     (Optional) Move toward retreatPos instead. Default: false
//
// @return Nothing
// @context Server only
// @scheduled true (called from virtualFSMTick)
// ============================================================================

params ["_profile", "_dt", ["_isRetreating", false]];

private _pos = _profile get "pos";
private _target = [0, 0, 0];

if (_isRetreating) then {
    _target = _profile getOrDefault ["retreatPos", []];
    if (_target isEqualTo []) exitWith {};
} else {
    private _waypoints = _profile get "waypoints";
    private _wpIdx = _profile getOrDefault ["wpIndex", 0];
    if (_wpIdx >= count _waypoints) exitWith {};
    _target = (_waypoints select _wpIdx) get "pos";
};

// Speed from type lookup (m/s)
private _baseSpeed = switch (_profile get "type") do {
    case "infantry":    { 1.4 };   // ~5 km/h
    case "motorized":   { 11.0 };  // ~40 km/h
    case "mechanized":  { 8.3 };   // ~30 km/h
    case "armor":       { 7.2 };   // ~26 km/h
    case "air":         { 44.0 };  // ~160 km/h
    case "naval":       { 8.3 };   // ~30 km/h
    default             { 1.4 };
};

// Road bonus — check if profile is near a road
private _onRoad = _profile getOrDefault ["onRoad", false];
private _roadBonus = if (_onRoad) then { 1.4 } else { 1.0 };

// Strength penalty — wounded/attrited units move slower
private _strengthMod = linearConversion [0, 1, _profile getOrDefault ["strength", 1.0], 0.5, 1.0, true];

// Routed units move at 1.3x (fleeing)
private _fleeBonus = if (_profile get "state" isEqualTo "ROUTED") then { 1.3 } else { 1.0 };

private _speed = _baseSpeed * _roadBonus * _strengthMod * _fleeBonus;
private _moveDist = _speed * _dt;

private _dist = _pos distance2D _target;

if (_moveDist >= _dist) then {
    // Arrived at target
    _profile set ["pos", _target];
    [_profile, _target] call EFUNC(main,gridMove);

    if (!_isRetreating) then {
        // Advance to next waypoint
        private _wpIdx = _profile getOrDefault ["wpIndex", 0];
        _profile set ["wpIndex", _wpIdx + 1];

        // Update road status at new position
        _profile set ["onRoad", count (_target nearRoads 50) > 0];
    };
} else {
    // Move toward target
    private _dx = (_target#0) - (_pos#0);
    private _dy = (_target#1) - (_pos#1);
    private _len = sqrt (_dx * _dx + _dy * _dy);
    if (_len > 0) then {
        private _newPos = [
            (_pos#0) + (_dx / _len) * _moveDist,
            (_pos#1) + (_dy / _len) * _moveDist,
            0
        ];
        _profile set ["pos", _newPos];
        [_profile, _newPos] call EFUNC(main,gridMove);
    };
};
