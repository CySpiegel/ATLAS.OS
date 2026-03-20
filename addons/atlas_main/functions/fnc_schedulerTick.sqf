#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_schedulerTick
// ============================================================================
// Main scheduler tick — runs every frame via the single PFH.
// Dispatches ONE subsystem per frame via priority exitWith chain.
// Only handles unscheduled work (things that touch the real game world).
// Virtual simulation runs in a separate scheduled loop.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

private _now = diag_tickTime;
private _start = _now;

// --- Priority 1: Player grid cell tracking ---
if (_now >= GVAR(nextPlayerGridTime)) exitWith {
    GVAR(nextPlayerGridTime) = _now + 2.0;

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

    GVAR(schedulerLastTickMs) = (diag_tickTime - _start) * 1000;
};

// --- Priority 2: Grid sync for spawned profiles (read real unit positions) ---
if (_now >= GVAR(nextGridSyncTime)) exitWith {
    GVAR(nextGridSyncTime) = _now + 5.0;

    private _budget = 10;
    private _processed = 0;
    {
        private _profile = _y;
        if (_profile get "state" isEqualTo "spawned") then {
            private _group = _profile getOrDefault ["spawnedGroup", grpNull];
            if (!isNull _group) then {
                private _ldr = leader _group;
                if (!isNull _ldr) then {
                    [_profile, getPosATL _ldr] call FUNC(gridMove);
                };
            };
            _processed = _processed + 1;
            if (_processed >= _budget) exitWith {};
        };
    } forEach GVAR(profileRegistry);

    GVAR(schedulerLastTickMs) = (diag_tickTime - _start) * 1000;
};

// --- Lowest priority: Auto-budget recalculation ---
if (_now >= GVAR(nextAutoBudgetTime)) exitWith {
    GVAR(nextAutoBudgetTime) = _now + 2.0;
    call FUNC(autoBudget);
    GVAR(schedulerLastTickMs) = (diag_tickTime - _start) * 1000;
};
