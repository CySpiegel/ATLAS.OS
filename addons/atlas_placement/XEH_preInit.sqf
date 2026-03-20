#include "script_component.hpp"

LOG("PreInit starting");

// Compile all functions
PREP(moduleInit);
PREP(init);
PREP(processModule);
PREP(readObjectivesFromEditor);
PREP(determineForceComposition);
PREP(getClassnames);
PREP(createForcesForObjective);
PREP(placeInfantry);
PREP(placeArmor);
PREP(getFactionsForSide);

// Register module
[
    "placement",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main", "profile"]],
        ["provides", ["militaryPlacement", "forceGeneration"]],
        ["events", [
            "ATLAS_placement_complete"
        ]]
    ]
] call EFUNC(main,registerModule);

// Placement instance registry
GVAR(instances) = [];

LOG("PreInit complete");
