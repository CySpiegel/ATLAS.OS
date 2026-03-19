// ============================================================================
// ATLAS_fnc_init
// ============================================================================
// Initializes the ATLAS.OS core framework.
// Called from XEH_postInit on server only.
//
// Usage:
//   [] call ATLAS_fnc_init;
//
// Returns: Nothing
// ============================================================================
#include "..\script_component.hpp"

if (!isServer) exitWith {
    ATLAS_LOG_WARN("Core","ATLAS_fnc_init called on non-server machine. Ignored.");
};

if (ATLAS_initialized getOrDefault ["core", false]) exitWith {
    ATLAS_LOG_WARN("Core","ATLAS_fnc_init called but core already initialized.");
};

// Initialize spatial grid with configured cell size
private _gridSize = ATLAS_setting_gridSize;
ATLAS_LOG_INFO("Core",format ["Initializing spatial grid with %1m cells", _gridSize]);

// Reset registries (safety — should already be empty from preInit)
ATLAS_profileRegistry   = createHashMap;
ATLAS_objectiveRegistry = createHashMap;
ATLAS_civilianRegistry  = createHashMap;
ATLAS_spatialGrid       = createHashMap;
ATLAS_profileCounter    = 0;

// Mark core as initialized
ATLAS_initialized set ["core", true];

// Fire init complete event — other modules listen for this
["ATLAS_core_initialized", []] call CBA_fnc_localEvent;

ATLAS_LOG_INFO("Core","Core framework initialized successfully.");
