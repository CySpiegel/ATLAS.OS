// ============================================================================
// ATLAS.OS Profile Handler — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::Profile] Pre-initialization starting...";

// Register module
[
    "profile",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["profileRegistry", "spatialQuery", "spawnDespawn"]],
        ["events", [
            "ATLAS_profile_created",
            "ATLAS_profile_destroyed",
            "ATLAS_profile_spawned",
            "ATLAS_profile_despawned",
            "ATLAS_profile_updated"
        ]]
    ]
] call ATLAS_fnc_registerModule;

// ---------------------------------------------------------------------------
// CBA Settings — Profile Handler
// ---------------------------------------------------------------------------

// Spawn Distance
[
    "ATLAS_profile_spawnDistance",
    "SLIDER",
    ["Spawn Distance (m)", "Distance in meters at which profiled groups are spawned into the game world when players approach. Lower values improve performance but units appear closer. Higher values provide smoother immersion but increase active unit count. Must be less than Despawn Distance. Recommended: 1200-1800m."],
    ["ATLAS.OS", "Profile Handler"],
    [500, 3000, 1500, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// Despawn Distance
[
    "ATLAS_profile_despawnDistance",
    "SLIDER",
    ["Despawn Distance (m)", "Distance in meters at which spawned groups are converted back to profiles when all players are beyond this range. Must be greater than Spawn Distance to prevent rapid spawn/despawn cycling (hysteresis). Recommended: 300-500m greater than spawn distance."],
    ["ATLAS.OS", "Profile Handler"],
    [750, 4000, 1800, 0],
    1,
    {}
] call CBA_fnc_addSetting;

diag_log "[ATLAS::Profile] Pre-initialization complete.";
