#include "script_component.hpp"

class CfgPatches {
    class atlas_weather {
        name = "ATLAS.OS - Weather System";
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
    class atlas_weather {
        tag = "atlas_weather";
        class weather {
            file = "\z\atlas\addons\atlas_weather\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
