class Extended_PreInit_EventHandlers {
    class atlas_weather {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_weather\XEH_preInit.sqf'";
    };
};

class Extended_PostInit_EventHandlers {
    class atlas_weather {
        init = "call compile preprocessFileLineNumbers '\z\atlas\addons\atlas_weather\XEH_postInit.sqf'";
    };
};
