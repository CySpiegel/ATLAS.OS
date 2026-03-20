class Extended_PreInit_EventHandlers {
    class atlas_persistence {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_persistence\XEH_preInit.sqf'";
    };
};

class Extended_PostInit_EventHandlers {
    class atlas_persistence {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_persistence\XEH_postInit.sqf'";
    };
};
