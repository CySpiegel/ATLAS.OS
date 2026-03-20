#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_determineForceComposition
// ============================================================================
// Determines how many groups to create based on force size string.
//
// @param  _size  STRING  "company", "battalion", or "brigade"
//
// @return NUMBER  Total number of groups to create
// @context Server only
// @scheduled false
// ============================================================================

params [["_size", "company", [""]]];

switch (toLower _size) do {
    case "company":  { 8  + floor random 4 };   // 8-11 groups (~30-45 units)
    case "battalion": { 25 + floor random 10 };  // 25-34 groups (~100-140 units)
    case "brigade":  { 60 + floor random 20 };   // 60-79 groups (~240-320 units)
    default          { 10 };
}
