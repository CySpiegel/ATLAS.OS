// ============================================================================
// ATLAS.OS Map Markers — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

// Marker updates run client-side for performance
if (hasInterface) then {
    [] call FUNC(init);

    [{
        [] call FUNC(update);
    }, ATLAS_markers_updateInterval] call CBA_fnc_addPerFrameHandler;

    LOG("Client-side marker update handler started.");
};

LOG("Post-initialization complete.");
