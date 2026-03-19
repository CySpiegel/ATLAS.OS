// ============================================================================
// ATLAS.OS Core — Post-Initialization
// ============================================================================
// Runs after mission init, unscheduled environment.
// Starts per-frame handlers, initializes server-side systems.
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS] Core post-initialization starting...";

// ---------------------------------------------------------------------------
// 1. Server-Side Initialization
// ---------------------------------------------------------------------------
if (isServer) then {
    // Initialize the core framework
    [] call ATLAS_fnc_init;

    // Log registered modules
    diag_log format ["[ATLAS] Registered modules: %1", keys ATLAS_moduleRegistry];

    // Player tracking — detect grid cell changes for event-driven spawn/despawn
    [{
        {
            private _player = _x;
            private _pos = getPosATL _player;
            private _gridSize = ATLAS_setting_gridSize;
            private _cell = [floor ((_pos#0) / _gridSize), floor ((_pos#1) / _gridSize)];
            private _lastCell = _player getVariable ["ATLAS_lastCell", [-1,-1]];

            if (!(_cell isEqualTo _lastCell)) then {
                _player setVariable ["ATLAS_lastCell", _cell];
                ["ATLAS_player_areaChanged", [_player, _cell, _lastCell]] call CBA_fnc_localEvent;

                if (ATLAS_setting_debugMode) then {
                    diag_log format ["[ATLAS::Core] DEBUG: Player %1 moved to grid cell %2", name _player, _cell];
                };
            };
        } forEach allPlayers;
    }, 1] call CBA_fnc_addPerFrameHandler; // Check every ~1 second

    // Player connection tracking
    addMissionEventHandler ["PlayerConnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
        ["ATLAS_player_connected", [_uid, _name, _jip, _owner]] call CBA_fnc_localEvent;
        diag_log format ["[ATLAS::Core] Player connected: %1 (JIP: %2)", _name, _jip];
    }];

    addMissionEventHandler ["PlayerDisconnected", {
        params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];
        ["ATLAS_player_disconnected", [_uid, _name]] call CBA_fnc_localEvent;
        diag_log format ["[ATLAS::Core] Player disconnected: %1", _name];
    }];

    // Mission end hook for persistence
    addMissionEventHandler ["MPEnded", {
        ["ATLAS_mission_ending", []] call CBA_fnc_localEvent;
        diag_log "[ATLAS::Core] Mission ending — persistence save triggered.";
    }];
};

// ---------------------------------------------------------------------------
// 2. Performance Monitor (Client-Side, if enabled)
// ---------------------------------------------------------------------------
if (hasInterface && {ATLAS_setting_perfMonitor}) then {
    [{
        if (!ATLAS_setting_perfMonitor) exitWith {};

        private _profileCount = count ATLAS_profileRegistry;
        private _gridCells = count ATLAS_spatialGrid;
        private _fps = diag_fps;

        hintSilent format [
            "ATLAS.OS Performance\n---\nProfiles: %1\nGrid Cells: %2\nFPS: %3\nModules: %4",
            _profileCount,
            _gridCells,
            _fps toFixed 1,
            count ATLAS_moduleRegistry
        ];
    }, 2] call CBA_fnc_addPerFrameHandler; // Update every ~2 seconds
};

diag_log "[ATLAS] Core post-initialization complete.";
