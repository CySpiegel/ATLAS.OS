#include "script_component.hpp"

class CfgPatches {
    class atlas_insertion {
        name = "ATLAS.OS - Insertion / Multispawn";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_Insertion"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_insertion {
        tag = "atlas_insertion";
        class insertion {
            file = "\z\atlas\addons\atlas_insertion\functions";
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

    class ATLAS_Module_Insertion : ATLAS_ModuleBase {
        scope = 2;
        displayName = "Insertion / Multispawn";
        icon = "\a3\Modules_F\data\iconModule_ca.paa";
        picture = "\a3\Modules_F\data\iconModule_ca.paa";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Support";
        function = "atlas_insertion_fnc_moduleInit";
        functionPriority = 5;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_insertion_name : Edit {
                property = "ATLAS_insertion_name";
                displayName = "Spawn Name";
                tooltip = "A human-readable name for this spawn point, shown in the spawn selection screen. Examples: 'FOB Alpha', 'Main Base', 'Rally Point North', 'HALO Insert'. Choose descriptive names so players can easily identify where each spawn point is located. Each insertion module should have a unique name.";
                typeName = "STRING";
                defaultValue = """Insertion Point""";
            };

            class ATLAS_insertion_default : CheckboxNumber {
                property = "ATLAS_insertion_default";
                displayName = "Is Default Spawn";
                tooltip = "When enabled, this insertion point is the default spawn location for players joining the mission. Only one insertion module should be marked as default — if multiple are set, the first one processed is used. The default spawn is automatically selected in the spawn screen for new players and JIP (Join In Progress) players.";
                typeName = "NUMBER";
                defaultValue = "0";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Insertion / Multispawn creates a selectable spawn point for players. When multiple Insertion modules are placed, players see a spawn selection screen on respawn where they can choose their insertion point. The module position defines the exact spawn location. Mark one module as 'Is Default Spawn' to set the initial spawn point. Additional spawn points can be unlocked during the mission via scripting or by syncing to objectives. Place the module at safe locations like FOBs, airfields, or rally points.";
            sync[] = {};
        };
    };
};
