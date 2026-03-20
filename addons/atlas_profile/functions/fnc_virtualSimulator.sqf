#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_virtualSimulator
// ============================================================================
// Main virtual world simulation loop. Runs in SCHEDULED environment.
// Iterates all virtual profiles, runs their FSM tick, yields every N items.
// This is the heart of ATLAS.OS — the virtual battlefield.
//
// @return Nothing
// @context Server only
// @scheduled true
// ============================================================================

if (!isServer) exitWith {};

LOG("Virtual simulator starting");
GVAR(simulatorRunning) = true;

private _simInterval = 0.1;  // 100ms between full passes

while {GVAR(simulatorRunning)} do {
    private _now = diag_tickTime;
    private _registry = EGVAR(main,profileRegistry);
    private _processed = 0;
    private _startTime = _now;

    {
        private _id = _x;
        private _profile = _y;

        // Skip spawned profiles — real Arma AI handles them
        private _state = _profile get "state";
        if (_state isEqualTo "spawned") then { continue };

        // Time delta since this profile was last simulated
        private _lastSim = _profile getOrDefault ["_lastSimTime", _now];
        private _dt = _now - _lastSim;
        if (_dt < 0.05) then { continue };  // min 50ms between ticks

        // Run the lightweight FSM
        [_profile, _dt] call FUNC(virtualFSMTick);

        _profile set ["_lastSimTime", _now];
        _processed = _processed + 1;

        // Yield every 50 profiles to prevent scheduler starvation
        if (_processed % 50 == 0) then {
            sleep 0.001;
            _now = diag_tickTime;  // refresh after yield
        };
    } forEach _registry;

    // Stats for debug overlay
    GVAR(simLastProcessed) = _processed;
    GVAR(simLastDuration) = (diag_tickTime - _startTime) * 1000;

    sleep _simInterval;
};

LOG("Virtual simulator stopped");
