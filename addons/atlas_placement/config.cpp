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

    class ATLAS_ModuleBase : Module_F {
        scope = 1;
        category = "ATLAS_Modules";
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 1;
        curatorCanAttach = 1;
        author = "ATLAS.OS Team";
    };

    class ATLAS_Module_Placement : ATLAS_ModuleBase {
        scope = 2;
        displayName = "ATLAS - Military Placement";
        icon = "\a3\Modules_F\data\iconModule_ca.paa";
        picture = "\a3\Modules_F\data\iconModule_ca.paa";
        function = "atlas_placement_fnc_moduleInit";
        functionPriority = 2;

        class Attributes : AttributesBase {
            class ATLAS_placement_side : Combo {
                property = "ATLAS_placement_side";
                displayName = "Side";
                tooltip = "The side that the placed military forces belong to.";
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
                tooltip = "CfgFaction classname (e.g. BLU_F, OPF_F, IND_F).";
                typeName = "STRING";
                defaultValue = """BLU_F""";
            };

            class ATLAS_placement_size : Combo {
                property = "ATLAS_placement_size";
                displayName = "Force Size";
                tooltip = "Overall size of the military force placed across objectives.";
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
                tooltip = "When enabled, forces are placed only at synced objectives.";
                typeName = "NUMBER";
                defaultValue = "0";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Populates the battlefield with profiled military units. Sync to an OPCOM module for AI command. Multiple placement modules create multi-faction scenarios.";
            sync[] = {"ATLAS_Module_OPCOM"};
        };
    };
};
