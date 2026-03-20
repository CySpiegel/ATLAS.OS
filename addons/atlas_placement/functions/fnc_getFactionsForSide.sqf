#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_getFactionsForSide
// ============================================================================
// Returns available faction classnames for a given side from CfgFactionClasses.
//
// @param  _side  SIDE  west, east, resistance
//
// @return ARRAY  Faction classname strings
// @context Both
// @scheduled false
// ============================================================================

params [["_side", west, [west]]];

private _sideNum = switch (_side) do {
    case west:       { 1 };
    case east:       { 0 };
    case resistance: { 2 };
    case civilian:   { 3 };
    default          { 1 };
};

private _factions = [];
{
    private _factionSide = getNumber (_x >> "side");
    if (_factionSide == _sideNum) then {
        _factions pushBack (configName _x);
    };
} forEach ("true" configClasses (configFile >> "CfgFactionClasses"));

_factions
