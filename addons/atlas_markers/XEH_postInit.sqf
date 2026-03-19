// ============================================================================
// ATLAS.OS Map Markers — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Markers] Post-initialization starting...";

// Marker updates run client-side for performance
if (hasInterface) then {
    [] call ATLAS_fnc_markers_init;

    [{
        [] call ATLAS_fnc_markers_update;
    }, ATLAS_markers_updateInterval] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::Markers] Client-side marker update handler started.";
};

diag_log "[ATLAS::Markers] Post-initialization complete.";
