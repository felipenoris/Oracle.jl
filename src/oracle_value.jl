
# https://oracle.github.io/odpi/doc/user_guide/data_types.html
# https://docs.oracle.com/cd/B28359_01/server.111/b28318/datatype.htm#CNCPT012
# https://docs.oracle.com/cd/B28359_01/server.111/b28320/limits001.htm

const SIZEOF_ORA_DATA = sizeof(Oracle.OraData)

@inline function oracle_type(v::AbstractOracleValue{O,N}) :: OraOracleTypeNum where {O,N}
    return O
end

@inline function native_type(v::AbstractOracleValue{O,N}) :: OraNativeTypeNum where {O,N}
    return N
end

@inline use_add_ref(::AbstractOracleValue) = false
@inline use_add_ref(v::ExternOracleValue) = v.use_add_ref

@inline parent(v::ExternOracleValue) = v.parent
@inline parent(v::JuliaOracleValue) = error("Not implemented.")

@inline function get_data_handle(val::ExternOracleValue, offset::Integer) :: Ptr{OraData}
    @assert offset > 0 "Invalid offset $offset."
    return val.data_handle + (offset-1)*SIZEOF_ORA_DATA
end

@inline function get_data_handle(val::ExternOracleValue) :: Ptr{OraData}
    # equivalent of get_data_handle(val, 0)
    return val.data_handle
end

@inline function get_data_handle(val::JuliaOracleValue, offset::Integer) :: Ptr{OraData}
    @assert offset > 0 "Invalid offset $offset."
    return pointer(val.buffer, offset)
end

@inline function get_data_handle(val::JuliaOracleValue) :: Ptr{OraData}
    # equivalent of get_data_handle(val, 0)
    return pointer(val.buffer)
end

@inline parse_oracle_value(val::AbstractOracleValue, offset::Integer) = parse_oracle_value_at(val, get_data_handle(val, offset))
@inline parse_oracle_value(val::AbstractOracleValue) = parse_oracle_value_at(val, get_data_handle(val))

@inline is_null(ptr::Ptr{OraData}) = Bool(dpiData_getIsNull(ptr))

@inline function parse_oracle_value_at(val::AbstractOracleValue, data_handle::Ptr{OraData})
    if is_null(data_handle)
        return missing
    else
        parse_non_null_oracle_value_at(val, data_handle)
    end
end

# O -> OraOracleTypeNum, N -> OraNativeTypeNum
@generated function parse_non_null_oracle_value_at(val::AbstractOracleValue{O, N}, data_handle::Ptr{OraData}) where {O, N}

    @assert isa(O, OraOracleTypeNum)
    @assert isa(N, OraNativeTypeNum)

    if O == ORA_ORACLE_TYPE_NATIVE_DOUBLE
        @assert N == ORA_NATIVE_TYPE_DOUBLE

        return quote
            dpiData_getDouble(data_handle)
        end
    end

    if O == ORA_ORACLE_TYPE_BOOLEAN
        @assert N == ORA_NATIVE_TYPE_BOOLEAN

        return quote
            Bool(dpiData_getBool(data_handle))
        end
    end

    if O == ORA_ORACLE_TYPE_NATIVE_FLOAT
        @assert N == ORA_NATIVE_TYPE_FLOAT

        return quote
            dpiData_getFloat(data_handle)
        end
    end

    if O == ORA_ORACLE_TYPE_NUMBER

        # DPI_NATIVE_TYPE_DOUBLE, DPI_NATIVE_TYPE_BYTES, DPI_NATIVE_TYPE_INT64, DPI_NATIVE_TYPE_UINT64

        if N == ORA_NATIVE_TYPE_DOUBLE
            return quote
                dpiData_getDouble(data_handle)
            end

        elseif N == ORA_NATIVE_TYPE_BYTES
            error("Numeric values with native type BYTES not supported.")

        elseif N == ORA_NATIVE_TYPE_INT64
            return quote
                dpiData_getInt64(data_handle)
            end

        elseif N == ORA_NATIVE_TYPE_UINT64
            return quote
                dpiData_getUint64(data_handle)
            end
        elseif N == ORA_NATIVE_TYPE_NUMBER
            return quote
                dpiData_getNumber(data_handle)
            end
        else
            error("Native type $N not expected for value with numeric oracle type.")
        end
    end

    if N == ORA_NATIVE_TYPE_BYTES

        if O == ORA_ORACLE_TYPE_RAW || O == ORA_ORACLE_TYPE_LONG_RAW
            # binary data
            return quote
                ptr_bytes = dpiData_getBytes(data_handle) # get a Ptr{OraBytes}
                ora_bytes = unsafe_load(ptr_bytes) # get a OraBytes
                unsafe_array = unsafe_wrap(Vector{UInt8}, ora_bytes.ptr, ora_bytes.length)
                return return copy(unsafe_array)
            end
        else
            # character data
            return quote
                ptr_bytes = dpiData_getBytes(data_handle) # get a Ptr{OraBytes}
                ora_bytes = unsafe_load(ptr_bytes) # get a OraBytes
                return unsafe_string(ora_bytes.ptr, ora_bytes.length)
            end
        end
    end

    if O == ORA_ORACLE_TYPE_DATE
        @assert N == ORA_NATIVE_TYPE_TIMESTAMP "Invalid combination: [ $O, $N ]."

        return quote
            ptr_native_timestamp = dpiData_getTimestamp(data_handle)
            local ts::OraTimestamp = unsafe_load(ptr_native_timestamp)
            return parse_datetime(ts)
        end
    end

    if O == ORA_ORACLE_TYPE_TIMESTAMP
        if N == ORA_NATIVE_TYPE_TIMESTAMP
            return quote
                ptr_native_timestamp = dpiData_getTimestamp(data_handle)
                local ts::OraTimestamp = unsafe_load(ptr_native_timestamp)
                return parse_timestamp(ts)
            end
        elseif N == ORA_NATIVE_TYPE_DOUBLE
            error("Not implemented.")
        else
            error("Invalid combination: [ $O, $N ].")
        end
    end

    if O == ORA_ORACLE_TYPE_TIMESTAMP_TZ
        @assert N == ORA_NATIVE_TYPE_TIMESTAMP "Invalid combination: [ $O, $N ]."

        return quote
            ptr_native_timestamp = dpiData_getTimestamp(data_handle)
            local ts::OraTimestamp = unsafe_load(ptr_native_timestamp)
            return parse_timestamp_tz(ts)
        end
    end

    if O == O == ORA_ORACLE_TYPE_TIMESTAMP_LTZ
        @assert N == ORA_NATIVE_TYPE_TIMESTAMP "Invalid combination: [ $O, $N ]."

        return quote
            ptr_native_timestamp = dpiData_getTimestamp(data_handle)
            local ts::OraTimestamp = unsafe_load(ptr_native_timestamp)
            return parse_timestamp_ltz(ts)
        end
    end

    if N == ORA_NATIVE_TYPE_LOB
        return quote
            ptr_native_lob = dpiData_getLOB(data_handle)
            return Lob(parent(val), ptr_native_lob, O; use_add_ref=use_add_ref(val))
        end
    end

    if O == ORA_ORACLE_TYPE_NATIVE_INT
        @assert N == ORA_NATIVE_TYPE_INT64

        return quote
            dpiData_getInt64(data_handle)
        end
    end

    if O == ORA_ORACLE_TYPE_NATIVE_UINT
        @assert N == ORA_NATIVE_TYPE_UINT64

        return quote
            dpiData_getUint64(data_handle)
        end
    end

    error("Couldn't parse value for oracle type $O, native type $N.")
end

@inline Base.getindex(val::AbstractOracleValue) = parse_oracle_value(val)
@inline Base.getindex(val::AbstractOracleValue, offset::Integer) = parse_oracle_value(val, offset)
@inline Base.setindex!(oracle_value::AbstractOracleValue, value, offset::Integer=1) = set_oracle_value!(oracle_value, value, offset)

@inline function set_oracle_value!(oracle_value::JuliaOracleValue{O,N,T}, val::T, offset::Integer=1) where {O,N,T}
    @assert offset > 0 "Invalid offset $offset."
    oracle_value.buffer[offset] = val
    nothing
end

@generated function set_oracle_value_at!(oracle_value::AbstractOracleValue{O,N}, val::T, at::Ref{OraData}) where {O,N,T}

    if val <: Missing
        return quote
            dpiData_setNull(at)
        end
    end

    if N == ORA_NATIVE_TYPE_BYTES
        if val <: String
            return quote
                dpiData_setBytes(at, val)
            end
        end

        if val <: Vector{UInt8}
            return quote
                dpiData_setBytes(at, pointer(val), UInt32(length(val)))
            end
        end
    end

    if N == ORA_NATIVE_TYPE_BOOLEAN
        return quote
            dpiData_setBool(at, val)
        end
    end

    if N == ORA_NATIVE_TYPE_DOUBLE
        return quote
            dpiData_setDouble(at, val)
        end
    end

    if N == ORA_NATIVE_TYPE_INT64
        return quote
            dpiData_setInt64(at, val)
        end
    end

    if N == ORA_NATIVE_TYPE_UINT64
        return quote
            dpiData_setUint64(at, val)
        end
    end

    if N == ORA_NATIVE_TYPE_TIMESTAMP

        # DPI_ORACLE_TYPE_DATE, DPI_ORACLE_TYPE_TIMESTAMP, DPI_ORACLE_TYPE_TIMESTAMP_LTZ, DPI_ORACLE_TYPE_TIMESTAMP_TZ

        if O == ORA_ORACLE_TYPE_DATE
            @assert val <: Date
        elseif O == ORA_ORACLE_TYPE_TIMESTAMP
            @assert (val <: Date) || (val <: DateTime) || (val <: Timestamp)
        elseif O == ORA_ORACLE_TYPE_TIMESTAMP_TZ
            @assert val <: TimestampTZ{false}
        elseif O == ORA_ORACLE_TYPE_TIMESTAMP_LTZ
            @assert val <: TimestampTZ{true}
        else
            error("Oracle type $O not supported.")
        end

        return quote
            ts = OraTimestamp(val)
            dpiData_setTimestamp(at, ts)
        end
    end

    if N == ORA_NATIVE_TYPE_LOB
        @assert val <: Lob "Value must be of type `Oracle.Lob`."
        return quote
            dpiData_setLOB(at, val.handle)
        end
    end

    if N == ORA_NATIVE_TYPE_NUMBER
        @assert val <: OraNumber "Value must be of type `Oracle.OraNumber`."
        return quote
            dpiData_setNumber(at, val)
        end
    end

    error("Setting values to AbstractOracleValue{$O, $N} is not supported.")
end

encoding(ora_string::OraBytes) = unsafe_string(ora_string.encoding)

function encoding(ora_string_ptr::Ptr{OraBytes})
    ora_string = unsafe_load(ora_string_ptr)
    return encoding(ora_string)
end

@generated function encoding(val::AbstractOracleValue{O,N}, offset::Integer=1) where {O,N}
    @assert offset > 0 "Invalid offset $offset."
    @assert N == ORA_NATIVE_TYPE_BYTES "Native type must be Oracle.ORA_NATIVE_TYPE_BYTES. Found: $N."

    return quote
        ptr_bytes = dpiData_getBytes(get_data_handle(val, offset))
        return encoding(ptr_bytes)
    end
end

#
# Get/Set Implementation for JuliaOracleValue
#

@inline function parse_oracle_value(oracle_value::JuliaOracleValue{O,N,T}, offset::Integer=1) where {O,N,T}
    @assert offset > 0 "Invalid offset $offset."
    return oracle_value.buffer[offset]
end

@inline function set_oracle_value!(oracle_value::AbstractOracleValue{O,N}, val::T, offset::Integer) where {O,N,T}
    return set_oracle_value_at!(oracle_value, val, get_data_handle(oracle_value, offset))
end

struct OracleTypeTuple
    oracle_type::OraOracleTypeNum
    native_type::OraNativeTypeNum
end

# accept julia types as arguments
@inline infer_oracle_type_tuple(::Type{Bool}) = OracleTypeTuple(ORA_ORACLE_TYPE_BOOLEAN, ORA_NATIVE_TYPE_BOOLEAN)
@inline infer_oracle_type_tuple(::Type{Float64}) = OracleTypeTuple(ORA_ORACLE_TYPE_NATIVE_DOUBLE, ORA_NATIVE_TYPE_DOUBLE)
@inline infer_oracle_type_tuple(::Type{Int64}) = OracleTypeTuple(ORA_ORACLE_TYPE_NATIVE_INT, ORA_NATIVE_TYPE_INT64)
@inline infer_oracle_type_tuple(::Type{UInt64}) = OracleTypeTuple(ORA_ORACLE_TYPE_NATIVE_UINT, ORA_NATIVE_TYPE_UINT64)
@inline infer_oracle_type_tuple(::Type{Date}) = OracleTypeTuple(ORA_ORACLE_TYPE_DATE, ORA_NATIVE_TYPE_TIMESTAMP)
@inline infer_oracle_type_tuple(::Type{DateTime}) = infer_oracle_type_tuple(Timestamp)
@inline infer_oracle_type_tuple(::Type{Timestamp}) = OracleTypeTuple(ORA_ORACLE_TYPE_TIMESTAMP, ORA_NATIVE_TYPE_TIMESTAMP)
@inline infer_oracle_type_tuple(::Type{OraNumber}) = OracleTypeTuple(ORA_ORACLE_TYPE_NUMBER, ORA_NATIVE_TYPE_NUMBER)

# accept julia values as arguments
for type_sym in (:Bool, :Float64, :Int64, :UInt64, :Date, :DateTime, :Timestamp)
    @eval begin
        @inline infer_oracle_type_tuple(::$type_sym) = infer_oracle_type_tuple($type_sym)
    end
end

@inline infer_oracle_type_tuple(::Type{Lob{O,P}}) where {O,P} = OracleTypeTuple(O, ORA_NATIVE_TYPE_LOB)
@inline infer_oracle_type_tuple(::Lob{O,P}) where {O,P} = OracleTypeTuple(O, ORA_NATIVE_TYPE_LOB)

@inline infer_oracle_type_tuple(::Type{TimestampTZ{false}}) = OracleTypeTuple(ORA_ORACLE_TYPE_TIMESTAMP_TZ, ORA_NATIVE_TYPE_TIMESTAMP)
@inline infer_oracle_type_tuple(::TimestampTZ{false}) = OracleTypeTuple(ORA_ORACLE_TYPE_TIMESTAMP_TZ, ORA_NATIVE_TYPE_TIMESTAMP)
@inline infer_oracle_type_tuple(::Type{TimestampTZ{true}}) = OracleTypeTuple(ORA_ORACLE_TYPE_TIMESTAMP_LTZ, ORA_NATIVE_TYPE_TIMESTAMP)
@inline infer_oracle_type_tuple(::TimestampTZ{true}) = OracleTypeTuple(ORA_ORACLE_TYPE_TIMESTAMP_LTZ, ORA_NATIVE_TYPE_TIMESTAMP)

@inline function infer_oracle_type_tuple(s::String)
    # max VARCHAR2 size is 4000 bytes
    if sizeof(s) <= 4000
        return OracleTypeTuple(ORA_ORACLE_TYPE_NVARCHAR, ORA_NATIVE_TYPE_BYTES)
    else
        return OracleTypeTuple(ORA_ORACLE_TYPE_NCLOB, ORA_NATIVE_TYPE_LOB)
    end
end

@inline function infer_oracle_type_tuple(::Type{String})
    # without information about string length, will best guess as a NVARCHAR
    return OracleTypeTuple(ORA_ORACLE_TYPE_NVARCHAR, ORA_NATIVE_TYPE_BYTES)
end

@inline function infer_oracle_type_tuple(b::Vector{UInt8})
    if length(b) <= 2000
        return OracleTypeTuple(ORA_ORACLE_TYPE_RAW, ORA_NATIVE_TYPE_BYTES)
    else
        return OracleTypeTuple(ORA_ORACLE_TYPE_LONG_RAW, ORA_NATIVE_TYPE_BYTES)
    end
end

@inline function infer_oracle_type_tuple(::Type{Vector{UInt8}})
    # without information about string length, will best guess as a RAW
    return OracleTypeTuple(ORA_ORACLE_TYPE_RAW, ORA_NATIVE_TYPE_BYTES)
end

function JuliaOracleValue(scalar::T) where {T}
    ott = infer_oracle_type_tuple(scalar)
    val = JuliaOracleValue(ott.oracle_type, ott.native_type, T)
    val[] = scalar
    return val
end
