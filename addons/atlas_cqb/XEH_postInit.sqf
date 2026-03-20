// ============================================================================
// ATLAS.OS CQB — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Player proximity check — spawn/despawn CQB garrisons based on player distance
    ["ATLAS_player_areaChanged", {
        params ["_player", "_cell", "_lastCell"];
        {
            private _zone = _y;
            private _zonePos = _zone get "position";
            private _radius = _zone get "radius";
            private _active = _zone getOrDefault ["active", false];
            private _dist = _player distance2D _zonePos;

            if (_dist < _radius + 200 && {!_active}) then {
                [_zone] call FUNC(garrison);
            };
            if (_dist > _radius + 500 && {_active}) then {
                [_zone] call FUNC(despawn);
            };
        } forEach GVAR(zones);
    }] call CBA_fnc_addEventHandler;

    LOG("Server-side proximity handler registered.");
};

LOG("Post-initialization complete.");
