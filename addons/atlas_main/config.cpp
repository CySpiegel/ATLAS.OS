#include "script_component.hpp"

class CfgPatches {
    class atlas_main {
        name = "ATLAS.OS - Core";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_ModuleMain"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"cba_main", "cba_settings", "cba_xeh"};
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

// --- Eden Editor Module Category ---
class CfgFactionClasses {
    class NO_CATEGORY;
    class ATLAS_Modules {
        displayName = "ATLAS.OS";
        priority = 2;
        side = 7;
    };
};

class CfgVehicleClasses {
    class ATLAS_Core {
        displayName = "Core Systems";
        faction = "ATLAS_Modules";
    };
    class ATLAS_Military {
        displayName = "Military";
        faction = "ATLAS_Modules";
    };
    class ATLAS_Civilian {
        displayName = "Civilian";
        faction = "ATLAS_Modules";
    };
    class ATLAS_Support {
        displayName = "Player Support";
        faction = "ATLAS_Modules";
    };
    class ATLAS_Admin {
        displayName = "Administration";
        faction = "ATLAS_Modules";
    };
};

// --- Eden Editor Module: ATLAS Core ---
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

    class ATLAS_ModuleMain : Module_F {
        scope = 2;
        displayName = "ATLAS Core (Required)";
        icon = "";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Core";
        function = "atlas_main_fnc_init";
        functionPriority = 0;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;
        curatorCanAttach = 0;

        class Attributes : AttributesBase {
            class ATLAS_main_debugMode : CheckboxNumber {
                property = "ATLAS_main_debugMode";
                displayName = "Debug Mode";
                tooltip = "Enable verbose debug logging for this mission. Overrides the CBA setting.";
                typeName = "NUMBER";
                defaultValue = "0";
            };
            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Required foundation module for ATLAS.OS. Place exactly one in every mission. Initializes all core registries, spatial grid, event bus, and module loader. Must load before any other ATLAS module.";
            sync[] = {};
        };
    };
};
