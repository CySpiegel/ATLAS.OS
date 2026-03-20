class Extended_PreInit_EventHandlers {
    class atlas_profile {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_profile\XEH_preInit.sqf'";
    };
};

class Extended_PostInit_EventHandlers {
    class atlas_profile {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_profile\XEH_postInit.sqf'";
    };
};
