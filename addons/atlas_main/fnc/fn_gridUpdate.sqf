// ============================================================================
// ATLAS_fnc_gridUpdate
// ============================================================================
// Batch updates the spatial grid for all profiles whose position changed.
// Intended to be called periodically to sync spawned unit positions back
// to their virtual profile grid entries.
//
// Usage:
//   [] call ATLAS_fnc_gridUpdate;
//
// Parameters: None
//
// Returns: NUMBER - Count of profiles that changed cells
// ============================================================================

private _movedCount = 0;

{
    private _id = _x;
    private _profile = _y;

    // Only update spawned profiles (virtual profiles are moved by the virtual mover)
    if (_profile get "state" == "spawned") then {
        private _spawnedGroup = _profile getOrDefault ["spawnedGroup", grpNull];
        if (!isNull _spawnedGroup) then {
            private _leader = leader _spawnedGroup;
            if (!isNull _leader) then {
                private _realPos = getPosATL _leader;
                private _changed = [_profile, _realPos] call ATLAS_fnc_gridMove;
                if (_changed) then {
                    _movedCount = _movedCount + 1;
                };
            };
        };
    };
} forEach ATLAS_profileRegistry;

_movedCount
