#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_moduleInit
// ============================================================================
// Called by the engine when an ATLAS_Module_Placement is activated.
// Reads module attributes, builds a config HashMap, queues for processing.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

// Module_F passes [logic, units, activated] but may vary by context
private _logic = param [0, objNull, [objNull]];
private _units = param [1, [], [[]]];
private _activated = param [2, true, [true]];

if (isNull _logic) exitWith {};
if (!_activated) exitWith {};
if (!isServer) exitWith {};

private _side = [east, west, resistance] select (_logic getVariable ["ATLAS_placement_side", 1]);
private _faction = _logic getVariable ["ATLAS_placement_faction", "BLU_F"];
private _size = _logic getVariable ["ATLAS_placement_size", "company"];
private _objectivesOnly = (_logic getVariable ["ATLAS_placement_objectivesOnly", 0]) isEqualTo 1;

private _cfg = createHashMapFromArray [
    ["side",           _side],
    ["faction",        _faction],
    ["size",           _size],
    ["objectivesOnly", _objectivesOnly],
    ["logic",          _logic],
    ["pos",            getPosATL _logic],
    ["synced",         synchronizedObjects _logic]
];

GVAR(instances) pushBack _cfg;

LOG_2("Placement module registered: %1 %2", _faction, _size);
