// ============================================================================
// ATLAS.OS CQB — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::CQB] Post-initialization starting...";

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
                [_zone] call ATLAS_fnc_cqb_garrison;
            };
            if (_dist > _radius + 500 && {_active}) then {
                [_zone] call ATLAS_fnc_cqb_despawn;
            };
        } forEach ATLAS_cqb_zones;
    }] call CBA_fnc_addEventHandler;

    diag_log "[ATLAS::CQB] Server-side proximity handler registered.";
};

diag_log "[ATLAS::CQB] Post-initialization complete.";
