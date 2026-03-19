// ============================================================================
// ATLAS.OS Compatibility Layer — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Compat] Pre-initialization starting...";

// Register module
[
    "compat",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["compatibility", "migration"]],
        ["events", [
            "ATLAS_compat_migrationComplete",
            "ATLAS_compat_warningIssued"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// ---------------------------------------------------------------------------
// CBA Settings — Compatibility
// ---------------------------------------------------------------------------

// Show migration warnings
[
    "ATLAS_compat_showWarnings",
    "CHECKBOX",
    ["Show Migration Warnings", "When enabled, displays warnings in the RPT log and optionally on-screen when deprecated features, classnames, or API calls are detected. Useful during upgrades between ATLAS.OS versions to identify what needs updating in your missions. Disable once your mission is fully migrated to reduce log noise."],
    ["ATLAS.OS", "Compatibility"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::Compat] Pre-initialization complete.";
