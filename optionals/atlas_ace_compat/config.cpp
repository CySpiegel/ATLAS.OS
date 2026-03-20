#include "script_component.hpp"

class CfgPatches {
    class atlas_ace_compat {
        name = "ATLAS.OS - ACE3 Compatibility";
        author = "ATLAS.OS Team";
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "ace_main"};
        version = "0.1.0";
    };
};

class CfgFunctions {
    class atlas_ace_compat {
        tag = "atlas_ace_compat";
        class ace_compat {
            file = "\z\atlas\optionals\atlas_ace_compat\functions";
        };
    };
};

#include "CfgEventHandlers.hpp"
