#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_resolveVirtualCombat
// ============================================================================
// Resolves virtual combat using Lanchester force-ratio model.
// Damage is proportional to relative combat power, modified by morale,
// ammo supply, and type effectiveness.
//
// @param  _profile  HASHMAP  The profile in combat
// @param  _dt       NUMBER   Seconds since last tick
//
// @return STRING  "WON", "LOST", "DRAW", "ROUTED", or "DESTROYED"
// @context Server only
// @scheduled true (called from virtualFSMTick)
// ============================================================================

params ["_profile", "_dt"];

private _engaged = _profile getOrDefault ["engagedWith", []];
if (_engaged isEqualTo []) exitWith { "WON" };

// --- Own combat power ---
private _ownStrength = _profile getOrDefault ["strength", 1.0];
private _ownCount = count (_profile get "classnames");
private _ownMorale = (_profile getOrDefault ["morale", 80]) / 100;
private _ownAmmo = _profile getOrDefault ["ammoLevel", 1.0];
private _ownType = _profile get "type";

private _ownPower = _ownCount * _ownStrength * _ownMorale * (_ownAmmo max 0.1);

// Type effectiveness multiplier
private _typeBonus = [_ownType, _engaged] call FUNC(virtualCombatDamage);
_ownPower = _ownPower * _typeBonus;

// --- Sum enemy combat power ---
private _enemyPower = 0;
private _aliveContacts = [];

{
    private _enemy = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_enemy isEqualType createHashMap) then { continue };

    private _eStr = _enemy getOrDefault ["strength", 1.0];
    if (_eStr <= 0.05) then { continue };

    private _eCount = count (_enemy get "classnames");
    private _eMorale = (_enemy getOrDefault ["morale", 80]) / 100;
    private _eAmmo = _enemy getOrDefault ["ammoLevel", 1.0];

    _enemyPower = _enemyPower + (_eCount * _eStr * _eMorale * (_eAmmo max 0.1));
    _aliveContacts pushBack _x;
} forEach _engaged;

// All enemies dead
if (_aliveContacts isEqualTo []) exitWith { "WON" };
_profile set ["engagedWith", _aliveContacts];

// --- Force ratio attrition ---
private _totalPower = _ownPower + _enemyPower;
if (_totalPower <= 0) exitWith { "DRAW" };

// Lanchester: damage proportional to opponent's fraction of total power
// Base attrition rate: 5% of strength per second of combat, scaled by ratio
private _attritionRate = 0.05;
private _damageToSelf = (_enemyPower / _totalPower) * _attritionRate * _dt;
private _damageToEnemy = (_ownPower / _totalPower) * _attritionRate * _dt;

// Add randomness (±20%)
_damageToSelf = _damageToSelf * (0.8 + random 0.4);
_damageToEnemy = _damageToEnemy * (0.8 + random 0.4);

// --- Apply damage to self ---
private _newStrength = (_ownStrength - _damageToSelf) max 0;
_profile set ["strength", _newStrength];
_profile set ["_dirty", true];

// Morale loss from taking casualties
private _morale = _profile getOrDefault ["morale", 80];
private _moraleLoss = _damageToSelf * 30;  // losing 10% strength = -3 morale
_profile set ["morale", (_morale - _moraleLoss) max 0];

// --- Apply damage to enemies (distributed) ---
private _dmgPerEnemy = _damageToEnemy / (count _aliveContacts);
{
    private _enemy = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_enemy isEqualType createHashMap) then { continue };

    private _eStr = ((_enemy getOrDefault ["strength", 1.0]) - _dmgPerEnemy) max 0;
    _enemy set ["strength", _eStr];
    _enemy set ["_dirty", true];

    // Enemy morale loss
    private _eMorale = _enemy getOrDefault ["morale", 80];
    _enemy set ["morale", ((_eMorale - _dmgPerEnemy * 30) max 0)];

    // Destroy enemy if wiped out
    if (_eStr <= 0.05) then {
        [_x, "virtualCombat"] call FUNC(destroy);
    };
} forEach _aliveContacts;

// --- Determine outcome ---
// Destroyed
if (_newStrength <= 0.05) exitWith { "DESTROYED" };

// Routed — very low strength AND very low morale
private _currentMorale = _profile getOrDefault ["morale", 80];
if (_newStrength < 0.3 && _currentMorale < 20) exitWith { "ROUTED" };

// Lost — low strength or low morale triggers withdrawal
if (_newStrength < 0.4 && _currentMorale < 40) exitWith { "LOST" };

// Draw — combat continues
"DRAW"
