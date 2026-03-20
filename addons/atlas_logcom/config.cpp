#include "script_component.hpp"

class CfgPatches {
    class atlas_logcom {
        name = "ATLAS.OS - Logistics Command";
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
    class atlas_logcom {
        tag = "atlas_logcom";
        class logcom {
            file = "\z\atlas\addons\atlas_logcom\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
