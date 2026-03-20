// ============================================================================
// ATLAS.OS Weather System — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "weather",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["weatherPersistence", "weatherSync"]],
        ["events", [
            "ATLAS_weather_changed"
        ]]
    ]
] call EFUNC(main,registerModule);

// ---------------------------------------------------------------------------
// CBA Settings — Weather System
// ---------------------------------------------------------------------------

// Enable weather persistence
[
    "ATLAS_weather_persistenceEnabled",
    "CHECKBOX",
    ["Enable Weather Persistence", "When enabled, weather state is saved and restored between mission restarts. The current overcast, rain, fog, and wind values are persisted alongside other ATLAS data. When disabled, weather starts fresh each mission based on Eden Editor settings."],
    ["ATLAS.OS", "Weather"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

// Weather change speed multiplier
[
    "ATLAS_weather_changeSpeed",
    "SLIDER",
    ["Weather Change Speed", "Multiplier for how quickly weather transitions occur (0.1-5.0). At 1.0, weather changes at the default Arma 3 rate. Lower values (0.1-0.5) create very slow, gradual weather shifts — good for long operations. Higher values (2.0-5.0) create rapid weather changes — good for dynamic, shorter missions."],
    ["ATLAS.OS", "Weather"],
    [0.1, 5.0, 1.0, 1],
    1,
    {}
] call CBA_fnc_addSetting;

// Force weather sync for JIP
[
    "ATLAS_weather_forceSync",
    "CHECKBOX",
    ["Force Weather Sync", "When enabled, forces weather synchronization for all clients including JIP (Join In Progress) players. Ensures everyone sees the same weather conditions. Disable only if you have custom weather scripts that handle synchronization."],
    ["ATLAS.OS", "Weather"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

LOG("Pre-initialization complete.");
