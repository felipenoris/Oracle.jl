
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

dpiOracleTypeNum dpiLob_getOracleTypeNum(dpiLob *lob) {
    return lob->type->oracleTypeNum;
}

int dpiLob_isCharacterData(dpiLob *lob) {
    return lob->type->isCharacterData;
}

size_t sizeof_dpiNumber() {
    return sizeof(dpiNumber);
}
