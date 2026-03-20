#include "script_component.hpp"

class CfgPatches {
    class atlas_admin {
        name = "ATLAS.OS - Admin Actions";
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
    class atlas_admin {
        tag = "atlas_admin";
        class admin {
            file = "\z\atlas\addons\atlas_admin\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
