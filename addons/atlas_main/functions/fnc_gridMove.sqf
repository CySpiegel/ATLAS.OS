#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_gridMove
// ============================================================================
// Updates a profile's position in the spatial grid.
// Only performs a grid re-index if the profile moved to a different cell.
//
// Usage:
//   [_profile, [5000, 6000, 0]] call ATLAS_fnc_gridMove;
//
// Parameters:
//   _profile - HASHMAP: The profile to move
//   _newPos  - ARRAY [x,y,z]: The new position
//
// Returns: BOOL - true if the profile changed grid cells
// ============================================================================

params ["_profile", "_newPos"];

private _gridSize = GVAR(gridSize);
private _oldCell = _profile getOrDefault ["_gridCell", []];
private _newCellX = floor ((_newPos#0) / _gridSize);
private _newCellY = floor ((_newPos#1) / _gridSize);
private _newCell = [_newCellX, _newCellY];

// Update position on profile
_profile set ["pos", _newPos];

// Check if cell changed
if (_newCell isEqualTo _oldCell) exitWith { false };

// Remove from old cell
if !(_oldCell isEqualTo []) then {
    [_profile] call FUNC(gridRemove);
};

// Insert into new cell
_profile set ["_gridCell", _newCell];
private _id = _profile get "id";
private _key = str _newCell;
private _bucket = GVAR(spatialGrid) getOrDefault [_key, []];
_bucket pushBackUnique _id;
GVAR(spatialGrid) set [_key, _bucket];

// Fire movement event
["ATLAS_profile_moved", [_id, _newPos, _oldCell, _newCell]] call CBA_fnc_localEvent;

true
