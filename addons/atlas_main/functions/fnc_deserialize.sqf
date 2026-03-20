#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_deserialize
// ============================================================================
// Reconstructs a HashMap entity from its serialized array form.
// Inverse of atlas_main_fnc_serialize. Restores nested HashMaps and side values.
//
// @param  _data  ARRAY  Serialized [[key, value], ...] from fnc_serialize
//
// @return HASHMAP  Reconstructed entity
//
// @context  Server only
// @scheduled false
// ============================================================================

params ["_data"];

if !(_data isEqualType []) exitWith {
    ["Core", "ERROR", format ["deserialize: Expected array, got %1", typeName _data]] call FUNC(log);
    createHashMap
};

if (_data isEqualTo []) exitWith { createHashMap };

private _hash = createHashMap;

{
    if !(_x isEqualType [] && {count _x == 2}) then { continue };

    _x params ["_key", "_val"];

    // Detect and reconstruct nested serialized HashMaps
    // A nested HashMap looks like: [[string, any], [string, any], ...]
    if (_val isEqualType [] && {count _val > 0} && {(_val#0) isEqualType []} && {count (_val#0) == 2} && {((_val#0)#0) isEqualType ""}) then {
        _val = [_val] call FUNC(deserialize);
    };

    // Restore side values from strings
    if (_val isEqualType "") then {
        _val = switch (toLower _val) do {
            case "west":        { west };
            case "east":        { east };
            case "resistance":  { resistance };
            case "independent": { resistance };
            case "civilian":    { civilian };
            default             { _val };
        };
    };

    // Handle arrays that may contain serialized HashMaps
    if (_val isEqualType []) then {
        _val = _val apply {
            if (_x isEqualType [] && {count _x > 0} && {(_x#0) isEqualType []} && {count (_x#0) == 2} && {((_x#0)#0) isEqualType ""}) then {
                [_x] call FUNC(deserialize)
            } else {
                _x
            };
        };
    };

    _hash set [_key, _val];
} forEach _data;

_hash
