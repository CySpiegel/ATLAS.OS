// ATLAS.OS Common Macros
// These provide CBA-compatible macro utilities used across all modules

#include "\x\cba\addons\main\script_macros_common.hpp"

// --- Logging Macros ---
#define ATLAS_LOG(msg)          diag_log format ["[ATLAS] %1", msg]
#define ATLAS_LOG_INFO(mod,msg) diag_log format ["[ATLAS::%1] INFO: %2", mod, msg]
#define ATLAS_LOG_WARN(mod,msg) diag_log format ["[ATLAS::%1] WARN: %2", mod, msg]
#define ATLAS_LOG_ERROR(mod,msg) diag_log format ["[ATLAS::%1] ERROR: %2", mod, msg]
#define ATLAS_LOG_DEBUG(mod,msg) if (ATLAS_setting_debugMode) then { diag_log format ["[ATLAS::%1] DEBUG: %2", mod, msg] }

// --- Prefix Macros ---
#define ATLAS_PREFIX            "ATLAS"
#define ADDON                   DOUBLES(PREFIX,COMPONENT)
#define DOUBLES(var1,var2)      var1##_##var2
#define TRIPLES(var1,var2,var3) var1##_##var2##_##var3
#define QUOTE(var)              #var
#define QGVAR(var)              QUOTE(DOUBLES(ADDON,var))

// --- Function Naming ---
#define FUNC(name)              TRIPLES(ATLAS,fnc,name)
#define QFUNC(name)             QUOTE(FUNC(name))
#define EFUNC(module,name)      TRIPLES(ATLAS,fnc,DOUBLES(module,name))
#define QEFUNC(module,name)     QUOTE(EFUNC(module,name))

// --- Global Variable Naming ---
#define GVAR(var)               DOUBLES(ADDON,var)
#define QGVAR(var)              QUOTE(GVAR(var))
#define EGVAR(module,var)       TRIPLES(PREFIX,module,var)
#define QEGVAR(module,var)      QUOTE(EGVAR(module,var))

// --- Spatial Grid ---
#define ATLAS_GRID_SIZE         500

// --- Spawn/Despawn Hysteresis ---
#define ATLAS_SPAWN_RADIUS      1500
#define ATLAS_DESPAWN_RADIUS    1800
