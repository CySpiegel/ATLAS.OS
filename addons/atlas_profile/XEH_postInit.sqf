// ============================================================================
// ATLAS.OS Profile Handler — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Spawn/despawn handler — checks profile distances to nearest player
    [{
        private _spawnDist = ATLAS_profile_spawnDistance;
        private _despawnDist = ATLAS_profile_despawnDistance;
        private _players = allPlayers;

        if (count _players == 0) exitWith {};

        {
            private _profileID = _x;
            private _profile = EGVAR(profile,registry) get _profileID;
            private _pos = _profile get "position";
            private _spawned = _profile getOrDefault ["spawned", false];

            private _nearestDist = _players apply { _x distance2D _pos } select 0;
            {
                _nearestDist = _nearestDist min (_x distance2D _pos);
            } forEach _players;

            if (!_spawned && {_nearestDist < _spawnDist}) then {
                [_profileID] call FUNC(spawn);
            };
            if (_spawned && {_nearestDist > _despawnDist}) then {
                [_profileID] call FUNC(despawn);
            };
        } forEach (keys EGVAR(profile,registry));
    }, 2] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side spawn/despawn handler started (2s cycle).");
};

LOG("Post-initialization complete.");
