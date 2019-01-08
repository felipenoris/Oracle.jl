
const SIZEOF_DPI_DATA = sizeof(Oracle.dpiData)

is_null(val::DataValue, offset::Integer=0) = is_null(val.dpi_data_handle + offset*SIZEOF_DPI_DATA)

function is_null(ptr::Ptr{dpiData})
    is_null_as_cint = dpiData_isNull(ptr)

    if is_null_as_cint == 0
        return false
    elseif is_null_as_cint == 1
        return true
    else
        error("Unexpected value for dpiData.is_null field: $(Int(is_null_as_cint))")
    end
end

function parse_julia_value(val::DataValue, offset::Integer=0)

    dpi_data_handle = val.dpi_data_handle + offset*SIZEOF_DPI_DATA

    if is_null(dpi_data_handle)
        return missing

    elseif val.native_type == DPI_NATIVE_TYPE_DOUBLE
        return dpiData_getDouble(dpi_data_handle)

    elseif val.native_type == DPI_NATIVE_TYPE_BOOLEAN
        result_bool = dpiData_getBool(dpi_data_handle)
        @assert result_bool == 0 || result_bool == 1
        return result_bool == 1

    elseif val.native_type == DPI_NATIVE_TYPE_FLOAT
        return dpiData_getFloat(dpi_data_handle)

    elseif val.native_type == DPI_NATIVE_TYPE_INT64
        return dpiData_getInt64(dpi_data_handle)

    elseif val.native_type == DPI_NATIVE_TYPE_UINT64
        return dpiData_getUint64(dpi_data_handle)

    elseif val.native_type == DPI_NATIVE_TYPE_BYTES
        return dpiData_getBytes(dpi_data_handle)

    else
        error("data type not supported")
    end
end

Base.getindex(val::DataValue) = parse_julia_value(val)
Base.getindex(val::DataValue, offset::Integer) = parse_julia_value(val, offset)
