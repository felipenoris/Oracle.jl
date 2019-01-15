
const SIZEOF_DPI_DATA = sizeof(Oracle.dpiData)

is_null(val::NativeValue, offset::Integer=0) = is_null(val.dpi_data_handle + offset*SIZEOF_DPI_DATA)

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

#=
"""
    julia_type(native_type::dpiNativeTypeNum) :: DataType

Returns the equivalente julia type for an Oracle native type.
"""
function julia_type(nt::dpiNativeTypeNum) :: DataType
    nt == DPI_NATIVE_TYPE_DOUBLE    && return Float64
    nt == DPI_NATIVE_TYPE_BOOLEAN   && return Bool
    nt == DPI_NATIVE_TYPE_FLOAT     && return Float32
    nt == DPI_NATIVE_TYPE_INT64     && return Int64
    nt == DPI_NATIVE_TYPE_UINT64    && return UInt64
    nt == DPI_NATIVE_TYPE_BYTES     && return String
    nt == DPI_NATIVE_TYPE_TIMESTAMP && return dpiTimestamp

    error("Native type $native_type not supported by method `Oracle.julia_type`.")
end
=#

dpiNativeTypeNum(::Type{Float64})      = DPI_NATIVE_TYPE_DOUBLE
dpiNativeTypeNum(::Type{Bool})         = DPI_NATIVE_TYPE_BOOLEAN
dpiNativeTypeNum(::Type{Float32})      = DPI_NATIVE_TYPE_FLOAT
dpiNativeTypeNum(::Type{Int64})        = DPI_NATIVE_TYPE_INT64
dpiNativeTypeNum(::Type{UInt64})       = DPI_NATIVE_TYPE_UINT64
dpiNativeTypeNum(::Type{String})       = DPI_NATIVE_TYPE_BYTES
dpiNativeTypeNum(::Type{dpiTimestamp}) = DPI_NATIVE_TYPE_TIMESTAMP
dpiNativeTypeNum(::Type{Date})         = DPI_NATIVE_TYPE_TIMESTAMP
dpiNativeTypeNum(::Type{DateTime})     = DPI_NATIVE_TYPE_TIMESTAMP

function parse_native_value(val::NativeValue, offset::Integer=0)

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
        ptr_bytes = dpiData_getBytes(dpi_data_handle) # get a Ptr{dpiBytes}
        ora_string = unsafe_load(ptr_bytes) # get a dpiBytes
        enc = unsafe_string(ora_string.encoding)
        if enc == "ASCII" || enc == "UTF-8"
            return unsafe_string(ora_string.ptr, ora_string.length)
        else
            error("String encoding not supported: $enc.")
        end

    elseif val.native_type == DPI_NATIVE_TYPE_TIMESTAMP
        ptr_native_timestamp = dpiData_getTimestamp(dpi_data_handle)
        return unsafe_load(ptr_native_timestamp)
    else
        error("Data Type not supported: $(Int(val.native_type))")
    end
end

Base.getindex(val::NativeValue) = parse_native_value(val)
Base.getindex(val::NativeValue, offset::Integer) = parse_native_value(val, offset)

encoding(ora_string::dpiBytes) = unsafe_string(ora_string.encoding)

function encoding(ora_string_ptr::Ptr{dpiBytes})
    ora_string = unsafe_load(ora_string_ptr)
    return encoding(ora_string)
end

function encoding(val::NativeValue)
    @assert val.native_type == DPI_NATIVE_TYPE_BYTES "Native type must be Oracle.DPI_NATIVE_TYPE_BYTES. Found: $(val.native_type)."
    ptr_bytes = dpiData_getBytes(val.dpi_data_handle)
    return encoding(ptr_bytes)
end


function parse_value(column_info::dpiQueryInfo, m::Missing) :: Missing
    @assert ismissing(m) # sanity check
    @assert column_info.null_ok == 1 # if we got a null value, it must be ok for the schema to have a null value in this columns
    return missing
end

function parse_value(column_info::dpiQueryInfo, num::Float64)
    if column_info.type_info.oracle_type_num == DPI_ORACLE_TYPE_NUMBER && column_info.type_info.scale <= 0
        return Int(num)
    else
        return num
    end
end

function parse_value(column_info::dpiQueryInfo, ts::dpiTimestamp)
    if column_info.type_info.oracle_type_num == DPI_ORACLE_TYPE_DATE
        return Date(ts.year, ts.month, ts.day)
    else
        error("oracle_type_num $(column_info.type_info.oracle_type_num) not supported.")
    end
end

function parse_value(column_info::dpiQueryInfo, val::T) :: T where {T}
    # catches all other cases
    val
end
