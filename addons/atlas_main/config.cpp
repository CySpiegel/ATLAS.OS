#include "script_component.hpp"

class CfgPatches {
    class atlas_main {
        name = "ATLAS.OS - Core";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_ModuleMain"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"cba_main", "cba_settings", "cba_xeh", "A3_Modules_F"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_main {
        tag = "atlas_main";
        class main {
            file = "\z\atlas\addons\atlas_main\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"

// --- Eden Editor: ATLAS.OS Faction (side 7 = Logic) ---
class CfgFactionClasses {
    class NO_CATEGORY;
    class ATLAS_Modules : NO_CATEGORY {
        displayName = "ATLAS.OS";
        priority = 1;
        side = 7;
    };
};

// --- Eden Editor: Module Definitions ---
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

    // Base class for all ATLAS modules — scope 1 (hidden)
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

    class ATLAS_ModuleMain : ATLAS_ModuleBase {
        scope = 2;
        displayName = "ATLAS - Required";
        icon = "\a3\Modules_F\data\iconModule_ca.paa";
        picture = "\a3\Modules_F\data\iconModule_ca.paa";
        function = "atlas_main_fnc_moduleInit";
        functionPriority = 0;

        class Attributes : AttributesBase {
            class ATLAS_main_debugMode : CheckboxNumber {
                property = "ATLAS_main_debugMode";
                displayName = "Debug Mode";
                tooltip = "Enable verbose debug logging for this mission.";
                typeName = "NUMBER";
                defaultValue = "0";
            };
            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Required foundation module for ATLAS.OS. Place exactly one in every mission. Initializes all core registries, spatial grid, event bus, and module loader.";
            sync[] = {};
        };
    };
};
