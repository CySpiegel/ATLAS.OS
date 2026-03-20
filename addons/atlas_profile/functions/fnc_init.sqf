#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_init
// ============================================================================
// Initializes the profile system. Registers event handlers.
// The virtual simulator and grid sync are handled by the scheduler —
// this function does NOT create any PFHs.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

if (!isServer) exitWith {};

// Spawn/despawn triggered by player grid cell changes (event-driven, zero idle cost)
["ATLAS_player_areaChanged", {
    params ["_player", "_newCell", "_oldCell"];
    [_player] call FUNC(checkSpawnDespawn);
}] call CBA_fnc_addEventHandler;

// Init simulator state
GVAR(simulatorRunning) = false;
GVAR(simLastProcessed) = 0;
GVAR(simLastDuration) = 0;

LOG("Profile system initialized (event-driven, no PFHs)");
