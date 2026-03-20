#include "..\script_component.hpp"
// ============================================================================
// atlas_placement_fnc_getClassnames
// ============================================================================
// Returns an array of unit classnames for a given profile type, faction, and side.
// Pulls from CfgGroups if available, falls back to hardcoded defaults.
//
// @param  _type     STRING  "infantry", "motorized", "mechanized", "armor"
// @param  _faction  STRING  Faction classname (e.g., "BLU_F", "OPF_F")
// @param  _side     SIDE    west, east, resistance
//
// @return ARRAY  Unit classname strings
// @context Both
// @scheduled false
// ============================================================================

params [
    ["_type",    "infantry", [""]],
    ["_faction", "BLU_F",    [""]],
    ["_side",    west,       [west]]
];

// Try to find groups from CfgGroups for this faction
private _sideStr = switch (_side) do {
    case west:       { "West" };
    case east:       { "East" };
    case resistance: { "Indep" };
    default          { "West" };
};

private _cfgPath = configFile >> "CfgGroups" >> _sideStr >> _faction;

if (isClass _cfgPath) then {
    // Find infantry/motorized subclass
    private _typeClass = switch (_type) do {
        case "infantry":   { "Infantry" };
        case "motorized":  { "Motorized" };
        case "mechanized": { "Mechanized" };
        case "armor":      { "Armored" };
        default            { "Infantry" };
    };

    // Search for a matching group config
    private _groupCfg = _cfgPath >> _typeClass;
    if (isClass _groupCfg && {count _groupCfg > 0}) then {
        // Pick a random group from this category
        private _groups = "true" configClasses _groupCfg;
        if (count _groups > 0) then {
            private _selectedGroup = selectRandom _groups;
            private _units = [];
            {
                private _unitClass = getText (_x >> "vehicle");
                if (_unitClass != "") then {
                    _units pushBack _unitClass;
                };
            } forEach ("true" configClasses _selectedGroup);
            if (count _units > 0) exitWith { _units };
        };
    };
};

// Fallback: hardcoded defaults by side and type
switch (_type) do {
    case "infantry": {
        switch (_side) do {
            case west:       { ["B_Soldier_TL_F", "B_Soldier_F", "B_Soldier_AR_F", "B_Soldier_GL_F"] };
            case east:       { ["O_Soldier_TL_F", "O_Soldier_F", "O_Soldier_AR_F", "O_Soldier_GL_F"] };
            case resistance: { ["I_Soldier_TL_F", "I_Soldier_F", "I_Soldier_AR_F", "I_Soldier_GL_F"] };
            default          { ["B_Soldier_F", "B_Soldier_F", "B_Soldier_F", "B_Soldier_F"] };
        };
    };
    case "motorized": {
        switch (_side) do {
            case west:       { ["B_MRAP_01_F"] };
            case east:       { ["O_MRAP_02_F"] };
            case resistance: { ["I_MRAP_03_F"] };
            default          { ["B_MRAP_01_F"] };
        };
    };
    case "mechanized": {
        switch (_side) do {
            case west:       { ["B_APC_Wheeled_01_cannon_F"] };
            case east:       { ["O_APC_Wheeled_02_rcws_v2_F"] };
            case resistance: { ["I_APC_Wheeled_03_cannon_F"] };
            default          { ["B_APC_Wheeled_01_cannon_F"] };
        };
    };
    case "armor": {
        switch (_side) do {
            case west:       { ["B_MBT_01_cannon_F"] };
            case east:       { ["O_MBT_02_cannon_F"] };
            case resistance: { ["I_MBT_03_cannon_F"] };
            default          { ["B_MBT_01_cannon_F"] };
        };
    };
    default { ["B_Soldier_F", "B_Soldier_F", "B_Soldier_F", "B_Soldier_F"] };
}
