#include "script_component.hpp"

class CfgPatches {
    class atlas_profile {
        name = "ATLAS.OS - Profile Handler";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_profile {
        tag = "atlas_profile";
        class profile {
            file = "\z\atlas\addons\atlas_profile\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
