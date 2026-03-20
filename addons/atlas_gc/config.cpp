#include "script_component.hpp"

class CfgPatches {
    class atlas_gc {
        name = "ATLAS.OS - Garbage Collection";
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
    class atlas_gc {
        tag = "atlas_gc";
        class gc {
            file = "\z\atlas\addons\atlas_gc\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
