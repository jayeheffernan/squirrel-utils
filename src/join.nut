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
