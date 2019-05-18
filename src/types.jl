
# 24 bytes -> sizeof dpiDataBuffer on 64bit arch
primitive type OraDataBuffer 24 * 8 end

struct OraData
    is_null::Int32 # Specifies if the value refers to a null value (1) or not (0).
    value::OraDataBuffer
end

struct OraTimestamp
    year::Int16
    month::UInt8
    day::UInt8
    hour::UInt8
    minute::UInt8
    second::UInt8
    fsecond::UInt32 # Specifies the fractional seconds for the timestamp, in nanoseconds.
    tzHourOffset::Int8 # Specifies the hours offset from UTC. This value is only used for timestamp with time zone and timestamp with local time zone columns.
    tzMinuteOffset::Int8 # Specifies the minutes offset from UTC. This value is only used for timestamp with time zone and timestamp with local time zone columns. Note that this value will be negative in the western hemisphere. For example, when the timezone is -03:30, tzHourOffset will be -3 and tzMinuteOffset will be -30.

    function OraTimestamp(year::Integer, month::Integer, day::Integer,
                          hour::Integer, minute::Integer, second::Integer, fsecond::Integer,
                          tz_hour_offset::Integer, tz_minute_offset::Integer)

        return new(Int16(year), UInt8(month), UInt8(day),
                   UInt8(hour), UInt8(minute), UInt8(second), UInt32(fsecond),
                   Int8(tz_hour_offset), Int8(tz_minute_offset)
               )
    end
end

struct OraErrorInfo <: Exception
    code::Int32 # The OCI error code if an OCI error has taken place. If no OCI error has taken place the value is 0.
    offset::UInt16 # The parse error offset (in bytes) when executing a statement or the row offset when fetching batch error information. If neither of these cases are true, the value is 0.
    message::Ptr{UInt8} # The error message as a byte string in the encoding specified by the OraErrorInfo.encoding member.
    message_length::UInt32 # The length of the OraErrorInfo.message member, in bytes.
    encoding::Cstring # The encoding in which the error message is encoded as a null-terminated string. For OCI errors this is the CHAR encoding used when the connection was created. For ODPI-C specific errors this is UTF-8.
    fn_name::Cstring # The public ODPI-C function name which was called in which the error took place. This is a null-terminated ASCII string.
    action::Cstring # The internal action that was being performed when the error took place. This is a null-terminated ASCII string.
    sql_state::Cstring # The SQLSTATE code associated with the error. This is a 5 character null-terminated string.
    is_recoverable::Int32 # A boolean value indicating if the error is recoverable. This member always has a value of 0 unless both client and server are at release 12.1 or higher.
end

Base.showerror(io::IO, err::OraErrorInfo) = print(io, unsafe_string(err.message, err.message_length))

struct OraVersionInfo
    version::Int32 # Specifies the major version of the Oracle Client or Database.
    release::Int32 # Specifies the release version of the Oracle Client or Database.
    update::Int32 # Specifies the update version of the Oracle Client or Database.
    port_release::Int32 # Specifies the port specific release version of the Oracle Client or Database.
    port_update::Int32 # Specifies the port specific update version of the Oracle Client or Database.
    full_version::Int32 # Specifies the full version (all five components) as a number that is suitable for comparison with the result of the macro DPI_ORACLE_VERSION_TO_NUMBER.
end

mutable struct OraCommonCreateParams
    create_mode::OraCreateMode # Specifies the mode used for creating connections. It is expected to be one or more of the values from the enumeration OraCreateMode, OR’ed together. The default value is DPI_MODE_CREATE_DEFAULT.
    encoding::Cstring # Specifies the encoding to use for CHAR data, as a null-terminated ASCII string. Either an IANA or Oracle specific character set name is expected. NULL is also acceptable which implies the use of the NLS_LANG environment variable (or ASCII, if the NLS_LANG environment variable is not set). The default value is NULL.
    nencoding::Cstring # Specifies the encoding to use for NCHAR data, as a null-terminated ASCII string. Either an IANA or Oracle specific character set name is expected. NULL is also acceptable which implies the use of the NLS_NCHAR environment variable (or the same value as the OraCommonCreateParams.encoding member if the NLS_NCHAR environment variable is not set). The default value is NULL.
    edition::Ptr{UInt8} # Specifies the edition to be used when creating a standalone connection. It is expected to be NULL (meaning that no edition is set) or a byte string in the encoding specified by the OraCommonCreateParams.encoding member. The default value is NULL.
    edition_length::UInt32 # Specifies the length of the OraCommonCreateParams.edition member, in bytes. The default value is 0.
    driver_name::Ptr{UInt8} # Specifies the name of the driver that is being used. It is expected to be NULL or a byte string in the encoding specified by the OraCommonCreateParams.encoding member. The default value is NULL.
    driver_name_length::UInt32 # Specifies the length of the OraCommonCreateParams.driverName member, in bytes. The default value is 0.
end

struct OraAppContext
    namespace_name::Ptr{UInt8} # Specifies the value of the “namespace” parameter to sys_context(). It is expected to be a byte string in the encoding specified in the OraConnCreateParams structure and must not be NULL.
    namespace_name_length::UInt32 # Specifies the length of the OraAppContext.namespaceName member, in bytes.
    name::Ptr{UInt8} # Specifies the value of the “parameter” parameter to sys_context(). It is expected to be a byte string in the encoding specified in the OraConnCreateParams structure and must not be NULL.
    name_length::UInt32 # Specifies the length of the OraAppContext.name member, in bytes.
    value::Ptr{UInt8} # Specifies the value that will be returned from sys_context(). It is expected to be a byte string in the encoding specified in the OraConnCreateParams structure and must not be NULL.
    value_length::UInt32 # Specifies the length of the OraAppContext.value member, in bytes.
end

mutable struct OraConnCreateParams
    auth_mode::OraAuthMode
    connection_class::Ptr{UInt8}
    connection_class_length::UInt32
    purity::OraPurity
    new_password::Ptr{UInt8}
    new_password_length::UInt32
    app_context::Ptr{OraAppContext} # Specifies the application context that will be set when the connection is created. This value is only used when creating standalone connections. It is expected to be NULL or an array of OraAppContext structures. The context specified here can be used in logon triggers, for example. The default value is NULL.
    num_app_context::UInt32 # Specifies the number of elements found in the OraConnCreateParams.appContext member. The default value is 0.
    external_auth::Int32 # Specifies whether external authentication should be used to create the connection. If this value is 0, the user name and password values must be specified in the call to OraConn_create(); otherwise, the user name and password values must be zero length or NULL. The default value is 0.
    external_handle::Ptr{Cvoid} # Specifies an OCI service context handle created externally that will be used instead of creating a connection. The default value is NULL.
    pool_handle::Ptr{Cvoid} # Specifies the session pool from which to acquire a connection or NULL if a standalone connection should be created. The default value is NULL.
    tag::Ptr{UInt8}
    tag_length::UInt32
    match_any_tag::Int32
    out_tag::Ptr{UInt8}
    out_tag_length::UInt32
    out_tag_found::Int32
    sharding_key_columns::Ptr{Cvoid} # TODO
    num_sharding_key_columns::UInt8 # TODO
    super_sharding_key_columns::Ptr{Cvoid} # TODO
    num_super_sharding_key_columns::UInt8 # TODO
end

mutable struct OraPoolCreateParams
    min_sessions::UInt32 # Specifies the minimum number of sessions to be created by the session pool. This value is ignored if the OraPoolCreateParams.homogeneous member has a value of 0. The default value is 1.
    max_sessions::UInt32 # Specifies the maximum number of sessions that can be created by the session pool. Values of 1 and higher are acceptable. The default value is 1.
    session_increment::UInt32 # Specifies the number of sessions that will be created by the session pool when more sessions are required and the number of sessions is less than the maximum allowed. This value is ignored if the OraPoolCreateParams.homogeneous member has a value of 0. This value added to the OraPoolCreateParams.minSessions member value must not exceed the OraPoolCreateParams.maxSessions member value. The default value is 0.
    ping_interval::Int32 # Specifies the number of seconds since a connection has last been used before a ping will be performed to verify that the connection is still valid. A negative value disables this check. The default value is 60.
    ping_timeout::Int32 # Specifies the number of milliseconds to wait when performing a ping to verify the connection is still valid before the connection is considered invalid and is dropped. The default value is 5000 (5 seconds). This value is ignored in clients 12.2 and later since a much faster internal check is done by the Oracle client.
    homogeneous::Int32 # Specifies whether the pool is homogeneous or not. In a homogeneous pool all connections use the same credentials whereas in a heterogeneous pool other credentials are permitted. The default value is 1.
    external_auth::Int32 # Specifies whether external authentication should be used to create the sessions in the pool. If this value is 0, the user name and password values must be specified in the call to dpiPool_create(); otherwise, the user name and password values must be zero length or NULL. The default value is 0. External authentication cannot be used with homogeneous pools.
    get_mode::OraPoolGetMode # Specifies the mode to use when sessions are acquired from the pool. It is expected to be one of the values from the enumeration OraPoolGetMode. The default value is DPI_MODE_POOL_GET_NOWAIT. This value can be set after the pool has been created using the function dpiPool_setGetMode() and acquired using the function dpiPool_getGetMode().
    out_pool_name::Ptr{UInt8} # This member is populated upon successful creation of a pool using the function dpiPool_create(). It is a byte string in the encoding used for CHAR data. Any value specified prior to creating the session pool is ignored.
    out_pool_name_length::UInt32 # This member is populated upon successful creation of a pool using the function dpiPool_create(). It is the length of the OraPoolCreateParams.outPoolName member, in bytes. Any value specified prior to creating the session pool is ignored.
    timeout::UInt32 # Specifies the length of time (in seconds) after which idle sessions in the pool are terminated. Note that termination only occurs when the pool is accessed. The default value is 0 which means that no idle sessions are terminated. This value can be set after the pool has been created using the function dpiPool_setTimeout() and acquired using the function dpiPool_getTimeout().
    wait_timeout::UInt32 # Specifies the length of time (in milliseconds) that the caller should wait for a session to become available in the pool before returning with an error. This value is only used if the OraPoolCreateParams.getMode member is set to the value DPI_MODE_POOL_GET_TIMEDWAIT. The default value is 0. This value can be set after the pool has been created using the function dpiPool_setWaitTimeout() and acquired using the function dpiPool_getWaitTimeout().
    max_lifetime_session::UInt32 # Specifies the maximum length of time (in seconds) a pooled session may exist. Sessions in use will not be closed. They become candidates for termination only when they are released back to the pool and have existed for longer than maxLifetimeSession seconds. Session termination only occurs when the pool is accessed. The default value is 0 which means that there is no maximum length of time that a pooled session may exist. This value can be set after the pool has been created using the function dpiPool_setMaxLifetimeSession() and acquired using the function dpiPool_getMaxLifetimeSession().
    plsql_fixup_callback::Ptr{UInt8}
    plsql_fixup_callback_length::UInt32
end

struct OraDataTypeInfo
    oracle_type_num::OraOracleTypeNum # Specifies the type of the data. It will be one of the values from the enumeration OraOracleTypeNum, or 0 if the type is not supported by ODPI-C.
    default_native_type_num::OraNativeTypeNum # Specifies the default native type for the data. It will be one of the values from the enumeration OraNativeTypeNum, or 0 if the type is not supported by ODPI-C.
    oci_type_code::UInt16 # Specifies the OCI type code for the data, which can be useful if the type is not supported by ODPI-C.
    db_size_in_bytes::UInt32 # Specifies the size in bytes (from the database’s perspective) of the data. This value is only populated for strings and binary data. For all other data the value is zero.
    client_size_in_bytes::UInt32 # Specifies the size in bytes (from the client’s perspective) of the data. This value is only populated for strings and binary data. For all other data the value is zero.
    size_in_chars::UInt32 # Specifies the size in characters of the data. This value is only populated for string data. For all other data the value is zero.
    precision::Int16 # Specifies the precision of the data. This value is only populated for numeric and interval data. For all other data the value is zero.
    scale::Int8 # Specifies the scale of the data. This value is only populated for numeric data. For all other data the value is zero.
    fs_precision::Int16 # Specifies the fractional seconds precision of the data. This value is only populated for timestamp and interval day to second data. For all other data the value is zero.
    object_type_handle::Ptr{Cvoid} # Specifies a reference to the type of the object. This value is only populated for named type data. For all other data the value is NULL. This reference is owned by the object attribute, object type or statement and a call to OraObjectType_addRef() must be made if the reference is going to be used beyond the lifetime of the owning object.
end

struct OraQueryInfo
    name::Ptr{UInt8} # Specifies the name of the column which is being queried, as a byte string in the encoding used for CHAR data.
    name_length::UInt32 # Specifies the length of the OraQueryInfo.name member, in bytes.
    type_info::OraDataTypeInfo # Specifies the type of data of the column that is being queried. It is a structure of type OraDataTypeInfo.
    null_ok::Int32 # Specifies if the data that is being queried may return null values (1) or not (0).
end

struct OraStmtInfo
    is_query::Int32
    is_PLSQL::Int32
    is_DDL::Int32
    is_DML::Int32
    statement_type::OraStatementType
    is_returning::Int32
end

"High-level version for OraStmtInfo using Bool Julia type."
struct StmtInfo
    is_query::Bool
    is_PLSQL::Bool
    is_DDL::Bool
    is_DML::Bool
    statement_type::OraStatementType
    is_returning::Bool

    function StmtInfo(ora_stmt_info::OraStmtInfo)

        return new(
                Bool(ora_stmt_info.is_query),
                Bool(ora_stmt_info.is_PLSQL),
                Bool(ora_stmt_info.is_DDL),
                Bool(ora_stmt_info.is_DML),
                ora_stmt_info.statement_type,
                Bool(ora_stmt_info.is_returning)
            )
    end
end

struct OraBytes
    ptr::Ptr{UInt8}
    length::UInt32
    encoding::Cstring
end

Base.show(io::IO, ptr::Ptr{OraBytes}) = show(io, unsafe_load(ptr))

function Base.show(io::IO, ora_str::OraBytes)
    str = unsafe_string(ora_str.ptr, ora_str.length)
    enc = unsafe_string(ora_str.encoding)
    print(io, "OraBytes(", str, ", ", enc, ")")
end

#=
This structure is used for transferring encoding information from ODPI-C.
All of the information here remains valid as long as a reference is held
to the standalone connection or session pool from which the information was taken.
=#
struct OraEncodingInfo
    encoding::Cstring # The encoding used for CHAR data, as a null-terminated ASCII string.
    max_bytes_per_character::Int32 # The maximum number of bytes required for each character in the encoding used for CHAR data. This value is used when calculating the size of buffers required when lengths in characters are provided.
    nencoding::Cstring # The encoding used for NCHAR data, as a null-terminated ASCII string.
    nmax_bytes_per_character::Int32 # The maximum number of bytes required for each character in the encoding used for NCHAR data. Since this information is not directly available from Oracle it is only accurate if the encodings used for CHAR and NCHAR data are identical or one of ASCII or UTF-8; otherwise a value of 4 is assumed. This value is used when calculating the size of buffers required when lengths in characters are provided.
end

"Mirrors ODPI-C's OraEncodingInfo struct, but using Julia types."
struct EncodingInfo
    encoding::String
    max_bytes_per_character::Int
    nencoding::String
    nmax_bytes_per_character::Int

    function EncodingInfo(encoding_info_ref::Ref{OraEncodingInfo})
        encoding_info = encoding_info_ref[]
        return new(
            unsafe_string(encoding_info.encoding),
            Int(encoding_info.max_bytes_per_character),
            unsafe_string(encoding_info.nencoding),
            Int(encoding_info.nmax_bytes_per_character)
        )
    end
end

mutable struct Context
    handle::Ptr{Cvoid}

    function Context(handle::Ptr{Cvoid})
        new_context = new(handle)
        @compat finalizer(destroy!, new_context)
        return new_context
    end
end

function destroy!(ctx::Context)
    if ctx.handle != C_NULL
        result = dpiContext_destroy(ctx.handle)
        error_check(ctx, result)
        ctx.handle = C_NULL
    end
    nothing
end

mutable struct Pool
    context::Context
    handle::Ptr{Cvoid}
    name::String

    function Pool(context::Context, handle::Ptr{Cvoid}, name::String)
        new_pool = new(context, handle, name)
        @compat finalizer(destroy!, new_pool)
        return new_pool
    end
end

function destroy!(pool::Pool)
    if pool.handle != C_NULL
        result = dpiPool_release(pool.handle)
        error_check(context(pool), result)
        pool.handle = C_NULL
    end
    nothing
end

mutable struct Connection
    context::Context
    handle::Ptr{Cvoid}
    encoding_info::EncodingInfo
    pool::Union{Nothing, Pool}

    function Connection(context::Context, handle::Ptr{Cvoid}, pool::Union{Nothing, Pool})

        # this driver currently only supports UTF-8 encoding
        function check_supported_encoding(ei::EncodingInfo)
            @assert ei.encoding ∈ SUPPORTED_CONNECTION_ENCODINGS "Unsupported encoding for CHARS: $(ei.encoding). Currently, Oracle.jl supports only $(SUPPORTED_CONNECTION_ENCODINGS)."
            @assert ei.nencoding ∈ SUPPORTED_CONNECTION_ENCODINGS  "Unsupported encoding for CHARS: $(ei.nencoding). Currently, Oracle.jl supports only $(SUPPORTED_CONNECTION_ENCODINGS)."
        end

        ei = EncodingInfo(context, handle)
        check_supported_encoding(ei)

        new_connection = new(context, handle, ei, pool)
        @compat finalizer(destroy!, new_connection)
        return new_connection
    end
end

function EncodingInfo(context::Context, connection_handle::Ptr{Cvoid})
    encoding_info_ref = Ref{OraEncodingInfo}()
    result = dpiConn_getEncodingInfo(connection_handle, encoding_info_ref)
    error_check(context, result)
    return EncodingInfo(encoding_info_ref)
end

function destroy!(conn::Connection)
    if conn.handle != C_NULL
        result = dpiConn_release(conn.handle)
        error_check(context(conn), result)
        conn.handle = C_NULL
        conn.pool = nothing
    end
    nothing
end

mutable struct Stmt{statement_type}
    connection::Connection
    handle::Ptr{Cvoid}
    scrollable::Bool
    info::StmtInfo
    bind_count::UInt32
    bind_names::Vector{String}
    bind_names_index::Dict{String, UInt32} # maps bind_name to bind position
    is_open::Bool
    columns_info::Union{Nothing, Vector{OraQueryInfo}}
end

const QueryStmt = Stmt{ORA_STMT_TYPE_SELECT}

function destroy!(stmt::Stmt)
    if stmt.handle != C_NULL
        result = dpiStmt_release(stmt.handle)
        error_check(context(stmt), result)
        stmt.handle = C_NULL
    end
    nothing
end

"Holds a 1-indexed vector of OraData."
abstract type AbstractOracleValue{O,N} end

"Wraps a OraData handle managed by extern ODPI-C. 1-indexed."
struct ExternOracleValue{O,N,P} <: AbstractOracleValue{O,N}
    parent::P
    data_handle::Ptr{OraData}
    use_add_ref::Bool # triggers a call to add_ref, if data_handle is a LOB, statement, object or rowid that is owned by the statement
end

function ExternOracleValue(parent::P, oracle_type::OraOracleTypeNum, native_type::OraNativeTypeNum, handle::Ptr{OraData}; use_add_ref::Bool=false) where {P}
    return ExternOracleValue{oracle_type, native_type, P}(parent, handle, use_add_ref)
end

"Wraps a OraData handle managed by Julia. 1-indexed."
struct JuliaOracleValue{O,N,T} <: AbstractOracleValue{O,N}
    buffer::Vector{T}
end

function JuliaOracleValue(oracle_type::OraOracleTypeNum, native_type::OraNativeTypeNum, ::Type{T}, capacity::Integer=1) where {T}
    buffer = undef_vector(T, capacity)
    return JuliaOracleValue{oracle_type,native_type,T}(buffer)
end

struct FetchResult
    found::Bool
    buffer_row_index::UInt32
end

Base.show(io::IO, result::FetchResult) = print(io, "FetchResult(", result.found, ", ", Int(result.buffer_row_index), ")")

struct FetchRowsResult
    buffer_row_index::UInt32
    num_rows_fetched::UInt32
    more_rows::Int32
end

Base.show(io::IO, result::FetchRowsResult) = print(io, "FetchRowsResult(", Int(result.buffer_row_index), ", " ,Int(result.num_rows_fetched), ", ",Int(result.more_rows), ")")

struct CursorSchema
    column_query_info::Vector{OraQueryInfo}
    column_names_index::Dict{String, Int}
end

struct Cursor
    stmt::QueryStmt
    schema::CursorSchema
end

struct ResultSetRow
    schema::CursorSchema
    data::Vector{Any}
end

struct ResultSet
    schema::CursorSchema
    rows::Vector{ResultSetRow}
end

"Safe version of OraCommonCreateParams"
mutable struct CommonCreateParams
    create_mode::Union{Nothing, OraCreateMode}
    encoding::String
    nencoding::String
    edition::Union{Nothing, String}
    driver_name::Union{Nothing, String}
end

"Safe version of OraConnCreateParams"
mutable struct ConnCreateParams
    auth_mode::OraAuthMode
    pool::Union{Nothing, Pool}
end

mutable struct Variable{T}
    connection::Connection
    handle::Ptr{Cvoid}
    oracle_type::OraOracleTypeNum
    native_type::OraNativeTypeNum
    max_byte_string_size_in_bytes::UInt32 # size. the maximum size of the buffer used for transferring data to/from Oracle. This value is only used for variables transferred as byte strings.
    is_PLSQL_array::Int32 # boolean value indicating if the variable refers to a PL/SQL array or simply to buffers used for binding or fetching data.
    obj_type_handle::Ptr{Cvoid}
    buffer_handle::Ptr{OraData} # a pointer to an array of dpiData structures that are used to transfer data to/from the variable. These are allocated when the variable is created and the number of structures corresponds to the maxArraySize.
    buffer_capacity::UInt32 # maxArraySize. the maximum number of rows that can be fetched or bound at one time from the database, or the maximum number of elements that can be stored in a PL/SQL array.

    function Variable(
            connection::Connection,
            ::Type{T},
            handle::Ptr{Cvoid},
            oracle_type::OraOracleTypeNum,
            native_type::OraNativeTypeNum,
            max_byte_string_size_in_bytes::UInt32,
            is_PLSQL_array::Int32,
            obj_type_handle::Ptr{Cvoid},
            buffer_handle::Ptr{OraData},
            buffer_capacity::UInt32) where {T}

        new_ora_variable = new{T}(
            connection,
            handle,
            oracle_type,
            native_type,
            max_byte_string_size_in_bytes,
            is_PLSQL_array,
            obj_type_handle,
            buffer_handle,
            buffer_capacity)

        @compat finalizer(destroy!, new_ora_variable)

        return new_ora_variable
    end
end

function destroy!(v::Variable)
    if v.handle != C_NULL
        result = dpiVar_release(v.handle)
        error_check(context(v), result)
        v.handle = C_NULL
        v.obj_type_handle = C_NULL
        v.buffer_handle = C_NULL
    end
    nothing
end

mutable struct Lob{ORATYPE,T}
    parent::T
    handle::Ptr{Cvoid}
    is_open::Bool

    function Lob(p::T, handle::Ptr{Cvoid}, oracle_type::OraOracleTypeNum; use_add_ref::Bool=false) where {T}
        check_valid_lob_oracle_type_num(oracle_type)
        new_lob = new{oracle_type, T}(p, handle, true)
        @compat finalizer(destroy!, new_lob)

        if use_add_ref
            add_ref(new_lob)
        end

        return new_lob
    end
end

function destroy!(lob::Lob)
    if lob.handle != C_NULL
        result = dpiLob_release(lob.handle)
        error_check(context(lob), result)
        lob.handle = C_NULL
    end
    nothing
end
