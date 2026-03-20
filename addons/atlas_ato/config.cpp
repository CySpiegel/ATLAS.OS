#include "script_component.hpp"

class CfgPatches {
    class atlas_ato {
        name = "ATLAS.OS - Air Tasking Order (ATO)";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_ATO"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_ato {
        tag = "atlas_ato";
        class ato {
            file = "\z\atlas\addons\atlas_ato\functions";
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

    class ATLAS_Module_ATO : Module_F {
        scope = 2;
        displayName = "Air Tasking Order (ATO)";
        icon = "\z\atlas\addons\atlas_ato\ui\icon.png";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Military";
        function = "ATLAS_fnc_ato_moduleInit";
        functionPriority = 3;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_ato_side : Combo {
                property = "ATLAS_ato_side";
                displayName = "Side";
                tooltip = "The side that owns this air tasking order. Aircraft from this ATO will support ground forces of the same side. Should match the OPCOM side for coordinated air-ground operations.";
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

            class ATLAS_ato_aircraft : Edit {
                property = "ATLAS_ato_aircraft";
                displayName = "Aircraft Types";
                tooltip = "Comma-separated list of aircraft classnames available for tasking. These aircraft will be spawned and assigned missions (CAS, transport, reconnaissance, CAP) by the OPCOM or on-demand. Examples: 'B_Heli_Attack_01_dynamicLoadout_F, B_Plane_CAS_01_dynamicLoadout_F' for BLUFOR attack assets, or 'O_Heli_Light_02_dynamicLoadout_F, O_Plane_CAS_02_dynamicLoadout_F' for OPFOR. Leave empty to auto-detect from faction config.";
                typeName = "STRING";
                defaultValue = """""";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Air Tasking Order (ATO) manages all air operations for a side. It maintains an aircraft roster, assigns missions (Close Air Support, Combat Air Patrol, Transport, Reconnaissance), manages sortie scheduling, and handles aircraft rearming/refueling cycles. The ATO works best when synced to an OPCOM module, which will automatically request air support for ground operations. Multiple ATO modules can be placed for different sides. Sync to an OPCOM to enable integrated air-ground operations.";
            sync[] = {"ATLAS_Module_OPCOM"};
        };
    };
};
