#include "script_component.hpp"

LOG("PostInit starting");

if (isServer) then {
    [] call FUNC(init);

    LOG_1("Registered modules: %1", keys GVAR(moduleRegistry));

    // Player grid-cell tracking — fires ATLAS_player_areaChanged events
    [{
        private _gridSize = GVAR(gridSize);
        {
            private _player = _x;
            private _pos = getPosATL _player;
            private _cell = [floor ((_pos#0) / _gridSize), floor ((_pos#1) / _gridSize)];
            private _lastCell = _player getVariable [QGVAR(lastCell), [-1,-1]];
            if (!(_cell isEqualTo _lastCell)) then {
                _player setVariable [QGVAR(lastCell), _cell];
                ["ATLAS_player_areaChanged", [_player, _cell, _lastCell]] call CBA_fnc_localEvent;
            };
        } forEach allPlayers;
    }, 1] call CBA_fnc_addPerFrameHandler;

    addMissionEventHandler ["PlayerConnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
        ["ATLAS_player_connected", [_uid, _name, _jip, _owner]] call CBA_fnc_localEvent;
    }];

    addMissionEventHandler ["PlayerDisconnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
        ["ATLAS_player_disconnected", [_uid, _name]] call CBA_fnc_localEvent;
    }];

    addMissionEventHandler ["MPEnded", {
        ["ATLAS_mission_ending", []] call CBA_fnc_localEvent;
    }];
};

if (hasInterface && {GVAR(perfMonitor)}) then {
    [{
        if (!GVAR(perfMonitor)) exitWith {};
        hintSilent format [
            "ATLAS.OS\n---\nProfiles: %1\nGrid Cells: %2\nFPS: %3\nModules: %4",
            count GVAR(profileRegistry),
            count GVAR(spatialGrid),
            diag_fps toFixed 1,
            count GVAR(moduleRegistry)
        ];
    }, 2] call CBA_fnc_addPerFrameHandler;
};

LOG("PostInit complete");
