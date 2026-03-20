#include "script_component.hpp"

class CfgPatches {
    class atlas_main {
        name = "ATLAS.OS - Core";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
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
