// ============================================================================
// ATLAS.OS AI Behavior — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    // Apply skill settings to newly spawned profiles
    ["ATLAS_profile_spawned", {
        params ["_profileID"];
        [_profileID] call FUNC(applySkill);
    }] call CBA_fnc_addEventHandler;

    // Initialize AI system
    [] call FUNC(init);

    LOG("Server-side AI skill handler registered.");
};

LOG("Post-initialization complete.");
