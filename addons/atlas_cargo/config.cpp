#include "script_component.hpp"

class CfgPatches {
    class atlas_cargo {
        name = "ATLAS.OS - Cargo System";
        author = AUTHOR;
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main"};
        version = VERSION;
        versionStr = VERSION_STR;
        versionAr[] = {VERSION_AR};
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
