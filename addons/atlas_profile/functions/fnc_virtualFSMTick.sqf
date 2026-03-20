#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_virtualFSMTick
// ============================================================================
// Per-profile finite state machine tick. Lightweight — just a string key
// and a switch statement. No CBA state machine, no Arma FSM file.
//
// States: virtual (idle), MOVING, ENGAGING, WITHDRAWING, GARRISONED, ROUTED
//
// @param  _profile  HASHMAP  The profile to tick
// @param  _dt       NUMBER   Seconds since last tick
//
// @return Nothing
// @context Server only
// @scheduled true (called from virtualSimulator)
// ============================================================================

params ["_profile", "_dt"];

private _state = _profile get "state";

switch (_state) do {
    case "virtual": {
        // Idle — check if we have waypoints to follow
        private _waypoints = _profile get "waypoints";
        private _wpIdx = _profile getOrDefault ["wpIndex", 0];
        if (_wpIdx < count _waypoints) then {
            _profile set ["state", "MOVING"];
        };
    };

    case "MOVING": {
        // Move along waypoints
        [_profile, _dt] call FUNC(virtualMove);

        // Check for enemy contacts
        private _contacts = [_profile] call FUNC(detectVirtualContacts);
        if (count _contacts > 0) then {
            _profile set ["state", "ENGAGING"];
            _profile set ["engagedWith", _contacts];
            ["ATLAS_profile_contactMade", [_profile get "id", _contacts]] call CBA_fnc_localEvent;
        };

        // Check if all waypoints completed
        private _wpIdx = _profile getOrDefault ["wpIndex", 0];
        if (_wpIdx >= count (_profile get "waypoints")) then {
            _profile set ["state", "virtual"];
            ["ATLAS_profile_waypointsComplete", [_profile get "id"]] call CBA_fnc_localEvent;
        };
    };

    case "ENGAGING": {
        // Resolve combat this tick
        private _result = [_profile, _dt] call FUNC(resolveVirtualCombat);

        switch (_result) do {
            case "WON": {
                _profile set ["state", "MOVING"];
                _profile set ["engagedWith", []];
                private _morale = _profile getOrDefault ["morale", 80];
                _profile set ["morale", (_morale + 5) min 100];  // victory morale boost
            };
            case "LOST": {
                _profile set ["state", "WITHDRAWING"];
                _profile set ["engagedWith", []];
                // Set retreat waypoint toward nearest friendly objective
                private _retreatPos = [_profile] call FUNC(findRetreatPosition);
                _profile set ["retreatPos", _retreatPos];
            };
            case "ROUTED": {
                _profile set ["state", "ROUTED"];
                _profile set ["engagedWith", []];
                private _retreatPos = [_profile] call FUNC(findRetreatPosition);
                _profile set ["retreatPos", _retreatPos];
                ["ATLAS_profile_routed", [_profile get "id"]] call CBA_fnc_localEvent;
            };
            case "DESTROYED": {
                [_profile get "id", "virtualCombat"] call FUNC(destroy);
            };
            // "DRAW" — stay engaging, continue next tick
        };
    };

    case "WITHDRAWING": {
        // Move toward retreat position
        [_profile, _dt, true] call FUNC(virtualMove);

        // Recover morale when not in contact
        private _morale = _profile getOrDefault ["morale", 80];
        _profile set ["morale", (_morale + 2 * _dt) min 100];

        // Check if we've reached retreat position
        private _retreatPos = _profile getOrDefault ["retreatPos", []];
        if (count _retreatPos > 0 && {(_profile get "pos") distance2D _retreatPos < 100}) then {
            _profile set ["state", "virtual"];
        };

        // Recover enough morale → resume orders
        if (_morale > 50) then {
            _profile set ["state", "MOVING"];
        };
    };

    case "GARRISONED": {
        // Do nothing — waiting for OPCOM orders
        // Slow morale recovery
        private _morale = _profile getOrDefault ["morale", 80];
        _profile set ["morale", (_morale + 1 * _dt) min 100];
    };

    case "ROUTED": {
        // Flee at max speed toward nearest friendly objective
        [_profile, _dt, true] call FUNC(virtualMove);

        // Slow morale recovery
        private _morale = _profile getOrDefault ["morale", 80];
        _profile set ["morale", (_morale + 0.5 * _dt) min 100];

        // Recover from rout when morale above 30
        if (_morale > 30) then {
            _profile set ["state", "WITHDRAWING"];
        };
    };
};
