#include "script_component.hpp"

class CfgPatches {
    class atlas_main {
        name = "ATLAS.OS - Core Framework";
        author = AUTHOR;
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"cba_main", "cba_events", "cba_settings", "cba_statemachine"};
        version = VERSION;
        versionStr = VERSION_STR;
        versionAr[] = {VERSION_AR};
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
#include "CfgSettings.hpp"

// --- Eden Editor Module Category ---
class CfgFactionClasses {
    class NO_CATEGORY;
    class ATLAS_Modules {
        displayName = "ATLAS.OS";
        priority = 2;
        side = 7; // logic
    };
};

// --- Eden Editor Subcategories ---
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
