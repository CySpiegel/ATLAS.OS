#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_gridInsert
// ============================================================================
// Inserts a profile into the spatial grid based on its position.
// The spatial grid enables O(m*k) proximity queries instead of O(n*m).
//
// Usage:
//   [_profile] call ATLAS_fnc_gridInsert;
//
// Parameters:
//   _profile - HASHMAP: A profile with "id" and "pos" keys
//
// Returns: STRING - The grid cell key the profile was inserted into
// ============================================================================

params ["_profile"];

private _pos = _profile get "pos";
private _id = _profile get "id";
private _gridSize = GVAR(gridSize);

// Calculate grid cell coordinates
private _cellX = floor ((_pos#0) / _gridSize);
private _cellY = floor ((_pos#1) / _gridSize);
private _cell = [_cellX, _cellY];
private _key = str _cell;

// Store cell reference on the profile for fast removal
_profile set ["_gridCell", _cell];

// Get or create bucket for this cell
private _bucket = GVAR(spatialGrid) getOrDefault [_key, []];
_bucket pushBackUnique _id;
GVAR(spatialGrid) set [_key, _bucket];

_key
