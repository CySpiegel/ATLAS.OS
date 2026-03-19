// ============================================================================
// ATLAS.OS Core — Pre-Initialization
// ============================================================================
// Runs before mission start, unscheduled environment.
// Initializes registries, spatial grid, CBA settings, and event bus.
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS] Core pre-initialization starting...";

// ---------------------------------------------------------------------------
// 1. Core Registries (HashMap of HashMaps)
// ---------------------------------------------------------------------------
ATLAS_profileRegistry   = createHashMap;  // profileID -> profile HashMap
ATLAS_objectiveRegistry = createHashMap;  // objectiveID -> objective HashMap
ATLAS_civilianRegistry  = createHashMap;  // civID -> civilian HashMap
ATLAS_moduleRegistry    = createHashMap;  // moduleName -> module config HashMap
ATLAS_spatialGrid       = createHashMap;  // "gridCell" -> array of profile IDs

// Profile ID counter
ATLAS_profileCounter = 0;

// Module initialization tracking
ATLAS_initialized = createHashMap;

// Version info
ATLAS_version = "0.1.0";
ATLAS_versionAr = [0,1,0,0];

// ---------------------------------------------------------------------------
// 2. CBA Settings Registration
// ---------------------------------------------------------------------------
// Category: ATLAS.OS > Core

// Debug Mode — enables verbose logging across all modules
[
    "ATLAS_setting_debugMode",
    "CHECKBOX",
    ["Debug Mode", "Enable verbose debug logging for all ATLAS.OS modules. Useful for development and troubleshooting. Performance impact when enabled."],
    ["ATLAS.OS", "Core"],
    false,
    1,  // server setting
    {}
] call CBA_fnc_addSetting;

// Log Level — controls which log messages are output
[
    "ATLAS_setting_logLevel",
    "LIST",
    ["Log Level", "Controls the verbosity of ATLAS.OS log output to RPT. Higher levels include all lower levels."],
    ["ATLAS.OS", "Core"],
    [[0, 1, 2, 3], ["ERROR", "WARNING", "INFO", "DEBUG"], 2],
    1,
    {}
] call CBA_fnc_addSetting;

// Spatial Grid Cell Size — affects spatial query performance
[
    "ATLAS_setting_gridSize",
    "SLIDER",
    ["Grid Cell Size (m)", "Size of spatial grid cells in meters. Smaller = more precise queries but more memory. Larger = fewer cells but more candidates per query. Requires mission restart to take effect."],
    ["ATLAS.OS", "Core"],
    [100, 1000, 500, 0],
    1,
    {},
    true  // needs mission restart
] call CBA_fnc_addSetting;

// Performance Monitor — per-frame diagnostics overlay
[
    "ATLAS_setting_perfMonitor",
    "CHECKBOX",
    ["Performance Monitor", "Show real-time performance diagnostics overlay. Displays frame time budget usage, active profile count, and spatial grid statistics."],
    ["ATLAS.OS", "Core"],
    false,
    0,  // client setting
    {}
] call CBA_fnc_addSetting;

// Max Profiles Warning Threshold
[
    "ATLAS_setting_maxProfilesWarn",
    "SLIDER",
    ["Profile Warning Threshold", "Log a warning when total profile count exceeds this number. Helps identify missions approaching performance limits."],
    ["ATLAS.OS", "Core"],
    [50, 2000, 500, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// ---------------------------------------------------------------------------
// 3. Event Bus Initialization
// ---------------------------------------------------------------------------
// Register core event taxonomy - these are the canonical event names
// Modules will subscribe to these in their own preInit

// Verify CBA event system is available
if (isNil "CBA_fnc_addEventHandler") exitWith {
    diag_log "[ATLAS] FATAL: CBA_A3 not detected. ATLAS.OS requires CBA_A3 3.16+.";
};

diag_log format ["[ATLAS] Core pre-initialization complete. Version: %1", ATLAS_version];
