// ============================================================================
// ATLAS.OS Map Markers — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Markers] Pre-initialization starting...";

// Register module
[
    "markers",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["mapMarkers", "situationalAwareness"]],
        ["events", [
            "ATLAS_markers_updated"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// Marker registry
ATLAS_markers_registry = createHashMap;

// ---------------------------------------------------------------------------
// CBA Settings — Map Markers
// ---------------------------------------------------------------------------

// Show friendly markers
[
    "ATLAS_markers_showFriendly",
    "CHECKBOX",
    ["Show Friendly Markers", "Display NATO tactical symbols for friendly profiled units on the map. Shows unit type, size, and movement direction. Useful for commanders to track friendly force disposition. Disable for a more challenging, limited-information experience."],
    ["ATLAS.OS", "Map Markers"],
    true,
    0,
    {}
] call CBA_fnc_addSetting;

// Show enemy markers
[
    "ATLAS_markers_showEnemy",
    "CHECKBOX",
    ["Show Enemy Markers", "Display known/suspected enemy positions on the map based on intelligence reports and contact reports. Enemy markers have a confidence level that degrades over time without fresh intel. Disable for hardcore gameplay where players must rely solely on their own reconnaissance."],
    ["ATLAS.OS", "Map Markers"],
    false,
    0,
    {}
] call CBA_fnc_addSetting;

// Marker update interval
[
    "ATLAS_markers_updateInterval",
    "SLIDER",
    ["Marker Update Interval (s)", "How often map markers are refreshed to reflect current unit positions (5-60 seconds). Lower values provide near-real-time tracking but increase client processing. Higher values reduce overhead but markers may lag behind actual positions. Recommended: 10s for real-time ops, 30s for general play."],
    ["ATLAS.OS", "Map Markers"],
    [5, 60, 15, 0],
    0,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::Markers] Pre-initialization complete.";
