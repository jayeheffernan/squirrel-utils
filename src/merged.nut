// Mergeds an array of squirrel tables, earlier tables' keys take precedence
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

        if (typeof table != "table") {
            throw format("merged table #%d is of type %s", i, typeof table);
        }
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
                throw opts.prefix ? opts.prefix + ": merged unknown key " + k : "merged unknown key in safe mode" + k;
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
