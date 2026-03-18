// ATLAS.OS Integration Test Runner
// Loaded by init.sqf — runs all test cases and writes results to RPT.
// Result markers are parsed by CI: [ATLAS_TEST] PASS: / FAIL: / ERROR:

private _tests = [];
private _passed = 0;
private _failed = 0;
private _errors = 0;

// Collect test files — add test scripts here
private _testFiles = [
    // "tests\integration.VR\test_example.sqf"
];

// --- Test helper functions ---

ATLAS_TEST_assert = {
    params ["_name", "_condition"];
    if (_condition) then {
        diag_log format ["[ATLAS_TEST] PASS: %1", _name];
        _passed = _passed + 1;
    } else {
        diag_log format ["[ATLAS_TEST] FAIL: %1", _name];
        _failed = _failed + 1;
    };
};

ATLAS_TEST_assertEqual = {
    params ["_name", "_actual", "_expected"];
    if (_actual isEqualTo _expected) then {
        diag_log format ["[ATLAS_TEST] PASS: %1", _name];
        _passed = _passed + 1;
    } else {
        diag_log format ["[ATLAS_TEST] FAIL: %1 — expected %2, got %3", _name, _expected, _actual];
        _failed = _failed + 1;
    };
};

// --- Run tests ---

diag_log "[ATLAS_TEST] === Starting ATLAS.OS integration tests ===";

{
    diag_log format ["[ATLAS_TEST] Running: %1", _x];
    try {
        [] execVM _x;
    } catch {
        diag_log format ["[ATLAS_TEST] ERROR: %1 — %2", _x, _exception];
        _errors = _errors + 1;
    };
} forEach _testFiles;

// Wait for async tests to settle
sleep 5;

// --- Summary ---

diag_log format ["[ATLAS_TEST] === Results: %1 passed, %2 failed, %3 errors ===", _passed, _failed, _errors];
diag_log "[ATLAS_TEST] ATLAS_TESTS_COMPLETE";

// Shut down server after tests
if (isServer) then {
    "endMission" call BIS_fnc_endMissionServer;
};
