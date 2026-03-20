#include "script_component.hpp"

LOG("PostInit starting");

if (isServer) then {
    [] call FUNC(init);
    LOG("Profile system server-side initialization complete");
};

LOG("PostInit complete");
