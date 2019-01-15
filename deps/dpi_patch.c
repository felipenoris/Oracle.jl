
// this file will be appended to src/embed/dpi.c

size_t sizeof_dpiDataBuffer() {
    return sizeof(dpiDataBuffer);
}

size_t sizeof_dpiData() {
    return sizeof(dpiData);
}

// See https://github.com/oracle/odpi/issues/82
int dpiData_isNull(dpiData *data) {
    return data->isNull;
}

// See https://github.com/oracle/odpi/issues/82
void dpiData_setNull(dpiData *data) {
    data->isNull = 1;
}
