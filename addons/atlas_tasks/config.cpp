#include "script_component.hpp"

class CfgPatches {
    class atlas_tasks {
        name = "ATLAS.OS - Task System";
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
    class atlas_tasks {
        tag = "atlas_tasks";
        class tasks {
            file = "\z\atlas\addons\atlas_tasks\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
