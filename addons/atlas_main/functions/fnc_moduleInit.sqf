#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_moduleInit
// ============================================================================
// Called by the engine when ATLAS_ModuleMain is placed/activated.
// In 3DEN editor, _this is a string (classname). At mission runtime,
// _this is [logic, units, activated].
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

// Handle both 3DEN (string) and runtime ([logic, units, activated]) calling conventions
if (_this isEqualType "") exitWith {};  // 3DEN editor placement — do nothing
if (_this isEqualType objNull) exitWith {};  // Single object reference — do nothing

if !(_this isEqualType []) exitWith {};  // Unknown format — ignore

private _logic = _this param [0, objNull, [objNull]];
private _activated = _this param [2, true, [true]];

if (isNull _logic) exitWith {};
if (!_activated) exitWith {};
if (!isServer) exitWith {};

// Check debug mode override from module attribute
private _debugOverride = _logic getVariable ["ATLAS_main_debugMode", 0];
if (_debugOverride isEqualTo 1) then {
    GVAR(debugMode) = true;
    GVAR(logLevel) = 3;
    LOG("Debug mode enabled via module attribute");
};

// Init is called from postInit — don't double-call
if !(GVAR(initialized) getOrDefault ["core", false]) then {
    [] call FUNC(init);
};
