#include "script_component.hpp"

class CfgPatches {
    class atlas_markers {
        name = "ATLAS.OS - Map Markers";
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
    class atlas_markers {
        tag = "atlas_markers";
        class markers {
            file = "\z\atlas\addons\atlas_markers\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
