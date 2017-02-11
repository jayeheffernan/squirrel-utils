// Returns thing as an array
function toarray(thing, nulls=false) {
    if (thing == null && !nulls) {
        return [];
    }
    return typeof thing == "array" ? thing : [ thing ];
}
