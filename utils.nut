function keys(table) {
    local keys = [];
    foreach (k, v in table) {
        keys.push(k);
    }
    return keys;
}

function concat(arrays, nulls=false) {
    local result = [];
    foreach (a in arrays) {
        result.extend(toarray(a, nulls));
    }
    return result;
}

function merged(tables, opts={}) {
    if (!( "respectNulls" in opts )) {
        opts.respectNulls <- false;
    }
    if (!("safe" in opts)) {
        opts.safe <- false;
    }
    if (!("prefix" in opts)) {
        opts.prefix <- "";
    }

    tables = toarray(tables);

    local merged = {};

    local validKeys = null;
    if (opts.safe) {
        if (tables.len() < 2) {
            throw "Cannot perform \"safe\" merge on less than two tables";
        }
        validKeys = concat(tables.slice(1).map(@(table) keys(table)));
    }

    foreach (i, table in tables) {

        foreach (k, v in table) {
            // Null can count as a "real" value for this slot if...
            local canBeNull = (
                // nulls are allowed on all keys, or
                opts.respectNulls == true ||
                // nulls is an array, and this key is listed, or
                (typeof opts.respectNulls == "array" && opts.respectNulls.find(k) != null)
            );

            // If validKeys is null i.e. safe mode is off then all keys are valid.
            // All keys in all tables after the first are valid.
            // Keys in the first table are only valid if they are present in
            // later tables (and therfore in validKeys).
            local valid = !validKeys || i != 0 || (validKeys.find(k) != null);

            if (!valid) {
                throw opts.prefix ? prefix + ": merged unknown key " + k : "merged unknown key in safe mode" + k;
            }

            // If the keys doesn't exist, set it
            if (!(k in merged)) {
                merged[k] <- v;
            // If the key exists and is null, and we don't respect null, then also set it
            } else if ((k in merged) && merged[k] == null && !canBeNull) {
                merged[k] = v;
            }

        }

    }

    return merged;
}

function tostring(val) {
    if (typeof val == "string") {
        return "\"" + val + "\"|;"
    } else if (val == null) {
        return "null";
    } else if ("tostring" in val) {
        return val.tostring();
    } else {
        throw "cannot convert val tostring";
    }
}

function join(arr, sep="") {
    arr = toarray(arr);
    if (arr.len() == 0)
        return "";
    local s = arr[0];
    for (local i = 1; i < arr.len(); i++) {
        s += sep + arr[i];
    }
    return s;
}

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

// Returns thing as an array
function toarray(thing, nulls=false) {
    if (thing == null && !nulls) {
        return [];
    }
    return typeof thing == "array" ? thing : [ thing ];
}

// TODO can we generalise the assignment of args to names
function retry(opts = {}) {
    validate(typeof opts == "table" || "opts argument must be a table", "retry");

    local defaults = {
        times       = 2,
        minWait     = 1,
        maxWait     = 4,
        multiplier  = 2,
        args        = [],
        cb          = @(err, data) {},
        task        = null,
        name        = "anon"
    };
    strictmerge(opts, defaults);

    validate([
        @() typeof name == "string" || "opt name must be a string, got " + typeof name
    ], opts, "retry");

    validate([
        @() typeof times == "integer"                            || "opt times must be an integer",
        @() times >= 0                                           || "opt times can't be negative",
        @() ["integer", "float"].find(typeof minWait) != null    || "opt minWait must be an integer or float",
        @() minWait >= 0                                         || "opt minWait can't be negative",
        @() ["integer", "float"].find(typeof maxWait) != null    || "opt maxWait must be an integer or float",
        @() maxWait >= 0                                         || "opt maxWait can't be negative",
        @() minWait <= maxWait                                   || "opt maxWait cannot be less than minWait",
        @() ["integer", "float"].find(typeof multiplier) != null || "opt multiplier must be an integer or float",
        @() multiplier > 0                                       || "opt multiplier must be positive",
        @() typeof args  == "array"                              || "opt args must be an array",
        @() typeof cb    == "function"                           || "opt cb must be a function",
        @() typeof task  == "function"                           || "opt task must be a function",
    ], opts, format("%s retry", opts.name))

    // Initialize wait to minWait
    opts._wait <- opts.minWait;

    local attempt;
    attempt = function() {
        imp.wakeup(0, function(){
            server.log("trying");

            // What to do when an error happens in the task...
            local handleError = function(err) {
                server.log("failed");
                // Decrement the times remaining
                opts.times--;

                if (opts.times < 0) {
                    // We're all out of retries
                    opts.cb(err, null);
                } else {
                    // Modify the wait time before the next retry
                    opts._wait *= opts.multiplier;

                    // Keep wait time within bounds
                    if (opts._wait > opts.maxWait) {
                        opts._wait = opts.maxWait;
                    } else if (opts._wait < opts.minWait) {
                        opts._wait = opts.minWait;
                    }

                    // Set up the retry
                    imp.wakeup(opts._wait, attempt.bindenv(this));
                }
            };

            try {
                local args = [this];
                args.extend(opts.args);

                // Define the callback for when the task function is called
                args.push(function(err, data) {
                    if (err) {
                        // An error happened asyncly
                        handleError(err);
                    } else {
                        // Success! call the callback
                        server.log("succeeded");
                        opts.cb(null, data);
                    }
                }.bindenv(this));

                // Call the task function
                opts.task.acall(args);

            } catch (e) {
                // An error was thrown (syncly)
                handleError(e);
            }

        }.bindenv(this));
    }.bindenv(this);

    attempt();
};
