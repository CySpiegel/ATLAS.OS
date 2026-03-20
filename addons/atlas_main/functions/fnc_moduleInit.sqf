#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_moduleInit
// ============================================================================
// Called by the engine when ATLAS_ModuleMain is placed in a mission.
// Delegates to fnc_init if not already initialized.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

private _logic = param [0, objNull, [objNull]];
private _units = param [1, [], [[]]];
private _activated = param [2, true, [true]];

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
