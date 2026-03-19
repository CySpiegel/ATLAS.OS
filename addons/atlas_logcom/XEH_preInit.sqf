// ============================================================================
// ATLAS.OS Logistics Command — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::LogCom] Pre-initialization starting...";

// Register module
[
    "logcom",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["logistics", "resupply", "reinforcements"]],
        ["events", [
            "ATLAS_logcom_resupplyDispatched",
            "ATLAS_logcom_resupplyComplete",
            "ATLAS_logcom_reinforcementDispatched"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// Active convoys
ATLAS_logcom_convoys = [];

// ---------------------------------------------------------------------------
// CBA Settings — Logistics Command
// ---------------------------------------------------------------------------

// Convoy speed
[
    "ATLAS_logcom_convoySpeed",
    "LIST",
    ["Convoy Speed", "Default movement speed for AI logistics convoys.\n\nLIMITED: Slow, cautious movement. Convoys stop at intersections and are less likely to crash. Best for dangerous routes.\n\nNORMAL: Standard road speed. Good balance of safety and efficiency.\n\nFULL: Maximum speed. Convoys reach destinations faster but may suffer accidents or be more vulnerable to ambush."],
    ["ATLAS.OS", "Logistics"],
    [["LIMITED", "NORMAL", "FULL"], ["Limited (Cautious)", "Normal", "Full Speed"], 1],
    1,
    {}
] call CBA_fnc_addSetting;

// Resupply threshold
[
    "ATLAS_logcom_resupplyThreshold",
    "SLIDER",
    ["Resupply Threshold", "Ammunition level (0.0-1.0) at which a group automatically requests resupply. When a profiled group's average ammo level drops below this threshold, a resupply request is generated. 0.3 means resupply when 30% ammo remains. Lower values let groups fight longer before resupply; higher values ensure groups are always well-supplied. Recommended: 0.3 for realistic logistics, 0.5 for casual play."],
    ["ATLAS.OS", "Logistics"],
    [0, 1, 0.3, 2],
    1,
    {}
] call CBA_fnc_addSetting;

// Enable reinforcements
[
    "ATLAS_logcom_reinforcementsEnabled",
    "CHECKBOX",
    ["Enable Reinforcements", "When enabled, the logistics system can spawn replacement units for destroyed groups. Reinforcements are generated at rear-area positions and move forward to reinforce depleted objectives. This keeps the battlefield populated over long operations. Disable for finite-forces scenarios where losses are permanent."],
    ["ATLAS.OS", "Logistics"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::LogCom] Pre-initialization complete.";
