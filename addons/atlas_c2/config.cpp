#include "script_component.hpp"

class CfgPatches {
    class atlas_c2 {
        name = "ATLAS.OS - Command & Control (C2)";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_markers", "atlas_reports"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_c2 {
        tag = "atlas_c2";
        class c2 {
            file = "\z\atlas\addons\atlas_c2\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
