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
