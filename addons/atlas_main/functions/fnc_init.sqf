#include "..\script_component.hpp"
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

if (!isServer) exitWith {
    ["Core", "WARN", "ATLAS_fnc_init called on non-server machine. Ignored."] call FUNC(log);
};

if (GVAR(initialized) getOrDefault ["core", false]) exitWith {
    ["Core", "WARN", "ATLAS_fnc_init called but core already initialized."] call FUNC(log);
};

// Initialize spatial grid with configured cell size
private _gridSize = GVAR(gridSize);
["Core", "INFO", format ["Initializing spatial grid with %1m cells", _gridSize]] call FUNC(log);

// Reset registries (safety — should already be empty from preInit)
GVAR(profileRegistry)   = createHashMap;
GVAR(objectiveRegistry) = createHashMap;
GVAR(civilianRegistry)  = createHashMap;
GVAR(spatialGrid)       = createHashMap;
GVAR(profileCounter)    = 0;

// Mark core as initialized
GVAR(initialized) set ["core", true];

// Fire init complete event — other modules listen for this
["ATLAS_core_initialized", []] call CBA_fnc_localEvent;

["Core", "INFO", "Core framework initialized successfully."] call FUNC(log);
