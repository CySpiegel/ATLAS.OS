#include "script_component.hpp"

class CfgPatches {
    class atlas_persistence {
        name = "ATLAS.OS - Persistence";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_Persistence"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_persistence {
        tag = "atlas_persistence";
        class persistence {
            file = "\z\atlas\addons\atlas_persistence\functions";
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
    };

    class ATLAS_Module_Persistence : ATLAS_ModuleBase {
        scope = 2;
        displayName = "Persistence";
        icon = "\a3\Modules_F\data\iconModule_ca.paa";
        picture = "\a3\Modules_F\data\iconModule_ca.paa";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Core";
        function = "atlas_persistence_fnc_moduleInit";
        functionPriority = 10;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 0;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_persistence_backend : Combo {
                property = "ATLAS_persistence_backend";
                displayName = "Storage Backend";
                tooltip = "Select where persistent data is stored.\n\nProfileNamespace: Uses Arma 3's built-in profile storage. No additional setup required. Data persists between server restarts but is limited in size and tied to the server profile. Best for singleplayer or small-scale coop.\n\nExtension: Uses an external database extension (extDB3/ArmAlytics) for persistence. Requires the extension to be installed and configured on the server. Supports larger datasets, concurrent access, and external tools. Recommended for dedicated servers.";
                typeName = "STRING";
                defaultValue = """profileNamespace""";
                class Values {
                    class ProfileNamespace {
                        name = "ProfileNamespace";
                        value = "profileNamespace";
                    };
                    class Extension {
                        name = "Extension (extDB3)";
                        value = "extension";
                    };
                };
            };

            class ATLAS_persistence_autoSaveInterval : Edit {
                property = "ATLAS_persistence_autoSaveInterval";
                displayName = "Auto-Save Interval (s)";
                tooltip = "Time in seconds between automatic save operations (60-600). Each save captures the full state: all profiles, objectives, OPCOM state, and player progress. Lower values (60-120s) provide better data safety but cause brief server hitches during save. Higher values (300-600s) reduce save overhead but risk more data loss on crash. Recommended: 180s for dedicated servers, 300s for hosted servers.";
                typeName = "NUMBER";
                defaultValue = "180";
            };

            class ATLAS_persistence_autoSaveEnabled : CheckboxNumber {
                property = "ATLAS_persistence_autoSaveEnabled";
                displayName = "Enable Auto-Save";
                tooltip = "When enabled, the persistence system automatically saves at the configured interval. When disabled, saves only occur on mission end or manual admin trigger. Disable if you want full manual control over save timing or if the mission has its own save logic.";
                typeName = "NUMBER";
                defaultValue = "1";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Persistence saves and restores the entire ATLAS.OS state between server restarts. This includes all profiled units, objective ownership, OPCOM decisions, vehicle states, and player progress. Place one Persistence module in your mission to enable persistent warfare. The module automatically saves at the configured interval and restores state when the mission restarts. On first run, no data is loaded and the mission starts fresh. Subsequent restarts pick up exactly where they left off.";
            sync[] = {};
        };
    };
};
