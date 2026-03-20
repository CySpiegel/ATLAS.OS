#include "script_component.hpp"

class CfgPatches {
    class atlas_reports {
        name = "ATLAS.OS - Reporting System";
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
    class atlas_reports {
        tag = "atlas_reports";
        class reports {
            file = "\z\atlas\addons\atlas_reports\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
