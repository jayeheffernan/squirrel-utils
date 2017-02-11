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

            // What to do when an error happens in the task...
            local handleError = function(err) {
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
