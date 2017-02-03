// copies a table
function copy(t) {
    local c = {};
    foreach (k,v in t) {
        c[k] <- v
    }
    return c;
}

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

// WARNING: mutates `given`
// Merges table `given` with `defaults`.  Values in `given` take precedence.
// `nulls` specifies whether nulls are allowable values.  If `nulls == false`
// then given `null` in `given` will be replaced with the value in `defaults`.
// `nulls == true` will keep given `null` in `given` and ignore the value in
// `defaults`.  `null` can be true or false (whether any/all keys are allowed
// to be null) or an array (of which keys can be null)
function merge(given, defaults, nulls=false) {
    foreach (k,v in defaults) {
        // This value can be null if...
        local canBeNull = (
            // If nulls are allowed on all keys, or
            nulls == true ||
            // nulls is an array, and this key is listed, or
            (typeof nulls == "array" && nulls.find(k) != null)
        );
        // If the keys doesn't exist, set it
        if (!(k in given)) {
            given[k] <- v;
        // If the key exists and is null, and is not allowed to be null, then also set it
        } else if ((k in given) && given[k] == null && !canBeNull) {
            given[k] = v;
        }
    }
    // We have mutated the original object, but return it as well
    return given;
}

// Like merge but makes sure that `given` does not provide any options not
// present in `defaults`
function strictmerge(given, defaults, nulls=false) {
    foreach (k, v in given) {
        if (!(k in defaults)) {
            throw "Unknown option: " + k;
        }
    }
    return merge(given, defaults, nulls);
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
function validate(tests, scope = null, prefix = null, throwIt = null) {
    local err = null;
    local errIndex = null;

    if (typeof scope == "string") {
        // no argument for scope, this arg is meant for prefix
        throwIt = prefix;
        prefix  = scope;
        scope   = {};
    } else if (scope == null) {
        scope = {};
    } else if (typeof scope != "table") {
        err = "expected type table but got type " + typeof scope;
    }

    if (prefix == null) {
        prefix == "Unknown";
    }

    if (throwIt == null) {
        throwIt = true;
    }

    // Accept a singular test, but treat it like an array
    tests = toarray(tests);

    // Report indices in test errors?  Don't if there's only one test
    local reportIndex = tests.len() > 1;

    if (err == null) {
        // Run the test functions
        foreach (index, test in tests) {
            try {
                local val;
                if (typeof test == "function") {
                    // Call the test function
                    val = test.bindenv(scope)();
                } else {
                    // Set the test value
                    val = test;
                }
                // A test function (or value) indicates success by returning
                // true, or nothing at all (null). Anything else should be
                // treated as an error
                if (val != null && val != true) {
                    err      = val.tostring();
                    errIndex = index;
                    break;
                }
            } catch (e) {
                // An error was thrown calling the test function, obvs treat it as an error
                err      = e.tostring();
                errIndex = index;
                break;
            }
        }
    }

    // Throw or return the error
    if (err != null) {
        if (reportIndex) {
            err = format("%s validation #%d failed: %s", prefix, errIndex+1, err);
        } else {
            err = format("%s validation failed: %s", prefix, err);
        }
        if (throwIt) {
            throw err;
        } else {
            return err;
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
