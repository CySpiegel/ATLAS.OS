#include "script_component.hpp"

class CfgPatches {
    class atlas_stats {
        name = "ATLAS.OS - Statistics Tracking";
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
    class atlas_stats {
        tag = "atlas_stats";
        class stats {
            file = "\z\atlas\addons\atlas_stats\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
