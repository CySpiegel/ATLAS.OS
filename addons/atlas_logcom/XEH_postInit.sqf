// ============================================================================
// ATLAS.OS Logistics Command — Post-Initialization
// ============================================================================
#include "script_component.hpp"

diag_log "[ATLAS::LogCom] Post-initialization starting...";

if (isServer) then {
    [] call ATLAS_fnc_logcom_init;

    // Monitor group ammo levels for resupply
    [{
        {
            private _profileID = _x;
            private _profile = ATLAS_profileRegistry get _profileID;
            if (!isNil "_profile") then {
                private _ammoLevel = _profile getOrDefault ["ammoLevel", 1.0];
                if (_ammoLevel < ATLAS_logcom_resupplyThreshold) then {
                    [_profileID] call ATLAS_fnc_logcom_resupply;
                };
            };
        } forEach (keys ATLAS_profileRegistry);
    }, 60] call CBA_fnc_addPerFrameHandler;

    // Convoy management cycle
    [{
        {
            [_x] call ATLAS_fnc_logcom_convoy;
        } forEach ATLAS_logcom_convoys;
    }, 10] call CBA_fnc_addPerFrameHandler;

    diag_log "[ATLAS::LogCom] Server-side logistics handler started.";
};

diag_log "[ATLAS::LogCom] Post-initialization complete.";
