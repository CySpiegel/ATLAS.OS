#include "script_component.hpp"

class CfgPatches {
    class atlas_compat {
        name = "ATLAS.OS - Compatibility Layer";
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
    class atlas_compat {
        tag = "atlas_compat";
        class compat {
            file = "\z\atlas\addons\atlas_compat\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
