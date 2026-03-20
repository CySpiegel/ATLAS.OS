// ============================================================================
// ATLAS.OS Compatibility Layer — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Run compatibility checks
    [] call FUNC(check);

    LOG("Compatibility checks complete.");
};

LOG("Post-initialization complete.");
