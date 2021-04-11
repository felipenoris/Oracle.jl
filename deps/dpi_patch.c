
// this file will be appended to src/embed/dpi.c

size_t sizeof_dpiDataBuffer() {
    return sizeof(dpiDataBuffer);
}

size_t sizeof_dpiData() {
    return sizeof(dpiData);
}

size_t sizeof_dpiTimestamp() {
    return sizeof(dpiTimestamp);
}

size_t sizeof_dpiErrorInfo() {
    return sizeof(dpiErrorInfo);
}

size_t sizeof_dpiCommonCreateParams() {
    return sizeof(dpiCommonCreateParams);
}

size_t sizeof_dpiAppContext() {
    return sizeof(dpiAppContext);
}

size_t sizeof_dpiPoolCreateParams() {
    return sizeof(dpiPoolCreateParams);
}

size_t sizeof_dpiConnCreateParams() {
    return sizeof(dpiConnCreateParams);
}

size_t sizeof_dpiDataTypeInfo() {
    return sizeof(dpiDataTypeInfo);
}

size_t sizeof_dpiQueryInfo() {
    return sizeof(dpiQueryInfo);
}

size_t sizeof_dpiVersionInfo() {
    return sizeof(dpiVersionInfo);
}

size_t sizeof_dpiStmtInfo() {
    return sizeof(dpiStmtInfo);
}

size_t sizeof_dpiBytes() {
    return sizeof(dpiBytes);
}

size_t sizeof_dpiEncodingInfo() {
    return sizeof(dpiEncodingInfo);
}

size_t sizeof_dpiObjectTypeInfo() {
    return sizeof(dpiObjectTypeInfo);
}

// see issue #21
/*
size_t sizeof_dpiNumber() {
    return sizeof(dpiNumber);
}
*/
