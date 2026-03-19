#include "script_component.hpp"

class CfgPatches {
    class atlas_cqb {
        name = "ATLAS.OS - Close Quarters Battle (CQB)";
        author = AUTHOR;
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_CQB"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = VERSION;
        versionStr = VERSION_STR;
        versionAr[] = {VERSION_AR};
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"

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

    class ATLAS_Module_CQB : Module_F {
        scope = 2;
        displayName = "CQB Garrison";
        icon = "\z\atlas\addons\atlas_cqb\ui\icon_cqb_ca.paa";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Military";
        function = "ATLAS_fnc_cqb_moduleInit";
        functionPriority = 3;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 1;
        canSetAreaShape = 0;

        class AttributeValues {
            isRectangle = 0;
            size3[] = {300, 300, -1};
        };

        class Attributes : AttributesBase {
            class ATLAS_cqb_side : Combo {
                property = "ATLAS_cqb_side";
                displayName = "Side";
                tooltip = "The side of the garrisoned units. CQB units will be hostile to enemies of this side and friendly to allies. Should typically match the OPCOM side controlling this area.";
                typeName = "NUMBER";
                defaultValue = "0";
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

            class ATLAS_cqb_probability : Edit {
                property = "ATLAS_cqb_probability";
                displayName = "Spawn Probability";
                tooltip = "Probability (0.0-1.0) that each eligible building in the area will receive a garrison. 0.0 = no buildings garrisoned, 1.0 = all eligible buildings garrisoned. Low values (0.1-0.3): Sparse occupation, creates uncertainty for players clearing buildings. Medium values (0.4-0.6): Moderate density, recommended for most scenarios. High values (0.7-1.0): Heavy urban defense, very dangerous for attackers. Recommended: 0.3 for realism, 0.6 for intense CQB.";
                typeName = "NUMBER";
                defaultValue = "0.4";
            };

            class ATLAS_cqb_maxGarrison : Edit {
                property = "ATLAS_cqb_maxGarrison";
                displayName = "Max Garrison Size";
                tooltip = "Maximum number of AI units placed inside a single building (1-12). Larger buildings may receive more units up to this cap. Small residential buildings typically get 1-3 units, while large industrial or military buildings can hold up to the maximum. Lower values reduce performance impact and difficulty. Recommended: 4 for light resistance, 8 for fortified positions, 12 for heavily defended strongpoints.";
                typeName = "NUMBER";
                defaultValue = "6";
            };

            class ATLAS_cqb_radius : Edit {
                property = "ATLAS_cqb_radius";
                displayName = "Radius (m)";
                tooltip = "The radius in meters around the module position where buildings will be scanned for garrisoning. Only buildings within this radius are eligible for CQB placement. Larger radii cover more area but increase initial processing time. The module area (if set) overrides this value. Recommended: 200-400m for a small town, 500-800m for a city district.";
                typeName = "NUMBER";
                defaultValue = "300";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "CQB Garrison dynamically populates buildings with infantry units that hold defensive positions inside structures. Units are placed at building positions (windows, doorways, rooftops) and will engage enemies that approach or enter the building. CQB garrisons are spawned when players approach and despawned when players leave the area. Place this module in urban areas where you want building-to-building fighting. For best results, sync with an OPCOM module so garrisoned units coordinate with the overall defense.";
            sync[] = {"ATLAS_Module_OPCOM"};
        };
    };
};
