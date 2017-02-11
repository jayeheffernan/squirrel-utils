// Validates an obj against a number of test function
// A test function should return `null` or `true` on success, and usually
// return (or throw) a string (representing an error message) on failure.  Test
// functions are bound to the context of `obj` when executing, so the keys of
// `obj` can be accessed within test functions as regular variables (not slots
// on a table)

// TODO can I expand validate to return a number (maybe) telling which of a set
// of conditions  is fulfilled.  This would enable the situation where there
// are a number of different (conflicting) ways a set of options can be valid,
// and allow different function to be dispatched batched on each

// Validates that a number of tests pass
function validate(scope, tests = null, opts={}) {
    if (typeof scope == "array") {
        // No scope was passed
        opts = tests || {};
        tests = scope;
        scope = {};
    } else if ("scope" in opts) {
        throw "validate: scope cannot be passed as both a parameter and an option";
    }
    local defaults = {
        scope      = {},
        prefix     = "unknown",
        throws     = true,
        tryAll     = false
    };

    opts = merged([ opts, { scope=scope }, defaults ], { safe=true, prefix="validation" });

    local errs = [];

    if (typeof opts.scope != "table") {
        errs.push("scope must be of type table, got type " + typeof scope);
    }

    // Accept a singular test, but treat it like an array
    tests = toarray(tests);

    // Report indices in test errors?  Don't if there's only one test
    local reportIndex = tests.len() > 1;

    if (errs.len() == 0) {
        // Run the test functions
        foreach (index, test in tests) {
            local err = null;
            try {
                local val;
                if (typeof test == "function") {
                    // Call the test function
                    val = test.bindenv(opts.scope)();
                } else {
                    // Set the test value
                    val = test;
                }
                // A test function (or value) indicates success by returning
                // true, or nothing at all (null). Anything else should be
                // treated as an error
                if (val != null && val != true) {
                    err      = val.tostring();
                }
            } catch (e) {
                // An error was thrown calling the test function, obvs treat it as an error
                err      = e.tostring();
            }
            if (err != null) {
                if (reportIndex) {
                    errs.push(format("%s validation #%d failed: %s", opts.prefix, index+1, err));
                } else {
                    errs.push(format("%s validation failed: %s", opts.prefix, err));
                }
                if (!opts.tryAll) {
                    break;
                }
            }
        }
    }

    // Throw or return the error
    if (errs.len() > 0) {
        if (opts.throws) {
            throw join(errs, "\n");
        } else {
            return join(errs, "\n");
        }
    } else {
        // No error, all good
        return null;
    }

}
