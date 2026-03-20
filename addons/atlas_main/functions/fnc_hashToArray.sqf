#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_hashToArray
// ============================================================================
// Converts a HashMap to a serializable array format.
// Used for persistence — HashMaps cannot be directly saved to profileNamespace.
//
// Usage:
//   private _array = [_hashMap] call ATLAS_fnc_hashToArray;
//
// Parameters:
//   _hash - HASHMAP: The HashMap to serialize
//
// Returns: ARRAY - [[key1, val1], [key2, val2], ...]
//          Nested HashMaps are recursively converted.
// ============================================================================

params ["_hash"];

private _result = [];

{
    private _key = _x;
    private _val = _y;

    // Recursively convert nested HashMaps
    if (_val isEqualType createHashMap) then {
        _val = [_val] call FUNC(hashToArray);
    };

    // Handle arrays that may contain HashMaps
    if (_val isEqualType []) then {
        _val = _val apply {
            if (_x isEqualType createHashMap) then {
                [_x] call FUNC(hashToArray)
            } else {
                _x
            };
        };
    };

    _result pushBack [_key, _val];
} forEach _hash;

_result
