// ============================================================================
// ATLAS.OS Civilian Population — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Civilian] Post-initialization starting...";

if (isServer) then {
    // Civilian ambient life handler — manages spawn/despawn around players
    [{
        if (count ATLAS_civilian_zones == 0) exitWith {};

        private _players = allPlayers;
        if (count _players == 0) exitWith {};

        {
            private _zone = _x;
            private _zonePos = _zone get "position";
            private _radius = _zone get "radius";
            private _maxCivs = _zone getOrDefault ["maxAmbient", 40];
            private _density = _zone getOrDefault ["density", 1.0];

            {
                private _dist = _x distance2D _zonePos;
                if (_dist < _radius + 200) then {
                    private _budget = (_maxCivs - ATLAS_civilian_activeCount) min 5;
                    if (_budget > 0) then {
                        [_zone, _x, _budget] call ATLAS_fnc_civilian_spawn;
                    };
                };
            } forEach _players;
        } forEach ATLAS_civilian_zones;
    }, 5] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::Civilian] Server-side ambient life handler started (5s cycle).";
};

diag_log "[ATLAS::Civilian] Post-initialization complete.";
