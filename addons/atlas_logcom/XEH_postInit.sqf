// ============================================================================
// ATLAS.OS Logistics Command — Post-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Post-initialization starting...");

if (isServer) then {
    [] call FUNC(init);

    // Monitor group ammo levels for resupply
    [{
        {
            private _profileID = _x;
            private _profile = EGVAR(profile,registry) get _profileID;
            if (!isNil "_profile") then {
                private _ammoLevel = _profile getOrDefault ["ammoLevel", 1.0];
                if (_ammoLevel < ATLAS_logcom_resupplyThreshold) then {
                    [_profileID] call FUNC(resupply);
                };
            };
        } forEach (keys EGVAR(profile,registry));
    }, 60] call CBA_fnc_addPerFrameHandler;

    // Convoy management cycle
    [{
        {
            [_x] call FUNC(convoy);
        } forEach GVAR(convoys);
    }, 10] call CBA_fnc_addPerFrameHandler;

    LOG("Server-side logistics handler started.");
};

LOG("Post-initialization complete.");
