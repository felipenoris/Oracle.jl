
const DPI_MAJOR_VERSION = UInt32(3)
const DPI_MINOR_VERSION = UInt32(0)
const DPI_PATCH_LEVEL = UInt32(0)
const DPI_DEFAULT_FETCH_ARRAY_SIZE = UInt32(100)
const DPI_DEFAULT_PING_INTERVAL = UInt32(60)
const DPI_DEFAULT_PING_TIMEOUT = UInt32(5000)
const DPI_DEQ_WAIT_NO_WAIT = UInt32(0)
const DPI_MAX_INT64_PRECISION = UInt32(18)

@enum dpiResult::Int32 begin
    DPI_SUCCESS = 0
    DPI_FAILURE = -1
end

"""
This enumeration identifies the mode to use when authorizing connections to the database.
"""
@enum dpiAuthMode::UInt32 begin
    DPI_MODE_AUTH_DEFAULT = 0
    DPI_MODE_AUTH_SYSDBA  = 2
    DPI_MODE_AUTH_SYSOPER = 4
    DPI_MODE_AUTH_PRELIM  = 8
    DPI_MODE_AUTH_SYSASM  = 32768
    DPI_MODE_AUTH_SYSBKP  = 131072
    DPI_MODE_AUTH_SYSDGD  = 262144
    DPI_MODE_AUTH_SYSKMT  = 524288
    DPI_MODE_AUTH_SYSRAC  = 1048576
end

@enum dpiConnCloseMode::UInt32 begin
    DPI_MODE_CONN_CLOSE_DEFAULT = 0
    DPI_MODE_CONN_CLOSE_DROP    = 1
    DPI_MODE_CONN_CLOSE_RETAG   = 2
end

"""
This enumeration identifies the mode to use when creating connections to the database. Note that the OCI objects mode is always enabled.
"""
@enum dpiCreateMode::UInt32 begin
    DPI_MODE_CREATE_DEFAULT  = 0
    DPI_MODE_CREATE_THREADED = 1
    DPI_MODE_CREATE_EVENTS   = 4
end

"""
This enumeration identifies the mode to use when getting sessions from a session pool.
"""
@enum dpiPoolGetMode::UInt32 begin
    DPI_MODE_POOL_GET_WAIT      = 0
    DPI_MODE_POOL_GET_NOWAIT    = 1
    DPI_MODE_POOL_GET_FORCEGET  = 2
    DPI_MODE_POOL_GET_TIMEDWAIT = 3
end

"""
This enumeration identifies the purity of the sessions that are acquired when using connection classes during connection creation.
"""
@enum dpiPurity::UInt32 begin
    DPI_PURITY_DEFAULT = 0
    DPI_PURITY_NEW     = 1
    DPI_PURITY_SELF    = 2
end

@enum dpiShutdownMode::UInt32 begin
    DPI_MODE_SHUTDOWN_DEFAULT             = 0
    DPI_MODE_SHUTDOWN_TRANSACTIONAL       = 1
    DPI_MODE_SHUTDOWN_TRANSACTIONAL_LOCAL = 2
    DPI_MODE_SHUTDOWN_IMMEDIATE           = 3
    DPI_MODE_SHUTDOWN_ABORT               = 4
    DPI_MODE_SHUTDOWN_FINAL               = 5
end

@enum dpiStartupMode::UInt32 begin
    DPI_MODE_STARTUP_DEFAULT  = 0
    DPI_MODE_STARTUP_FORCE    = 1
    DPI_MODE_STARTUP_RESTRICT = 2
end

@enum dpiExecMode::UInt32 begin
    DPI_MODE_EXEC_DEFAULT             = 0
    DPI_MODE_EXEC_DESCRIBE_ONLY       = 16
    DPI_MODE_EXEC_COMMIT_ON_SUCCESS   = 32
    DPI_MODE_EXEC_BATCH_ERRORS        = 128
    DPI_MODE_EXEC_PARSE_ONLY          = 256
    DPI_MODE_EXEC_ARRAY_DML_ROWCOUNTS = 1048576
end

@enum dpiOracleTypeNum::UInt32 begin
    DPI_ORACLE_TYPE_NONE          = 2000
    DPI_ORACLE_TYPE_VARCHAR       = 2001
    DPI_ORACLE_TYPE_NVARCHAR      = 2002
    DPI_ORACLE_TYPE_CHAR          = 2003
    DPI_ORACLE_TYPE_NCHAR         = 2004
    DPI_ORACLE_TYPE_ROWID         = 2005
    DPI_ORACLE_TYPE_RAW           = 2006
    DPI_ORACLE_TYPE_NATIVE_FLOAT  = 2007
    DPI_ORACLE_TYPE_NATIVE_DOUBLE = 2008
    DPI_ORACLE_TYPE_NATIVE_INT    = 2009
    DPI_ORACLE_TYPE_NUMBER        = 2010
    DPI_ORACLE_TYPE_DATE          = 2011
    DPI_ORACLE_TYPE_TIMESTAMP     = 2012
    DPI_ORACLE_TYPE_TIMESTAMP_TZ  = 2013
    DPI_ORACLE_TYPE_TIMESTAMP_LTZ = 2014
    DPI_ORACLE_TYPE_INTERVAL_DS   = 2015
    DPI_ORACLE_TYPE_INTERVAL_YM   = 2016
    DPI_ORACLE_TYPE_CLOB          = 2017
    DPI_ORACLE_TYPE_NCLOB         = 2018
    DPI_ORACLE_TYPE_BLOB          = 2019
    DPI_ORACLE_TYPE_BFILE         = 2020
    DPI_ORACLE_TYPE_STMT          = 2021
    DPI_ORACLE_TYPE_BOOLEAN       = 2022
    DPI_ORACLE_TYPE_OBJECT        = 2023
    DPI_ORACLE_TYPE_LONG_VARCHAR  = 2024
    DPI_ORACLE_TYPE_LONG_RAW      = 2025
    DPI_ORACLE_TYPE_NATIVE_UINT   = 2026
    DPI_ORACLE_TYPE_MAX           = 2027
end

@enum dpiNativeTypeNum::UInt32 begin
    DPI_NATIVE_TYPE_INT64       = 3000
    DPI_NATIVE_TYPE_UINT64      = 3001
    DPI_NATIVE_TYPE_FLOAT       = 3002
    DPI_NATIVE_TYPE_DOUBLE      = 3003
    DPI_NATIVE_TYPE_BYTES       = 3004
    DPI_NATIVE_TYPE_TIMESTAMP   = 3005
    DPI_NATIVE_TYPE_INTERVAL_DS = 3006
    DPI_NATIVE_TYPE_INTERVAL_YM = 3007
    DPI_NATIVE_TYPE_LOB         = 3008
    DPI_NATIVE_TYPE_OBJECT      = 3009
    DPI_NATIVE_TYPE_STMT        = 3010
    DPI_NATIVE_TYPE_BOOLEAN     = 3011
    DPI_NATIVE_TYPE_ROWID       = 3012
end

@enum dpiStatementType::UInt16 begin
    DPI_STMT_TYPE_UNKNOWN      = 0
    DPI_STMT_TYPE_SELECT       = 1
    DPI_STMT_TYPE_UPDATE       = 2
    DPI_STMT_TYPE_DELETE       = 3
    DPI_STMT_TYPE_INSERT       = 4
    DPI_STMT_TYPE_CREATE       = 5
    DPI_STMT_TYPE_DROP         = 6
    DPI_STMT_TYPE_ALTER        = 7
    DPI_STMT_TYPE_BEGIN        = 8
    DPI_STMT_TYPE_DECLARE      = 9
    DPI_STMT_TYPE_CALL         = 10
    DPI_STMT_TYPE_EXPLAIN_PLAN = 15
    DPI_STMT_TYPE_MERGE        = 16
    DPI_STMT_TYPE_ROLLBACK     = 17
    DPI_STMT_TYPE_COMMIT       = 21
end

# 24 bytes -> sizeof dpiDataBuffer on 64bit arch
primitive type dpiDataBuffer 24 * 8 end

"""
This structure is used for passing data to and from the database for variables and for manipulating object attributes and collection values.
"""
struct dpiData
    is_null::Int32 # Specifies if the value refers to a null value (1) or not (0).
    value::dpiDataBuffer
end

struct dpiErrorInfo <: Exception
    code::Int32 # The OCI error code if an OCI error has taken place. If no OCI error has taken place the value is 0.
    offset::UInt16 # The parse error offset (in bytes) when executing a statement or the row offset when fetching batch error information. If neither of these cases are true, the value is 0.
    message::Ptr{UInt8} # The error message as a byte string in the encoding specified by the dpiErrorInfo.encoding member.
    message_length::UInt32 # The length of the dpiErrorInfo.message member, in bytes.
    encoding::Cstring # The encoding in which the error message is encoded as a null-terminated string. For OCI errors this is the CHAR encoding used when the connection was created. For ODPI-C specific errors this is UTF-8.
    fn_name::Cstring # The public ODPI-C function name which was called in which the error took place. This is a null-terminated ASCII string.
    action::Cstring # The internal action that was being performed when the error took place. This is a null-terminated ASCII string.
    sql_state::Cstring # The SQLSTATE code associated with the error. This is a 5 character null-terminated string.
    is_recoverable::Int32 # A boolean value indicating if the error is recoverable. This member always has a value of 0 unless both client and server are at release 12.1 or higher.
end

Base.showerror(io::IO, err::dpiErrorInfo) = print(io, unsafe_string(err.message, err.message_length))

struct dpiVersionInfo
    version::Int32 # Specifies the major version of the Oracle Client or Database.
    release::Int32 # Specifies the release version of the Oracle Client or Database.
    update::Int32 # Specifies the update version of the Oracle Client or Database.
    port_release::Int32 # Specifies the port specific release version of the Oracle Client or Database.
    port_update::Int32 # Specifies the port specific update version of the Oracle Client or Database.
    full_version::Int32 # Specifies the full version (all five components) as a number that is suitable for comparison with the result of the macro DPI_ORACLE_VERSION_TO_NUMBER.
end

mutable struct dpiCommonCreateParams
    create_mode::dpiCreateMode # Specifies the mode used for creating connections. It is expected to be one or more of the values from the enumeration dpiCreateMode, OR’ed together. The default value is DPI_MODE_CREATE_DEFAULT.
    encoding::Cstring # Specifies the encoding to use for CHAR data, as a null-terminated ASCII string. Either an IANA or Oracle specific character set name is expected. NULL is also acceptable which implies the use of the NLS_LANG environment variable (or ASCII, if the NLS_LANG environment variable is not set). The default value is NULL.
    nencoding::Cstring # Specifies the encoding to use for NCHAR data, as a null-terminated ASCII string. Either an IANA or Oracle specific character set name is expected. NULL is also acceptable which implies the use of the NLS_NCHAR environment variable (or the same value as the dpiCommonCreateParams.encoding member if the NLS_NCHAR environment variable is not set). The default value is NULL.
    edition::Ptr{UInt8} # Specifies the edition to be used when creating a standalone connection. It is expected to be NULL (meaning that no edition is set) or a byte string in the encoding specified by the dpiCommonCreateParams.encoding member. The default value is NULL.
    edition_length::UInt32 # Specifies the length of the dpiCommonCreateParams.edition member, in bytes. The default value is 0.
    driver_name::Ptr{UInt8} # Specifies the name of the driver that is being used. It is expected to be NULL or a byte string in the encoding specified by the dpiCommonCreateParams.encoding member. The default value is NULL.
    driver_name_length::UInt32 # Specifies the length of the dpiCommonCreateParams.driverName member, in bytes. The default value is 0.
end

edition(p::dpiCommonCreateParams) = p.edition == C_NULL ? nothing : unsafe_string(p.edition, p.edition_length)
driver_name(p::dpiCommonCreateParams) = p.driver_name == C_NULL ? nothing : unsafe_string(p.driver_name, p.driver_name_length)

struct dpiAppContext
    namespace_name::Ptr{UInt8} # Specifies the value of the “namespace” parameter to sys_context(). It is expected to be a byte string in the encoding specified in the dpiConnCreateParams structure and must not be NULL.
    namespace_name_length::UInt32 # Specifies the length of the dpiAppContext.namespaceName member, in bytes.
    name::Ptr{UInt8} # Specifies the value of the “parameter” parameter to sys_context(). It is expected to be a byte string in the encoding specified in the dpiConnCreateParams structure and must not be NULL.
    name_length::UInt32 # Specifies the length of the dpiAppContext.name member, in bytes.
    value::Ptr{UInt8} # Specifies the value that will be returned from sys_context(). It is expected to be a byte string in the encoding specified in the dpiConnCreateParams structure and must not be NULL.
    value_length::UInt32 # Specifies the length of the dpiAppContext.value member, in bytes.
end

"""
This structure is used for creating connections to the database, whether standalone or acquired from a session pool. All members are initialized to default values using the dpiContext_initConnCreateParams() function. Care should be taken to ensure a copy of this structure exists only as long as needed to create the connection since it can contain a clear text copy of credentials used for connecting to the database.
"""
mutable struct dpiConnCreateParams
    auth_mode::dpiAuthMode
    connection_class::Ptr{UInt8}
    connection_class_length::UInt32
    purity::dpiPurity
    new_password::Ptr{UInt8}
    new_password_length::UInt32
    app_context::Ptr{dpiAppContext} # Specifies the application context that will be set when the connection is created. This value is only used when creating standalone connections. It is expected to be NULL or an array of dpiAppContext structures. The context specified here can be used in logon triggers, for example. The default value is NULL.
    num_app_context::UInt32 # Specifies the number of elements found in the dpiConnCreateParams.appContext member. The default value is 0.
    external_auth::Int32 # Specifies whether external authentication should be used to create the connection. If this value is 0, the user name and password values must be specified in the call to dpiConn_create(); otherwise, the user name and password values must be zero length or NULL. The default value is 0.
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

"""
This structure is used for creating session pools,
which can in turn be used to create connections that
are acquired from that session pool.

All members are initialized to default values using
the dpiContext_initPoolCreateParams() function.
"""
struct dpiPoolCreateParams
    min_sessions::UInt32 # Specifies the minimum number of sessions to be created by the session pool. This value is ignored if the dpiPoolCreateParams.homogeneous member has a value of 0. The default value is 1.
    max_sessions::UInt32 # Specifies the maximum number of sessions that can be created by the session pool. Values of 1 and higher are acceptable. The default value is 1.
    session_increment::UInt32 # Specifies the number of sessions that will be created by the session pool when more sessions are required and the number of sessions is less than the maximum allowed. This value is ignored if the dpiPoolCreateParams.homogeneous member has a value of 0. This value added to the dpiPoolCreateParams.minSessions member value must not exceed the dpiPoolCreateParams.maxSessions member value. The default value is 0.
    ping_interval::Int32 # Specifies the number of seconds since a connection has last been used before a ping will be performed to verify that the connection is still valid. A negative value disables this check. The default value is 60.
    ping_timeout::Int32 # Specifies the number of milliseconds to wait when performing a ping to verify the connection is still valid before the connection is considered invalid and is dropped. The default value is 5000 (5 seconds). This value is ignored in clients 12.2 and later since a much faster internal check is done by the Oracle client.
    homogeneous::Int32 # Specifies whether the pool is homogeneous or not. In a homogeneous pool all connections use the same credentials whereas in a heterogeneous pool other credentials are permitted. The default value is 1.
    external_auth::Int32 # Specifies whether external authentication should be used to create the sessions in the pool. If this value is 0, the user name and password values must be specified in the call to dpiPool_create(); otherwise, the user name and password values must be zero length or NULL. The default value is 0. External authentication cannot be used with homogeneous pools.
    get_mode::dpiPoolGetMode # Specifies the mode to use when sessions are acquired from the pool. It is expected to be one of the values from the enumeration dpiPoolGetMode. The default value is DPI_MODE_POOL_GET_NOWAIT. This value can be set after the pool has been created using the function dpiPool_setGetMode() and acquired using the function dpiPool_getGetMode().
    out_pool_name::Ptr{UInt8} # This member is populated upon successful creation of a pool using the function dpiPool_create(). It is a byte string in the encoding used for CHAR data. Any value specified prior to creating the session pool is ignored.
    out_pool_name_length::UInt32 # This member is populated upon successful creation of a pool using the function dpiPool_create(). It is the length of the dpiPoolCreateParams.outPoolName member, in bytes. Any value specified prior to creating the session pool is ignored.
    timeout::UInt32 # Specifies the length of time (in seconds) after which idle sessions in the pool are terminated. Note that termination only occurs when the pool is accessed. The default value is 0 which means that no idle sessions are terminated. This value can be set after the pool has been created using the function dpiPool_setTimeout() and acquired using the function dpiPool_getTimeout().
    wait_timeout::UInt32 # Specifies the length of time (in milliseconds) that the caller should wait for a session to become available in the pool before returning with an error. This value is only used if the dpiPoolCreateParams.getMode member is set to the value DPI_MODE_POOL_GET_TIMEDWAIT. The default value is 0. This value can be set after the pool has been created using the function dpiPool_setWaitTimeout() and acquired using the function dpiPool_getWaitTimeout().
    max_lifetime_session::UInt32 # Specifies the maximum length of time (in seconds) a pooled session may exist. Sessions in use will not be closed. They become candidates for termination only when they are released back to the pool and have existed for longer than maxLifetimeSession seconds. Session termination only occurs when the pool is accessed. The default value is 0 which means that there is no maximum length of time that a pooled session may exist. This value can be set after the pool has been created using the function dpiPool_setMaxLifetimeSession() and acquired using the function dpiPool_getMaxLifetimeSession().
end

struct dpiDataTypeInfo
    oracle_type_num::dpiOracleTypeNum # Specifies the type of the data. It will be one of the values from the enumeration dpiOracleTypeNum, or 0 if the type is not supported by ODPI-C.
    default_native_type_num::dpiNativeTypeNum # Specifies the default native type for the data. It will be one of the values from the enumeration dpiNativeTypeNum, or 0 if the type is not supported by ODPI-C.
    oci_type_code::UInt16 # Specifies the OCI type code for the data, which can be useful if the type is not supported by ODPI-C.
    db_size_in_bytes::UInt32 # Specifies the size in bytes (from the database’s perspective) of the data. This value is only populated for strings and binary data. For all other data the value is zero.
    client_size_in_bytes::UInt32 # Specifies the size in bytes (from the client’s perspective) of the data. This value is only populated for strings and binary data. For all other data the value is zero.
    size_in_chars::UInt32 # Specifies the size in characters of the data. This value is only populated for string data. For all other data the value is zero.
    precision::Int16 # Specifies the precision of the data. This value is only populated for numeric and interval data. For all other data the value is zero.
    scale::Int8 # Specifies the scale of the data. This value is only populated for numeric data. For all other data the value is zero.
    fs_precision::Int16 # Specifies the fractional seconds precision of the data. This value is only populated for timestamp and interval day to second data. For all other data the value is zero.
    object_type_handle::Ptr{Cvoid} # Specifies a reference to the type of the object. This value is only populated for named type data. For all other data the value is NULL. This reference is owned by the object attribute, object type or statement and a call to dpiObjectType_addRef() must be made if the reference is going to be used beyond the lifetime of the owning object.
end

struct dpiQueryInfo
    name::Ptr{UInt8} # Specifies the name of the column which is being queried, as a byte string in the encoding used for CHAR data.
    name_length::UInt32 # Specifies the length of the dpiQueryInfo.name member, in bytes.
    type_info::dpiDataTypeInfo # Specifies the type of data of the column that is being queried. It is a structure of type dpiDataTypeInfo.
    null_ok::Int32 # Specifies if the data that is being queried may return null values (1) or not (0).
end

struct dpiStmtInfo
    is_query::Int32
    is_PLSQL::Int32
    is_DDL::Int32
    is_DML::Int32
    statement_type::dpiStatementType
    is_returning::Int32
end

mutable struct Context
    handle::Ptr{Cvoid}

    function Context(handle::Ptr{Cvoid})
        new_context = new(handle)
        finalizer(destroy!, new_context)
        return new_context
    end
end

function destroy!(ctx::Context)
    if ctx.handle != C_NULL
        dpiContext_destroy(ctx.handle)
        ctx.handle = C_NULL
    end
    nothing
end

"""
Connection handles are used to represent connections to the database. These can be standalone connections created by calling the function dpiConn_create() or acquired from a session pool by calling the function dpiPool_acquireConnection(). They can be closed by calling the function dpiConn_close() or releasing the last reference to the connection by calling the function dpiConn_release(). Connection handles are used to create all handles other than session pools and context handles.
"""
mutable struct Connection
    context::Context
    handle::Ptr{Cvoid}

    function Connection(context::Context, handle::Ptr{Cvoid})
        new_connection = new(context, handle)
        finalizer(destroy!, new_connection)
        return new_connection
    end
end

function destroy!(conn::Connection)
    if conn.handle != C_NULL
        dpi_result = dpiConn_release(conn.handle)
        error_check(conn.context, dpi_result)
        conn.handle = C_NULL
    end
    nothing
end

mutable struct Pool
    context::Context
    handle::Ptr{Cvoid}

    function Pool(context::Context, handle::Ptr{Cvoid})
        new_pool = new(context, handle)
        finalizer(destroy!, new_pool)
        return new_pool
    end
end

function destroy!(pool::Pool)
    if pool.handle != C_NULL
        dpi_result = dpiPool_release(pool.handle)
        error_check(pool.context, dpi_result)
        pool.handle = C_NULL
    end
    nothing
end

mutable struct Stmt
    connection::Connection
    handle::Ptr{Cvoid}

    function Stmt(connection::Connection, handle::Ptr{Cvoid})
        new_stmt = new(connection, handle)
        finalizer(destroy!, new_stmt)
        return new_stmt
    end
end

function destroy!(stmt::Stmt)
    if stmt.handle != C_NULL
        dpi_result = dpiStmt_release(stmt.handle)
        error_check(stmt.connection.context, dpi_result)
        stmt.handle = C_NULL
    end
    nothing
end

"""
High-level type as an aggregation of `dpiNativeTypeNum` and `dpiData`.
"""
struct DataValue
    native_type::dpiNativeTypeNum
    dpi_data_handle::Ptr{dpiData}
end
