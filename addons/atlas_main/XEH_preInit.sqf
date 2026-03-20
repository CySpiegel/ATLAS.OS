#include "script_component.hpp"

// Compile all functions
PREP(init);
PREP(moduleInit);
PREP(log);
PREP(gridInsert);
PREP(gridRemove);
PREP(gridQuery);
PREP(gridMove);
PREP(gridUpdate);
PREP(hashToArray);
PREP(arrayToHash);
PREP(nextID);
PREP(registerModule);
PREP(setting);
PREP(serialize);
PREP(deserialize);
PREP(validateProfile);
PREP(initScheduler);
PREP(schedulerTick);
PREP(autoBudget);

LOG("PreInit starting");

// Self-register main module FIRST (other modules check for "main" in their deps)
[
    "main",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", []],
        ["provides", ["registries", "spatialGrid", "eventBus", "moduleLoader"]],
        ["events", ["ATLAS_core_initialized", "ATLAS_module_registered", "ATLAS_player_areaChanged"]]
    ]
] call FUNC(registerModule);

// Core Registries
GVAR(profileRegistry)   = createHashMap;
GVAR(objectiveRegistry) = createHashMap;
GVAR(civilianRegistry)  = createHashMap;
GVAR(moduleRegistry)    = createHashMap;
GVAR(spatialGrid)       = createHashMap;
GVAR(baseRegistry)      = createHashMap;
GVAR(hcRegistry)        = createHashMap;
GVAR(intelRegistry)     = createHashMap;
GVAR(profileCounter)    = 0;
GVAR(initialized)       = createHashMap;
GVAR(version)           = "0.1.0";
GVAR(gridSize)          = ATLAS_GRID_SIZE_DEFAULT;

// CBA Settings — Core
[
    QGVAR(debugMode),
    "CHECKBOX",
    ["Debug Mode", "Enable verbose debug logging for all ATLAS.OS modules."],
    ["ATLAS.OS", "Core"],
    false,
    1,
    {}
] call CBA_fnc_addSetting;

[
    QGVAR(logLevel),
    "LIST",
    ["Log Level", "Controls log verbosity. Higher levels include all lower levels."],
    ["ATLAS.OS", "Core"],
    [[0, 1, 2, 3], ["ERROR", "WARNING", "INFO", "DEBUG"], 2],
    1,
    {}
] call CBA_fnc_addSetting;

[
    QGVAR(gridSize),
    "SLIDER",
    ["Grid Cell Size (m)", "Spatial grid cell size. Smaller = more precise, more memory. Requires restart."],
    ["ATLAS.OS", "Core"],
    [100, 1000, 500, 0],
    1,
    {
        params ["_value"];
        GVAR(gridSize) = _value;
    },
    true
] call CBA_fnc_addSetting;

[
    QGVAR(perfMonitor),
    "CHECKBOX",
    ["Performance Monitor", "Show real-time performance overlay with profile count, grid stats, FPS."],
    ["ATLAS.OS", "Core"],
    false,
    0,
    {}
] call CBA_fnc_addSetting;

[
    QGVAR(maxProfilesWarn),
    "SLIDER",
    ["Profile Warning Threshold", "Log warning when profile count exceeds this."],
    ["ATLAS.OS", "Core"],
    [50, 2000, 500, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// --- Scheduler Settings ---
[
    QGVAR(schedulerTargetFPS),
    "SLIDER",
    ["Scheduler Target FPS", "Auto-budget keeps server FPS above this. Lower = more processing budget, higher = smoother frames."],
    ["ATLAS.OS", "Performance"],
    [20, 60, 40, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    QGVAR(schedulerFramePct),
    "SLIDER",
    ["Scheduler Frame %", "Max percentage of frame time the scheduler can use. 10-15% for listen server, 20-30% for dedicated."],
    ["ATLAS.OS", "Performance"],
    [5, 50, 15, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// Performance tier state
GVAR(performanceTier) = "NORMAL";

LOG("PreInit complete");
