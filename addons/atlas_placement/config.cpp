#include "script_component.hpp"

class CfgPatches {
    class atlas_placement {
        name = "ATLAS.OS - Military Placement";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_Placement"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_placement {
        tag = "atlas_placement";
        class placement {
            file = "\z\atlas\addons\atlas_placement\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"

class CfgVehicles {
    class Logic;
    class Module_F : Logic {
        class AttributesBase {
            class Default;
            class Edit;
            class Combo;
            class Checkbox;
            class CheckboxNumber;
            class ModuleDescription;
            class Units;
        };
        class ModuleDescription;
    };

    class ATLAS_Module_Placement : Module_F {
        scope = 2;
        displayName = "Military Placement";
        icon = "";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Military";
        function = "atlas_placement_fnc_moduleInit";
        functionPriority = 2;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_placement_side : Combo {
                property = "ATLAS_placement_side";
                displayName = "Side";
                tooltip = "The side that the placed military forces belong to. This determines allegiance, friend/foe identification, and which OPCOM can command these units. Ensure this matches the OPCOM module side if you want the AI commander to control these forces.";
                typeName = "NUMBER";
                defaultValue = "1";
                class Values {
                    class BLUFOR {
                        name = "BLUFOR";
                        value = 1;
                    };
                    class OPFOR {
                        name = "OPFOR";
                        value = 0;
                    };
                    class INDFOR {
                        name = "Independent";
                        value = 2;
                    };
                };
            };

            class ATLAS_placement_faction : Edit {
                property = "ATLAS_placement_faction";
                displayName = "Faction Classname";
                tooltip = "The CfgFaction classname to pull unit compositions from. This determines which specific uniforms, vehicles, and equipment the placed forces use. Examples: 'BLU_F' (NATO), 'OPF_F' (CSAT), 'IND_F' (AAF), 'BLU_CTRG_F' (CTRG). Must be a valid faction classname from your loaded mods. Leave empty to use the default faction for the selected side.";
                typeName = "STRING";
                defaultValue = """BLU_F""";
            };

            class ATLAS_placement_size : Combo {
                property = "ATLAS_placement_size";
                displayName = "Force Size";
                tooltip = "Determines the overall size of the military force to be placed across objectives.\n\nCompany (~120 units): Suitable for small-scale operations with 3-5 objectives. Good for cooperative missions with 4-8 players. Lower server performance impact.\n\nBattalion (~400 units): Medium-scale operations with 5-15 objectives. Recommended for 8-20 player missions. Moderate server load.\n\nBrigade (~1200 units): Large-scale warfare with 10-30+ objectives. Best for dedicated servers with 20+ players. High server performance impact — ensure adequate hardware.";
                typeName = "STRING";
                defaultValue = """company""";
                class Values {
                    class Company {
                        name = "Company (~120 units)";
                        value = "company";
                    };
                    class Battalion {
                        name = "Battalion (~400 units)";
                        value = "battalion";
                    };
                    class Brigade {
                        name = "Brigade (~1200 units)";
                        value = "brigade";
                    };
                };
            };

            class ATLAS_placement_objectivesOnly : CheckboxNumber {
                property = "ATLAS_placement_objectivesOnly";
                displayName = "Objectives Only";
                tooltip = "When enabled, forces are placed exclusively at synced objective markers/locations. When disabled, forces are distributed organically across the area of operations including patrols between objectives, roadblocks, observation posts, and reserve positions. Disable for more realistic force distribution; enable for tighter, more predictable gameplay.";
                typeName = "NUMBER";
                defaultValue = "0";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Military Placement populates the battlefield with profiled military units based on the selected faction and force size. Units are distributed across objectives and key terrain. Place this module and sync it to an OPCOM module to give the AI commander control of the placed forces. Multiple placement modules can be used to create multi-faction scenarios. Sync to specific trigger areas or objective markers to constrain placement regions.";
            sync[] = {"ATLAS_Module_OPCOM"};
        };
    };
};
