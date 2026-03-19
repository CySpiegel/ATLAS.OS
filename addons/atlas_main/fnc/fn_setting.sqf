// ============================================================================
// ATLAS_fnc_setting
// ============================================================================
// Gets an ATLAS.OS setting value with a default fallback.
// Wrapper around CBA settings for convenient access.
//
// Usage:
//   private _debug = ["debugMode", false] call ATLAS_fnc_setting;
//   private _grid = ["gridSize", 500] call ATLAS_fnc_setting;
//
// Parameters:
//   _name    - STRING: Setting name (without "ATLAS_setting_" prefix)
//   _default - ANY: Default value if setting is not defined
//
// Returns: ANY - The setting value, or _default if not found
// ============================================================================

params ["_name", ["_default", nil]];

private _fullName = format ["ATLAS_setting_%1", _name];
private _value = missionNamespace getVariable [_fullName, _default];

_value
