#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_init
// ============================================================================
// Initializes the profile system. Called from XEH_postInit on server.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

if (!isServer) exitWith {};

["ATLAS_player_areaChanged", {
    params ["_player", "_newCell", "_oldCell"];
    [_player] call FUNC(checkSpawnDespawn);
}] call CBA_fnc_addEventHandler;

// Periodic grid sync for spawned profiles (update pos from real units)
[{
    if (!isServer) exitWith {};
    private _budget = 10;
    private _processed = 0;
    {
        private _profile = _y;
        if (_profile get "state" isEqualTo "spawned") then {
            private _group = _profile getOrDefault ["spawnedGroup", grpNull];
            if (!isNull _group) then {
                private _ldr = leader _group;
                if (!isNull _ldr) then {
                    [_profile, getPosATL _ldr] call EFUNC(main,gridMove);
                };
            };
            _processed = _processed + 1;
            if (_processed >= _budget) exitWith {};
        };
    } forEach EGVAR(main,profileRegistry);
}, 5] call CBA_fnc_addPerFrameHandler;

LOG("Profile system initialized");
