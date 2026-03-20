#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_serialize
// ============================================================================
// Deep-serializes any ATLAS entity (profile, objective, base) for storage.
// Converts HashMaps to arrays, handles nested structures, strips internal keys.
//
// @param  _entity  HASHMAP  The entity to serialize
// @param  _stripInternal  BOOL  (Optional) Remove keys starting with "_". Default: true
//
// @return ARRAY  Serialized [[key, value], ...] array safe for profileNamespace/DB
//
// @context  Server only
// @scheduled false
// ============================================================================

params ["_entity", ["_stripInternal", true]];

if !(_entity isEqualType createHashMap) exitWith {
    ["Core", "ERROR", format ["serialize: Expected HashMap, got %1", typeName _entity]] call FUNC(log);
    []
};

private _result = [];

{
    private _key = _x;
    private _val = _y;

    // Skip internal tracking keys (prefixed with "_") if requested
    if (_stripInternal && {_key select [0, 1] == "_"}) then {
        continue;
    };

    // Skip non-serializable types
    if (_val isEqualType objNull || _val isEqualType grpNull || _val isEqualType controlNull) then {
        continue;
    };

    // Recursively serialize nested HashMaps
    if (_val isEqualType createHashMap) then {
        _val = [_val, _stripInternal] call FUNC(serialize);
    };

    // Handle arrays that may contain HashMaps
    if (_val isEqualType []) then {
        _val = _val apply {
            if (_x isEqualType createHashMap) then {
                [_x, _stripInternal] call FUNC(serialize)
            } else {
                _x
            };
        };
    };

    // Convert side to string for storage
    if (_val isEqualType west) then {
        _val = str _val;
    };

    _result pushBack [_key, _val];
} forEach _entity;

_result
