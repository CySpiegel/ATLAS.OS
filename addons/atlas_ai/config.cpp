#include "script_component.hpp"

class CfgPatches {
    class atlas_ai {
        name = "ATLAS.OS - AI Behavior";
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
    class atlas_ai {
        tag = "atlas_ai";
        class ai {
            file = "\z\atlas\addons\atlas_ai\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
