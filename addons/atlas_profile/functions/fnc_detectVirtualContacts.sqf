#include "..\script_component.hpp"
// ============================================================================
// atlas_profile_fnc_detectVirtualContacts
// ============================================================================
// Uses the spatial grid to find enemy profiles within contact range.
// O(nearby cells) not O(n²) — the key performance optimization.
//
// @param  _profile  HASHMAP  The profile checking for contacts
//
// @return ARRAY  Profile IDs of detected enemies within contact range
// @context Server only
// @scheduled true (called from virtualFSMTick)
// ============================================================================

params ["_profile"];

private _pos = _profile get "pos";
private _side = _profile get "side";
private _id = _profile get "id";

// Contact range varies by unit type
private _contactRange = switch (_profile get "type") do {
    case "infantry":    { 400 };
    case "motorized":   { 600 };
    case "mechanized":  { 700 };
    case "armor":       { 800 };
    case "air":         { 1500 };
    case "naval":       { 1000 };
    default             { 400 };
};

// Spatial grid query — returns only profiles in nearby cells
private _nearbyIDs = [_pos, _contactRange] call EFUNC(main,gridQuery);
private _contacts = [];

{
    if (_x isEqualTo _id) then { continue };

    private _other = EGVAR(main,profileRegistry) getOrDefault [_x, ""];
    if !(_other isEqualType createHashMap) then { continue };

    // Skip same side
    if ((_other get "side") isEqualTo _side) then { continue };

    // Skip spawned (real AI handles them)
    if ((_other get "state") isEqualTo "spawned") then { continue };

    // Skip already routed/destroyed
    if ((_other get "state") in ["ROUTED"]) then { continue };
    if ((_other getOrDefault ["strength", 1.0]) <= 0.05) then { continue };

    // Precise distance check
    if ((_other get "pos") distance2D _pos <= _contactRange) then {
        _contacts pushBack _x;
    };
} forEach _nearbyIDs;

_contacts
