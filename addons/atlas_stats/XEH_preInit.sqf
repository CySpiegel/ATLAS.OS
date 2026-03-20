// ============================================================================
// ATLAS.OS Statistics — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "stats",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["statistics", "tracking"]],
        ["events", [
            "ATLAS_stats_updated",
            "ATLAS_stats_saved"
        ]]
    ]
] call EFUNC(main,registerModule);

// Statistics store
GVAR(data) = createHashMap;

// ---------------------------------------------------------------------------
// CBA Settings — Statistics
// ---------------------------------------------------------------------------

// Enable stat tracking
[
    "ATLAS_stats_enabled",
    "CHECKBOX",
    ["Enable Stat Tracking", "When enabled, ATLAS tracks combat statistics per side: kills, losses, vehicles destroyed, objectives captured/lost, and force ratios over time. Statistics are available via the C2 tablet and admin panel. Disable to reduce server processing overhead in performance-critical scenarios."],
    ["ATLAS.OS", "Statistics"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

// Stat save interval
[
    "ATLAS_stats_saveInterval",
    "SLIDER",
    ["Stat Save Interval (s)", "How often statistics are saved to the persistence backend (60-600 seconds). Statistics are accumulated in memory and periodically flushed to storage. Lower values provide more granular data but increase I/O load. Higher values are more efficient but risk losing recent data on crash."],
    ["ATLAS.OS", "Statistics"],
    [60, 600, 300, 0],
    1,
    {}
] call CBA_fnc_addSetting;

LOG("Pre-initialization complete.");
