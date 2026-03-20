#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_validateProfile
// ============================================================================
// Validates that a profile HashMap contains all required keys with correct types.
// Used before registration and after deserialization to catch corrupt data.
//
// @param  _profile  HASHMAP  The profile to validate
//
// @return BOOL  true if valid, false if missing or mistyped keys
//
// @context  Both
// @scheduled false
// ============================================================================

params ["_profile"];

if !(_profile isEqualType createHashMap) exitWith {
    ["Core", "ERROR", "validateProfile: Input is not a HashMap"] call FUNC(log);
    false
};

// Required keys and their expected types
private _requiredKeys = [
    ["id",         ""],
    ["type",       ""],
    ["side",       west],
    ["pos",        []],
    ["state",      ""]
];

private _valid = true;

{
    _x params ["_key", "_typeExample"];

    if !(_key in _profile) then {
        ["Core", "WARN", format ["validateProfile: Missing required key '%1'", _key]] call FUNC(log);
        _valid = false;
    } else {
        private _val = _profile get _key;
        if !(_val isEqualType _typeExample) then {
            ["Core", "WARN", format ["validateProfile: Key '%1' has wrong type. Expected %2, got %3", _key, typeName _typeExample, typeName _val]] call FUNC(log);
            _valid = false;
        };
    };
} forEach _requiredKeys;

// Validate position array has at least 2 elements
if (_valid && {count (_profile get "pos") < 2}) then {
    ["Core", "WARN", "validateProfile: Position array must have at least [x,y]"] call FUNC(log);
    _valid = false;
};

// Validate ID is not empty
if (_valid && {(_profile get "id") isEqualTo ""}) then {
    ["Core", "WARN", "validateProfile: ID cannot be empty"] call FUNC(log);
    _valid = false;
};

_valid
