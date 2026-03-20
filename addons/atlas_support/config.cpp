#include "script_component.hpp"

class CfgPatches {
    class atlas_support {
        name = "ATLAS.OS - Combat Support";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_Support"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_support {
        tag = "atlas_support";
        class support {
            file = "\z\atlas\addons\atlas_support\functions";
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

    class ATLAS_Module_Support : Module_F {
        scope = 2;
        displayName = "Combat Support";
        icon = "\z\atlas\addons\atlas_support\ui\icon.png";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Support";
        function = "ATLAS_fnc_support_moduleInit";
        functionPriority = 5;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_support_type : Combo {
                property = "ATLAS_support_type";
                displayName = "Support Type";
                tooltip = "The type of combat support this module provides.\n\nCAS (Close Air Support): Provides attack helicopter or fixed-wing strike aircraft that can be called to engage targets at a specified location. Players request CAS via the support menu.\n\nTransport: Provides a helicopter for troop transport. Players can request pickup and dropoff at any location. The helicopter will land, wait for passengers, then fly to the destination.\n\nArtillery: Provides indirect fire support (mortars, howitzers, MLRS). Players designate targets on the map and select munition type and fire mission parameters.";
                typeName = "STRING";
                defaultValue = """CAS""";
                class Values {
                    class CAS {
                        name = "CAS (Close Air Support)";
                        value = "CAS";
                    };
                    class Transport {
                        name = "Transport";
                        value = "transport";
                    };
                    class Artillery {
                        name = "Artillery";
                        value = "artillery";
                    };
                };
            };

            class ATLAS_support_callsign : Edit {
                property = "ATLAS_support_callsign";
                displayName = "Callsign";
                tooltip = "The radio callsign for this support asset, displayed in the support request menu and radio communications. Examples: 'Eagle 1' for CAS, 'Dustoff 1' for transport, 'Steel Rain' for artillery. Keep it short and memorable. If left empty, a default callsign is generated based on support type.";
                typeName = "STRING";
                defaultValue = """""";
            };

            class ATLAS_support_vehicle : Edit {
                property = "ATLAS_support_vehicle";
                displayName = "Vehicle Classname";
                tooltip = "The classname of the vehicle used for this support asset. Must be a valid CfgVehicles classname from your loaded mods.\n\nCAS examples: 'B_Heli_Attack_01_dynamicLoadout_F' (AH-99 Blackfoot), 'B_Plane_CAS_01_dynamicLoadout_F' (A-164 Wipeout).\n\nTransport examples: 'B_Heli_Transport_01_F' (UH-80 Ghost Hawk), 'B_Heli_Transport_03_F' (CH-67 Huron).\n\nArtillery examples: 'B_Mortar_01_F' (Mk6 Mortar), 'B_MBT_01_arty_F' (M4 Scorcher).\n\nLeave empty to use the default vehicle for the support type.";
                typeName = "STRING";
                defaultValue = """""";
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "Combat Support provides player-accessible fire support, transport, and close air support assets. Each module creates one support asset that players can call via the support request menu (default: 0-8-1). Place multiple modules for multiple support assets. The module position defines the staging/spawn location for the support vehicle. For CAS and Transport, place the module at an airfield or FARP. For Artillery, place it at the desired gun position. Players access support through the ATLAS C2 tablet or the vanilla support menu.";
            sync[] = {};
        };
    };
};
