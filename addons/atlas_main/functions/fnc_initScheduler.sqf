#include "..\script_component.hpp"
// ============================================================================
// atlas_main_fnc_initScheduler
// ============================================================================
// Initializes the budget scheduler. Starts the single PFH dispatcher
// and the virtual simulation loop (scheduled). Staggers initial timings.
//
// @return Nothing
// @context Server only
// @scheduled false
// ============================================================================

if (!isServer) exitWith {};

private _now = diag_tickTime;

// --- Stagger initial timings to prevent first-frame spike ---
GVAR(nextPlayerGridTime)  = _now + 0.5;
GVAR(nextGridSyncTime)    = _now + 1.5;
GVAR(nextAutoBudgetTime)  = _now + 3.0;

// --- Auto-budget state ---
GVAR(autoBudgetSmoothedFPS) = 0;
GVAR(schedulerTotalBudget)  = 2.0;  // initial total ms, auto-budget overwrites

// --- Scheduler stats ---
GVAR(schedulerLastTickMs) = 0;

// --- Start the single PFH dispatcher (unscheduled — for real-world work) ---
GVAR(schedulerHandle) = [{
    call FUNC(schedulerTick);
}, 0] call CBA_fnc_addPerFrameHandler;

// --- Start the virtual simulator (scheduled — for virtual world simulation) ---
[] spawn EFUNC(profile,virtualSimulator);

LOG("Scheduler started (PFH + virtual simulator)");
