class Extended_PreInit_EventHandlers {
    class atlas_gc {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_gc\XEH_preInit.sqf'";
    };
};

class Extended_PostInit_EventHandlers {
    class atlas_gc {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_gc\XEH_postInit.sqf'";
    };
};
