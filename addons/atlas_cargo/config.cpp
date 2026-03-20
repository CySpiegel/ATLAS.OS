#include "script_component.hpp"

class CfgPatches {
    class atlas_cargo {
        name = "ATLAS.OS - Cargo System";
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
    class atlas_cargo {
        tag = "atlas_cargo";
        class cargo {
            file = "\z\atlas\addons\atlas_cargo\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
