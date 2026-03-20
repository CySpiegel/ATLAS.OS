#include "script_component.hpp"

class CfgPatches {
    class atlas_civilian {
        name = "ATLAS.OS - Civilian Population";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_Civilian"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_civilian {
        tag = "atlas_civilian";
        class civilian {
            file = "\z\atlas\addons\atlas_civilian\functions";
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

    class ATLAS_Module_Civilian : Module_F {
        scope = 2;
        displayName = "Civilian Population";
        icon = "\z\atlas\addons\atlas_civilian\ui\icon.png";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Civilian";
        function = "ATLAS_fnc_civilian_moduleInit";
        functionPriority = 4;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 1;
        canSetAreaShape = 0;

        class AttributeValues {
            isRectangle = 0;
            size3[] = {500, 500, -1};
        };

        class Attributes : AttributesBase {
            class ATLAS_civilian_density : Edit {
                property = "ATLAS_civilian_density";
                displayName = "Civilian Density";
                tooltip = "Density multiplier (0.0-3.0) controlling how many civilians populate the area. This multiplier is applied to the base density calculated from building count and road density.\n\n0.0: No civilians (ghost town).\n0.5: Sparse population, conflict zone feel.\n1.0: Normal population density.\n1.5-2.0: Busy urban environment.\n2.5-3.0: Crowded city center, market day.\n\nHigher values increase server load proportionally. Recommended: 1.0 for most scenarios, 0.5 for active combat zones.";
                typeName = "NUMBER";
                defaultValue = "1.0";
            };

            class ATLAS_civilian_maxAmbient : Edit {
                property = "ATLAS_civilian_maxAmbient";
                displayName = "Max Ambient Civilians";
                tooltip = "Maximum number of civilian agents that can be active simultaneously around players (10-100). This is a hard cap to prevent performance degradation. Civilians are spawned nearest to players first. When the cap is reached, distant civilians are despawned to make room for closer ones. Recommended: 30 for hosted servers, 60 for dedicated servers, 100 only for high-end hardware.";
                typeName = "NUMBER";
                defaultValue = "40";
            };

            class ATLAS_civilian_faction : Edit {
                property = "ATLAS_civilian_faction";
                displayName = "Faction Classname";
                tooltip = "The civilian faction classname to use for spawned civilians. This determines their appearance (clothing, ethnicity, accessories). Examples: 'CIV_F' (Mediterranean civilians), 'CIV_IDAP_F' (IDAP aid workers). Use mod faction classnames for region-specific civilians. Leave empty for the default 'CIV_F'.";
                typeName = "STRING";
                defaultValue = """CIV_F""";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Civilian Population creates ambient civilian life in the mission area. Civilians walk along roads, congregate near markets and public buildings, drive vehicles, and react dynamically to combat (fleeing, cowering, or reporting to authorities). The module uses the ATLAS profiling system to manage civilians efficiently. Place this module over populated areas. Multiple modules can be used with different densities for different zones (e.g., higher density in city centers, lower in suburbs). Civilians are affected by combat — hostility scores increase when players harm civilians.";
            sync[] = {};
        };
    };
};
