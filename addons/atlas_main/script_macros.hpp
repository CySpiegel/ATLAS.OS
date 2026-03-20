// ATLAS.OS - Shared script macros
// Lives in addons/atlas_main/ for PBO path access at runtime
// Other addons include via: #include "\z\atlas\addons\atlas_main\script_macros.hpp"

#ifndef ATLAS_SCRIPT_MACROS_HPP
#define ATLAS_SCRIPT_MACROS_HPP

#define MAINPREFIX z
#define PREFIX atlas

#define DOUBLES(var1,var2) var1##_##var2
#define TRIPLES(var1,var2,var3) var1##_##var2##_##var3
#define QUOTE(var1) #var1

#define ADDON DOUBLES(PREFIX,COMPONENT)
#define GVAR(var1) PREFIX##_##COMPONENT##_##var1
#define QGVAR(var1) QUOTE(GVAR(var1))
#define FUNC(var1) PREFIX##_##COMPONENT##_fnc_##var1
#define QFUNC(var1) QUOTE(FUNC(var1))
#define EGVAR(var1,var2) PREFIX##_##var1##_##var2
#define QEGVAR(var1,var2) QUOTE(EGVAR(var1,var2))
#define EFUNC(var1,var2) PREFIX##_##var1##_fnc_##var2
#define QEFUNC(var1,var2) QUOTE(EFUNC(var1,var2))

// Function preparation — compiles fnc_<name>.sqf and assigns to global variable
// Uses ADDON (PREFIX_COMPONENT) for the folder path since addon dirs are atlas_<name>
#define PREP(var1) FUNC(var1) = compileFinal preprocessFileLineNumbers QUOTE(\MAINPREFIX\PREFIX\addons\ADDON\functions\DOUBLES(fnc,var1).sqf)

// Logging
#define LOG(msg) diag_log text format ["[ATLAS/%1] %2", QUOTE(COMPONENT), msg]
#define LOG_1(msg,arg1) diag_log text format ["[ATLAS/%1] %2", QUOTE(COMPONENT), format [msg, arg1]]
#define LOG_2(msg,arg1,arg2) diag_log text format ["[ATLAS/%1] %2", QUOTE(COMPONENT), format [msg, arg1, arg2]]

// --- Spatial Grid ---
#define ATLAS_GRID_SIZE_DEFAULT 500

// --- Spawn/Despawn Hysteresis ---
#define ATLAS_SPAWN_RADIUS      1500
#define ATLAS_DESPAWN_RADIUS    1800

#ifdef DEBUG_MODE_FULL
    #define DEBUG_LOG(msg) LOG(msg)
#else
    #define DEBUG_LOG(msg)
#endif

#endif
