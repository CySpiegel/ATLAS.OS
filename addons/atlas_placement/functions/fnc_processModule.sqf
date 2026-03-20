#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_processModule
// ============================================================================
// Processes a single placement module — wrapper around fnc_init.
// Validates config before passing to init.
//
// @param  _cfg  HASHMAP  Placement config from moduleInit
//
// @return BOOL  true if processed successfully
// @context Server only
// @scheduled false
// ============================================================================

params ["_cfg"];

if !(_cfg isEqualType createHashMap) exitWith {
    LOG("processModule: Invalid config — not a HashMap");
    false
};

if !("side" in _cfg && "faction" in _cfg && "size" in _cfg) exitWith {
    LOG("processModule: Missing required keys (side, faction, size)");
    false
};

[_cfg] call FUNC(init);
true
