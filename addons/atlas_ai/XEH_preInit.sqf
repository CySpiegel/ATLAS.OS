// ============================================================================
// ATLAS.OS AI Behavior — Pre-Initialization
// ============================================================================
#include "script_component.hpp"

LOG("Pre-initialization starting...");

// Register module
[
    "ai",
    createHashMapFromArray [
        ["version", "0.1.0"],
        ["requires", ["main"]],
        ["provides", ["aiSkill", "aiSuppression", "aiScaling"]],
        ["events", [
            "ATLAS_ai_skillApplied",
            "ATLAS_ai_suppressed"
        ]]
    ]
] call EFUNC(main,registerModule);

// ---------------------------------------------------------------------------
// CBA Settings — AI Behavior
// ---------------------------------------------------------------------------

// AI Skill Range
[
    "ATLAS_ai_skillRange",
    "SLIDER",
    ["AI Skill Range", "Base skill level for AI units (0.0-1.0). This value is used as the midpoint for skill randomization. Lower values make AI less accurate and less aware. Higher values create more challenging opponents. Each AI unit receives a randomized skill within a range centered on this value. Recommended: 0.4 for casual play, 0.6 for challenging, 0.8 for milsim."],
    ["ATLAS.OS", "AI Behavior"],
    [0, 1, 0.5, 2],
    1,
    {}
] call CBA_fnc_addSetting;

// AI Suppression System
[
    "ATLAS_ai_suppressionEnabled",
    "CHECKBOX",
    ["Enable AI Suppression", "When enabled, AI units react to incoming fire with suppression effects: reduced accuracy, movement to cover, and morale impacts. This makes firefights more dynamic and tactical. When disabled, AI uses default Arma 3 behavior under fire."],
    ["ATLAS.OS", "AI Behavior"],
    true,
    1,
    {}
] call CBA_fnc_addSetting;

// Skill Scaling Method
[
    "ATLAS_ai_scalingMethod",
    "LIST",
    ["Skill Scaling Method", "How AI skill scales during the mission.\n\nFixed: All AI use the base skill value throughout the mission.\n\nDistance: AI further from players have lower skill (simulates fog of war).\n\nDynamic: AI skill adjusts based on player performance — if players dominate, AI gets tougher; if players struggle, AI becomes easier."],
    ["ATLAS.OS", "AI Behavior"],
    [["fixed", "distance", "dynamic"], ["Fixed", "Distance-Based", "Dynamic (Adaptive)"], 0],
    1,
    {}
] call CBA_fnc_addSetting;

LOG("Pre-initialization complete.");
