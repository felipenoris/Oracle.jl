
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
