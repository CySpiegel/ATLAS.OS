// ============================================================================
// ATLAS.OS C2 (Command & Control) — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::C2] Pre-initialization starting...";

// Register module
[
    "c2",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "markers", "reports"]],
        ["provides", ["c2Tablet", "commandControl", "intelDisplay"]],
        ["events", [
            "ATLAS_c2_tabletOpened",
            "ATLAS_c2_tabletClosed",
            "ATLAS_c2_intelRefreshed"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// ---------------------------------------------------------------------------
// CBA Settings — Command & Control
// ---------------------------------------------------------------------------

// C2 Tablet Keybind (registered as CBA keybind in postInit)

// Show real-time intel
[
    "ATLAS_c2_showRealTimeIntel",
    "CHECKBOX",
    ["Show Real-Time Intel", "When enabled, the C2 tablet displays live intelligence data: real-time unit positions, active engagements, and objective statuses. When disabled, intel is based on the last known report — positions may be stale. Enable for arcade-style play, disable for realistic fog-of-war."],
    ["ATLAS.OS", "C2 Tablet"],
    true,
    0,
    {}
] call CBA_fnc_addSetting;

// Intel refresh rate
[
    "ATLAS_c2_intelRefreshRate",
    "SLIDER",
    ["Intel Refresh Rate (s)", "How often the C2 tablet refreshes its intelligence display (5-60 seconds). Only relevant when real-time intel is enabled. Lower values provide smoother updates but increase network traffic. Higher values reduce bandwidth but data may appear jumpy."],
    ["ATLAS.OS", "C2 Tablet"],
    [5, 60, 10, 0],
    0,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::C2] Pre-initialization complete.";
