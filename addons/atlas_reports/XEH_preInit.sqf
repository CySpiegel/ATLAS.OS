// ============================================================================
// ATLAS.OS Reporting System — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "reports",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["spotReports", "sitReports", "intelReports"]],
        ["events", [
            "ATLAS_reports_spotrepGenerated",
            "ATLAS_reports_sitrepGenerated"
        ]]
    ]
] call EFUNC(main,registerModule);

// Report log
GVAR(log) = [];

// ---------------------------------------------------------------------------
// CBA Settings — Reporting
// ---------------------------------------------------------------------------

// Auto SPOTREP
[
    "ATLAS_reports_autoSpotrep",
    "CHECKBOX",
    ["Enable Auto SPOTREP", "When enabled, automatic SPOT reports are generated when friendly units make contact with the enemy. Reports include enemy position, size estimate, activity, and unit type. Reports are displayed in the C2 tablet and can be shown on the map. Disable for manual-only reporting in hardcore milsim."],
    ["ATLAS.OS", "Reports"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

// SITREP interval
[
    "ATLAS_reports_sitrepInterval",
    "SLIDER",
    ["SITREP Interval (s)", "Time in seconds between automatic situation reports (300-3600). SITREPs summarize the overall tactical situation: objectives held, force strength, recent contacts, and recommended actions. Shown in the C2 tablet. Lower values provide more frequent updates; higher values reduce information overload."],
    ["ATLAS.OS", "Reports"],
    [300, 3600, 900, 0],
    1,
    {}
] call CBA_fnc_addSetting;

LOG("Pre-initialization complete.");
