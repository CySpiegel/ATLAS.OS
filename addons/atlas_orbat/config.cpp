#include "script_component.hpp"

class CfgPatches {
    class atlas_orbat {
        name = "ATLAS.OS - ORBAT (Order of Battle)";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_orbat {
        tag = "atlas_orbat";
        class orbat {
            file = "\z\atlas\addons\atlas_orbat\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
