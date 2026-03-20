#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_arrayToHash
// ============================================================================
// Converts a serialized array back to a HashMap.
// Inverse of ATLAS_fnc_hashToArray. Used for persistence deserialization.
//
// Usage:
//   private _hashMap = [_array] call ATLAS_fnc_arrayToHash;
//
// Parameters:
//   _array - ARRAY: [[key1, val1], [key2, val2], ...] format from hashToArray
//
// Returns: HASHMAP - Reconstructed HashMap with nested HashMaps restored
// ============================================================================

params ["_array"];

if !(_array isEqualType []) exitWith {
    ["Core", "ERROR", format ["arrayToHash: Expected array, got %1", typeName _array]] call FUNC(log);
    createHashMap
};

if (_array isEqualTo []) exitWith { createHashMap };

// Check if this is a key-value pair array [[k,v], [k,v], ...]
if !((_array#0) isEqualType []) exitWith {
    ["Core", "ERROR", "arrayToHash: Array elements must be [key, value] pairs"] call FUNC(log);
    createHashMap
};

private _hash = createHashMap;

{
    _x params ["_key", "_val"];

    // Recursively reconstruct nested HashMaps
    // Detect: if _val is an array of [string, any] pairs, it's likely a serialized HashMap
    if (_val isEqualType [] && {count _val > 0} && {(_val#0) isEqualType []} && {count (_val#0) == 2} && {((_val#0)#0) isEqualType ""}) then {
        _val = [_val] call FUNC(arrayToHash);
    };

    _hash set [_key, _val];
} forEach _array;

_hash
