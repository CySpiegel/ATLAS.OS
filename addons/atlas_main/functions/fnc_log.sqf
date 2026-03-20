#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_log
// ============================================================================
// Structured logging function with level filtering.
//
// Usage:
//   ["Core", "INFO", "System initialized"] call ATLAS_fnc_log;
//   ["OPCOM", "ERROR", "No objectives found"] call ATLAS_fnc_log;
//
// Parameters:
//   _module - STRING: Module name (e.g., "Core", "OPCOM", "Profile")
//   _level  - STRING: Log level — "ERROR" (0), "WARN" (1), "INFO" (2), "DEBUG" (3)
//   _message - STRING: The log message
//
// Returns: Nothing
// ============================================================================

params ["_module", "_level", "_message"];

private _levelNum = switch (toUpper _level) do {
    case "ERROR": { 0 };
    case "WARN":  { 1 };
    case "INFO":  { 2 };
    case "DEBUG": { 3 };
    default       { 2 };
};

// Filter by configured log level
if (_levelNum > GVAR(logLevel)) exitWith {};

private _timestamp = if (isMultiplayer) then { serverTime } else { time };

diag_log format ["[ATLAS::%1] %2 (t=%3): %4", _module, toUpper _level, _timestamp toFixed 2, _message];
