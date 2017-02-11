function keys(table) {
    local keys = [];
    foreach (k, v in table) {
        keys.push(k);
    }
    return keys;
}
