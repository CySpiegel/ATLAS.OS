#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_checkSpawnDespawn
// ============================================================================
// Checks profiles near a player and spawns/despawns as needed.
// Called when a player changes grid cells (ATLAS_player_areaChanged event).
// Uses spatial grid for efficient proximity queries.
//
// @param  _player  OBJECT  The player who moved
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

params ["_player"];

if (!isServer) exitWith {};

private _playerPos = getPosATL _player;
private _spawnDist = ATLAS_profile_spawnDistance;
private _despawnDist = ATLAS_profile_despawnDistance;

// Query profiles in cells overlapping the despawn radius (larger radius catches despawn candidates)
private _candidateIDs = [_playerPos, _despawnDist] call EFUNC(main,gridQuery);

{
    private _profile = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_profile isEqualType createHashMap) then { continue };

    private _state = _profile get "state";
    private _profPos = _profile get "pos";
    private _dist = _playerPos distance2D _profPos;

    // Spawn: virtual profiles within spawn distance
    if (_state isEqualTo "virtual" && {_dist < _spawnDist}) then {
        [_x] call FUNC(spawn);
        continue;
    };

    // Despawn: spawned profiles beyond despawn distance from ALL players
    if (_state isEqualTo "spawned" && {_dist > _despawnDist}) then {
        // Check against all players — only despawn if far from everyone
        private _nearAnyPlayer = false;
        {
            if ((getPosATL _x) distance2D _profPos < _despawnDist) exitWith {
                _nearAnyPlayer = true;
            };
        } forEach allPlayers;

        if (!_nearAnyPlayer) then {
            [_x] call FUNC(despawn);
        };
    };
} forEach _candidateIDs;
