
// this file will be appended to src/embed/dpi.c

size_t sizeof_dpiDataBuffer() {
    return sizeof(dpiDataBuffer);
}

size_t sizeof_dpiData() {
    return sizeof(dpiData);
}

size_t sizeof_dpiPoolCreateParams() {
    return sizeof(dpiPoolCreateParams);
}

size_t sizeof_dpiConnCreateParams() {
    return sizeof(dpiConnCreateParams);
}

size_t sizeof_dpiQueryInfo() {
    return sizeof(dpiQueryInfo);
}

size_t sizeof_dpiVersionInfo() {
    return sizeof(dpiVersionInfo);
}

// see issue #21
/*
size_t sizeof_dpiNumber() {
    return sizeof(dpiNumber);
}
*/
