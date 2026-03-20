#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_autoBudget
// ============================================================================
// Auto-adjusts scheduler budgets based on server FPS.
// Uses EMA-smoothed FPS to avoid reacting to transient spikes.
// Derived from athena's fnc_autoBudget pattern.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

// --- Smooth FPS reading ---
private _rawFPS = diag_fps;
private _smoothedFPS = GVAR(autoBudgetSmoothedFPS);

if (_smoothedFPS < 1) then {
    _smoothedFPS = _rawFPS;
} else {
    _smoothedFPS = _smoothedFPS * 0.7 + _rawFPS * 0.3;
};
GVAR(autoBudgetSmoothedFPS) = _smoothedFPS;

// --- Compute headroom ---
private _targetFPS = GVAR(schedulerTargetFPS);
private _targetFrameTime = 1000 / _targetFPS;
private _currentFrameTime = 1000 / (_smoothedFPS max 1);
private _headroom = _targetFrameTime - _currentFrameTime;

// --- Compute ceiling from user-configured frame percentage ---
private _framePct = GVAR(schedulerFramePct) / 100;
private _ceilingBudget = _targetFrameTime * _framePct;
private _minBudget = 1.0;  // 1ms floor — diag_tickTime resolution limit

// --- Adjust total budget ---
private _currentBudget = GVAR(schedulerTotalBudget);
private _newBudget = if (_headroom > 0) then {
    // FPS above target — gently increase toward ceiling
    _currentBudget + ((_ceilingBudget - _currentBudget) * 0.3)
} else {
    // FPS below target — pressure-scale down
    private _pressure = (abs _headroom) / _targetFrameTime;
    _currentBudget * (1 - (_pressure * 0.5) min 0.4)
};

_newBudget = _newBudget max _minBudget min _ceilingBudget;
GVAR(schedulerTotalBudget) = _newBudget;

// --- Performance tier detection ---
private _tier = if (_smoothedFPS >= _targetFPS) then { "NORMAL" }
    else { if (_smoothedFPS >= _targetFPS * 0.5) then { "STRESSED" }
    else { "DEGRADED" }};

private _oldTier = GVAR(performanceTier);
if !(_tier isEqualTo _oldTier) then {
    GVAR(performanceTier) = _tier;
    ["ATLAS_performance_tierChanged", [_tier, _oldTier, _smoothedFPS]] call CBA_fnc_localEvent;
    ["Core", "INFO", format ["Performance tier: %1 -> %2 (FPS: %3, budget: %4ms)", _oldTier, _tier, _smoothedFPS toFixed 1, _newBudget toFixed 2]] call FUNC(log);
};

// --- Log if budget changed significantly ---
if (GVAR(debugMode) && {abs (_newBudget - _currentBudget) > 0.1}) then {
    ["Core", "DEBUG", format ["autoBudget: budget=%1ms fps=%2 headroom=%3ms tier=%4",
        _newBudget toFixed 2, _smoothedFPS toFixed 1, _headroom toFixed 2, _tier]] call FUNC(log);
};
