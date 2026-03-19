// ============================================================================
// ATLAS_fnc_registerModule
// ============================================================================
// Registers a module with the ATLAS.OS core framework.
// Each module self-registers during its preInit, declaring its capabilities
// and dependencies. Core has zero knowledge of module internals.
//
// Usage:
//   [
//       "profile",
//       createHashMapFromArray [
//           ["version", "0.1.0"],
//           ["requires", ["main"]],
//           ["provides", ["profileRegistry", "spatialQuery"]],
//           ["events", ["ATLAS_profile_created", "ATLAS_profile_destroyed"]]
//       ]
//   ] call ATLAS_fnc_registerModule;
//
// Parameters:
//   _name   - STRING: Module name (e.g., "profile", "opcom", "cqb")
//   _config - HASHMAP: Module configuration with keys:
//             "version"  - STRING: Module version
//             "requires" - ARRAY: Module dependencies (names)
//             "provides" - ARRAY: Capabilities this module provides
//             "events"   - ARRAY: Events this module publishes
//
// Returns: BOOL - true if registration succeeded
// ============================================================================

params ["_name", "_config"];

if (_name isEqualTo "") exitWith {
    ["Core", "ERROR", "registerModule: Empty module name"] call ATLAS_fnc_log;
    false
};

if (ATLAS_moduleRegistry getOrDefault [_name, ""] isEqualType createHashMap) exitWith {
    ["Core", "WARN", format ["registerModule: Module '%1' already registered", _name]] call ATLAS_fnc_log;
    false
};

// Validate dependencies
private _requires = _config getOrDefault ["requires", []];
private _missingDeps = _requires select { !(ATLAS_moduleRegistry getOrDefault [_x, ""] isEqualType createHashMap) };

if (count _missingDeps > 0) then {
    ["Core", "WARN", format ["registerModule: Module '%1' has unmet dependencies: %2 (may load later)", _name, _missingDeps]] call ATLAS_fnc_log;
};

// Register
_config set ["_registeredAt", diag_tickTime];
ATLAS_moduleRegistry set [_name, _config];

["Core", "INFO", format ["Module registered: %1 v%2", _name, _config getOrDefault ["version", "unknown"]]] call ATLAS_fnc_log;

// Fire module registered event
["ATLAS_module_registered", [_name, _config]] call CBA_fnc_localEvent;

true
