#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_virtualCombatDamage
// ============================================================================
// Returns a type effectiveness multiplier for combat.
// Models rock-paper-scissors dynamics: armor beats infantry,
// AT infantry beats armor, AA beats air, etc.
//
// @param  _attackerType  STRING  Attacker profile type
// @param  _defenderIDs   ARRAY   Defender profile IDs (checks best matchup)
//
// @return NUMBER  Multiplier (>1.0 = advantage, <1.0 = disadvantage)
// @context Server only
// @scheduled true (called from resolveVirtualCombat)
// ============================================================================

params ["_attackerType", "_defenderIDs"];

// Find the dominant defender type
private _defenderTypes = createHashMap;
{
    private _enemy = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if (_enemy isEqualType createHashMap) then {
        private _t = _enemy get "type";
        private _count = _defenderTypes getOrDefault [_t, 0];
        _defenderTypes set [_t, _count + 1];
    };
} forEach _defenderIDs;

// Get the most common defender type
private _dominantType = "infantry";
private _maxCount = 0;
{
    if (_y > _maxCount) then {
        _maxCount = _y;
        _dominantType = _x;
    };
} forEach _defenderTypes;

// Type effectiveness matrix
// Row = attacker, Column = defender
// >1.0 = attacker has advantage
private _matrix = createHashMapFromArray [
    // infantry attacks...
    ["infantry_infantry",    1.0],
    ["infantry_motorized",   0.8],
    ["infantry_mechanized",  0.5],
    ["infantry_armor",       0.3],  // infantry struggles vs armor
    ["infantry_air",         0.2],  // infantry can barely touch air
    ["infantry_naval",       0.1],

    // motorized attacks...
    ["motorized_infantry",   1.3],
    ["motorized_motorized",  1.0],
    ["motorized_mechanized", 0.6],
    ["motorized_armor",      0.4],
    ["motorized_air",        0.3],
    ["motorized_naval",      0.2],

    // mechanized attacks...
    ["mechanized_infantry",  1.5],
    ["mechanized_motorized", 1.3],
    ["mechanized_mechanized",1.0],
    ["mechanized_armor",     0.7],
    ["mechanized_air",       0.4],
    ["mechanized_naval",     0.3],

    // armor attacks...
    ["armor_infantry",       1.8],  // armor crushes infantry
    ["armor_motorized",      1.6],
    ["armor_mechanized",     1.3],
    ["armor_armor",          1.0],
    ["armor_air",            0.5],  // tanks can't easily hit air
    ["armor_naval",          0.3],

    // air attacks...
    ["air_infantry",         2.0],  // CAS devastates infantry
    ["air_motorized",        1.8],
    ["air_mechanized",       1.5],
    ["air_armor",            1.3],  // air has edge vs armor (ATGMs)
    ["air_air",              1.0],
    ["air_naval",            1.5],

    // naval attacks...
    ["naval_infantry",       1.5],
    ["naval_motorized",      1.3],
    ["naval_mechanized",     1.0],
    ["naval_armor",          0.8],
    ["naval_air",            0.6],
    ["naval_naval",          1.0]
];

private _key = format ["%1_%2", _attackerType, _dominantType];
_matrix getOrDefault [_key, 1.0]
