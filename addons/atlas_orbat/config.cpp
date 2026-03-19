#include "script_component.hpp"

class CfgPatches {
    class atlas_orbat {
        name = "ATLAS.OS - ORBAT (Order of Battle)";
        author = AUTHOR;
        url = "https://github.com/CySpiegel/ATLAS.OS";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.16;
        requiredAddons[] = {"atlas_main", "atlas_profile"};
        version = VERSION;
        versionStr = VERSION_STR;
        versionAr[] = {VERSION_AR};
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgFunctions.hpp"
