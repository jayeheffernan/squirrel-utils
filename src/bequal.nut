// Check if two blobs or strings are equal
function bequal(a, b) {
    if (a.len() != b.len()) {
        return false;
    }
    for (local i = 0, len=a.len(); i < len; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}
