#include "script_component.hpp"

LOG("PreInit starting");

// Compile all functions
PREP(init);
PREP(create);
PREP(destroy);
PREP(spawn);
PREP(despawn);
PREP(checkSpawnDespawn);
PREP(getByID);
PREP(getBySide);
PREP(getByArea);
PREP(getByObjective);
PREP(getSpawned);
PREP(getVirtual);
PREP(getUnitCount);
PREP(setPosition);
PREP(addWaypoint);
PREP(removeWaypoint);
PREP(processWaypoints);
PREP(updateState);
PREP(serialize);
PREP(deserialize);

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
            "ATLAS_profile_moved",
            "ATLAS_profile_stateChanged"
        ]]
    ]
] call EFUNC(main,registerModule);

// CBA Settings
[
    "ATLAS_profile_spawnDistance",
    "SLIDER",
    ["Spawn Distance (m)", "Distance at which virtual profiles spawn into real AI units when players approach."],
    ["ATLAS.OS", "Profile"],
    [500, 3000, 1500, 0],
    1,
    {}
] call CBA_fnc_addSetting;

[
    "ATLAS_profile_despawnDistance",
    "SLIDER",
    ["Despawn Distance (m)", "Distance beyond which spawned groups revert to virtual profiles. Must exceed spawn distance for hysteresis."],
    ["ATLAS.OS", "Profile"],
    [750, 4000, 1800, 0],
    1,
    {}
] call CBA_fnc_addSetting;

LOG("PreInit complete");
