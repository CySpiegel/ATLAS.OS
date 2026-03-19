// ============================================================================
// ATLAS.OS AI Behavior — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::AI] Post-initialization starting...";

if (isServer) then {
    // Apply skill settings to newly spawned profiles
    ["ATLAS_profile_spawned", {
        params ["_profileID"];
        [_profileID] call ATLAS_fnc_ai_applySkill;
    }] call CBA_fnc_addEventHandler;

    // Initialize AI system
    [] call ATLAS_fnc_ai_init;

    diag_log "[ATLAS::AI] Server-side AI skill handler registered.";
};

diag_log "[ATLAS::AI] Post-initialization complete.";
