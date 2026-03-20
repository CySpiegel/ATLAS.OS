#include "script_component.hpp"

class CfgPatches {
    class atlas_opcom {
        name = "ATLAS.OS - AI Commander (OPCOM)";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {"ATLAS_Module_OPCOM"};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile", "atlas_placement"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_opcom {
        tag = "atlas_opcom";
        class opcom {
            file = "\z\atlas\addons\atlas_opcom\functions";
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

    class ATLAS_Module_OPCOM : Module_F {
        scope = 2;
        displayName = "AI Commander (OPCOM)";
        icon = "\z\atlas\addons\atlas_opcom\ui\icon.png";
        category = "ATLAS_Modules";
        vehicleClass = "ATLAS_Military";
        function = "ATLAS_fnc_opcom_moduleInit";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 0;
        is3DEN = 0;

        curatorCanAttach = 1;
        canSetArea = 0;

        class Attributes : AttributesBase {
            class ATLAS_opcom_side : Combo {
                property = "ATLAS_opcom_side";
                displayName = "Side";
                tooltip = "The side this AI commander controls. The OPCOM will issue orders to all profiled units on this side, including attack, defend, reinforce, and recon missions. Each side should have at most one OPCOM. BLUFOR = West, OPFOR = East, INDFOR = Resistance.";
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

            class ATLAS_opcom_aggression : Edit {
                property = "ATLAS_opcom_aggression";
                displayName = "Aggression";
                tooltip = "Controls how aggressively the AI commander acts, from 0 (purely defensive) to 1 (maximum aggression). Low values (0.0-0.3): OPCOM prioritizes defense and rarely launches offensives. Medium values (0.3-0.7): balanced approach with periodic attacks. High values (0.7-1.0): constant offensive pressure with minimal reserves. Recommended: 0.5 for balanced gameplay, 0.8+ for intense combat.";
                typeName = "NUMBER";
                defaultValue = "0.5";
            };

            class ATLAS_opcom_type : Combo {
                property = "ATLAS_opcom_type";
                displayName = "OPCOM Type";
                tooltip = "Determines the AI commander's strategic doctrine and behavior pattern.\n\nInvasion: The OPCOM will systematically capture objectives in order of proximity, pushing a front line forward. Best for conventional warfare scenarios with clear battle lines.\n\nOccupation: The OPCOM holds all objectives simultaneously, distributing forces evenly and reinforcing threatened positions. Best for peacekeeping or area denial scenarios.\n\nAsymmetric: The OPCOM uses hit-and-run tactics, ambushes, and IED placement. Forces are hidden until they strike, then disperse. Best for insurgency and guerrilla warfare scenarios.";
                typeName = "STRING";
                defaultValue = """invasion""";
                class Values {
                    class Invasion {
                        name = "Invasion";
                        value = "invasion";
                    };
                    class Occupation {
                        name = "Occupation";
                        value = "occupation";
                    };
                    class Asymmetric {
                        name = "Asymmetric";
                        value = "asymmetric";
                    };
                };
            };

            class ModuleDescription : ModuleDescription {};
        };

        class ModuleDescription : ModuleDescription {
            description = "ATLAS AI Commander (OPCOM) provides autonomous strategic-level AI command and control. The OPCOM analyzes the battlefield, prioritizes objectives, and issues orders to all profiled military units on its side. It handles force allocation, attack planning, defensive positioning, reinforcement routing, and strategic reserve management. Place one OPCOM module per side. Sync the module to Military Placement modules to define which forces the OPCOM controls. The OPCOM will automatically coordinate with the Air Tasking Order (ATO) module if present.";
            sync[] = {"ATLAS_Module_Placement", "ATLAS_Module_ATO"};
        };
    };
};
