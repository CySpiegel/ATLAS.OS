// ============================================================================
// ATLAS.OS Cargo System — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "cargo",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["cargoLoading", "slingLoading"]],
        ["events", [
            "ATLAS_cargo_loaded",
            "ATLAS_cargo_unloaded",
            "ATLAS_cargo_slingAttached",
            "ATLAS_cargo_slingDetached"
        ]]
    ]
] call EFUNC(main,registerModule);

// ---------------------------------------------------------------------------
// CBA Settings — Cargo System
// ---------------------------------------------------------------------------

// Max cargo weight
[
    "ATLAS_cargo_maxWeight",
    "SLIDER",
    ["Max Cargo Weight (kg)", "Maximum weight in kilograms that can be loaded into a vehicle's cargo space. This applies on top of each vehicle's native cargo capacity. Heavier loads slow vehicles and affect handling. Recommended: 500 for light vehicles, 2000 for trucks, 5000 for heavy transport."],
    ["ATLAS.OS", "Cargo & Logistics"],
    [100, 5000, 2000, 0],
    1,
    {}
] call CBA_fnc_addSetting;

// Enable sling loading
[
    "ATLAS_cargo_slingEnabled",
    "CHECKBOX",
    ["Enable Sling Loading", "When enabled, helicopters can sling-load compatible cargo objects (supply crates, vehicles, static weapons). Adds sling-load actions to helicopter crews. Uses the ATLAS weight system to determine if a helicopter can carry the selected cargo. Disable if using another sling-load mod."],
    ["ATLAS.OS", "Cargo & Logistics"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

LOG("Pre-initialization complete.");
