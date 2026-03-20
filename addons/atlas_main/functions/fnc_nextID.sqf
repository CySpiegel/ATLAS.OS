#include "..\script_component.hpp"
// ============================================================================
// ATLAS_fnc_nextID
// ============================================================================
// Generates a unique profile ID using a monotonic counter.
// Simple, fast, guaranteed unique on server.
//
// Usage:
//   private _id = ["P"] call ATLAS_fnc_nextID;      // "ATLAS_P_1"
//   private _id = ["OBJ"] call ATLAS_fnc_nextID;    // "ATLAS_OBJ_2"
//   private _id = [] call ATLAS_fnc_nextID;          // "ATLAS_ID_3"
//
// Parameters:
//   _prefix - STRING (optional): ID prefix. Default "ID"
//
// Returns: STRING - Unique ID in format "ATLAS_<prefix>_<counter>"
// ============================================================================

params [["_prefix", "ID"]];

GVAR(profileCounter) = GVAR(profileCounter) + 1;

format ["ATLAS_%1_%2", _prefix, GVAR(profileCounter)]
