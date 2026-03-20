#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_readObjectivesFromEditor
// ============================================================================
// Auto-detects objective positions from nearby named locations on the map.
// Used when no objectives are manually synced to the placement module.
//
// @param  _centerPos  ARRAY   Center position to search from
// @param  _size       STRING  Force size — determines search radius and count
//
// @return ARRAY  Array of positions suitable as objectives
// @context Server only
// @scheduled false
// ============================================================================

params ["_centerPos", "_size"];

private _searchRadius = switch (_size) do {
    case "company":  { 3000 };
    case "battalion": { 6000 };
    case "brigade":  { 12000 };
    default          { 5000 };
};

private _maxObjectives = switch (_size) do {
    case "company":  { 5 };
    case "battalion": { 12 };
    case "brigade":  { 25 };
    default          { 8 };
};

// Get named locations within search radius
private _locations = nearestLocations [_centerPos, ["NameCity", "NameVillage", "NameCityCapital", "NameLocal", "Airport", "NameMarine"], _searchRadius];

private _objectives = [];
{
    if (count _objectives >= _maxObjectives) exitWith {};
    private _locPos = locationPosition _x;
    // Ensure minimum spacing between objectives (500m)
    private _tooClose = false;
    {
        if (_locPos distance2D _x < 500) exitWith { _tooClose = true };
    } forEach _objectives;
    if (!_tooClose) then {
        _objectives pushBack _locPos;
    };
} forEach _locations;

LOG_1("Auto-detected %1 objectives from map locations", count _objectives);

_objectives
