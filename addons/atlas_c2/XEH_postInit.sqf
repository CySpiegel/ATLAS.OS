#include "script_component.hpp"

LOG("PostInit starting");

if (isServer) then {
    // TODO: Implement server-side initialization
    LOG("Server-side stub — no active handlers");
};

LOG("PostInit complete");
