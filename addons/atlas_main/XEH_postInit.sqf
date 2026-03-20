#include "script_component.hpp"

LOG("PostInit starting");

if (isServer) then {
    [] call FUNC(init);

    LOG_1("Registered modules: %1", keys GVAR(moduleRegistry));

    // Mission event handlers
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

    // Start the scheduler — replaces all individual PFHs
    // This starts both the unscheduled PFH dispatcher AND the scheduled virtual simulator
    [] call FUNC(initScheduler);
};

// Client-side perf overlay (only when enabled)
if (hasInterface) then {
    [{
        if (!GVAR(perfMonitor)) exitWith {};
        private _simProc = EGVAR(profile,simLastProcessed);
        private _simMs = EGVAR(profile,simLastDuration);
        if (isNil "_simProc") then { _simProc = 0 };
        if (isNil "_simMs") then { _simMs = 0 };
        hintSilent format [
            "ATLAS.OS v%1\n─────────────\nProfiles: %2\nGrid Cells: %3\nModules: %4\nFPS: %5\nTier: %6\nBudget: %7ms\n─────────────\nVirtual Sim\nProcessed: %8\nDuration: %9ms",
            GVAR(version),
            count GVAR(profileRegistry),
            count GVAR(spatialGrid),
            count GVAR(moduleRegistry),
            diag_fps toFixed 1,
            GVAR(performanceTier),
            GVAR(schedulerTotalBudget) toFixed 2,
            _simProc,
            _simMs toFixed 2
        ];
    }, 2] call CBA_fnc_addPerFrameHandler;
};

LOG("PostInit complete");
