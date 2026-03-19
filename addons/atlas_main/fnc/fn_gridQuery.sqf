// ============================================================================
// ATLAS_fnc_gridQuery
// ============================================================================
// Returns all profile IDs within a radius of a position using spatial grid.
// This is the core performance optimization — reduces O(n*m) to O(m*k).
//
// Usage:
//   private _nearbyIDs = [getPos player, 1500] call ATLAS_fnc_gridQuery;
//
// Parameters:
//   _pos    - ARRAY [x,y,z]: Center position to query from
//   _radius - NUMBER: Search radius in meters
//
// Returns: ARRAY of STRING - Profile IDs in nearby grid cells
//
// Note: Returns candidates from grid cells that OVERLAP the radius.
//       Callers should do precise distance checks on the results.
// ============================================================================

params ["_pos", "_radius"];

private _gridSize = ATLAS_setting_gridSize;
private _cellRadius = ceil (_radius / _gridSize);
private _centerX = floor ((_pos#0) / _gridSize);
private _centerY = floor ((_pos#1) / _gridSize);
private _results = [];

for "_dx" from -_cellRadius to _cellRadius do {
    for "_dy" from -_cellRadius to _cellRadius do {
        private _key = str [_centerX + _dx, _centerY + _dy];
        private _bucket = ATLAS_spatialGrid getOrDefault [_key, []];
        if !(_bucket isEqualTo []) then {
            _results append _bucket;
        };
    };
};

_results
