#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_moduleInit
// ============================================================================
// Called by the engine when an ATLAS_Module_Placement is activated in Eden.
// Reads module attributes, builds a config HashMap, queues for processing.
//
// @param  _logic      OBJECT  The module logic object
// @param  _units      ARRAY   Synced units (unused)
// @param  _activated  BOOL    Whether the module is activated
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

params ["_logic", "_units", "_activated"];

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
