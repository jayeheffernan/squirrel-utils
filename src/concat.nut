function concat(arrays, nulls=false) {
    local result = [];
    foreach (a in arrays) {
        result.extend(toarray(a, nulls));
    }
    return result;
}
