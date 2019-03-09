
#
# functions added by deps/dpi_patch.c
#

#size_t sizeof_dpiDataBuffer()
function sizeof_dpiDataBuffer()
    ccall((:sizeof_dpiDataBuffer, libdpi), Csize_t, ())
end

# size_t sizeof_dpiData()
function sizeof_dpiData()
    ccall((:sizeof_dpiData, libdpi), Csize_t, ())
end

# size_t sizeof_dpiPoolCreateParams()
function sizeof_dpiPoolCreateParams()
    ccall((:sizeof_dpiPoolCreateParams, libdpi), Csize_t, ())
end

# size_t sizeof_dpiConnCreateParams()
function sizeof_dpiConnCreateParams()
    ccall((:sizeof_dpiConnCreateParams, libdpi), Csize_t, ())
end

# size_t sizeof_dpiQueryInfo()
function sizeof_dpiQueryInfo()
    ccall((:sizeof_dpiQueryInfo, libdpi), Csize_t, ())
end

# dpiOracleTypeNum dpiLob_getOracleType(dpiLob *lob)
function dpiLob_getOracleTypeNum(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_getOracleTypeNum, libdpi), OraOracleTypeNum, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_isCharacterData(dpiLob *lob)
function dpiLob_isCharacterData(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_isCharacterData, libdpi), Int32, (Ptr{Cvoid},), lob_handle)
end

# size_t sizeof_dpiNumber()
function sizeof_dpiNumber()
    ccall((:sizeof_dpiNumber, libdpi), Csize_t, ())
end

#
# ODPI Context Functions
#

# int dpiContext_create(unsigned int majorVersion, unsigned int minorVersion, dpiContext **context, dpiErrorInfo *errorInfo)
function dpiContext_create(major_version::UInt32, minor_version::UInt32, dpi_context_ref::Ref{Ptr{Cvoid}}, error_info::Ref{OraErrorInfo})
    ccall((:dpiContext_create, libdpi), OraResult, (Cuint, Cuint, Ref{Ptr{Cvoid}}, Ref{OraErrorInfo}), major_version, minor_version, dpi_context_ref, error_info)
end

# int dpiContext_destroy(dpiContext *context)
function dpiContext_destroy(dpi_context_handle::Ptr{Cvoid})
    ccall((:dpiContext_destroy, libdpi), OraResult, (Ptr{Cvoid},), dpi_context_handle)
end

# void dpiContext_getClientVersion(const dpiContext *context, dpiVersionInfo *versionInfo)
function dpiContext_getClientVersion(dpi_context_handle::Ptr{Cvoid}, version_info_ref::Ref{OraVersionInfo})
    ccall((:dpiContext_getClientVersion, libdpi), Cvoid, (Ptr{Cvoid}, Ref{OraVersionInfo}), dpi_context_handle, version_info_ref)
end

# int dpiContext_initCommonCreateParams(const dpiContext *context, dpiContextParams *params)
function dpiContext_initCommonCreateParams(dpi_context_handle::Ptr{Cvoid}, common_create_params_ref::Ref{OraCommonCreateParams})
    ccall((:dpiContext_initCommonCreateParams, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraCommonCreateParams}), dpi_context_handle, common_create_params_ref)
end

# int dpiContext_initPoolCreateParams(const dpiContext *context, dpiPoolCreateParams *params)
function dpiContext_initPoolCreateParams(context_handle::Ptr{Cvoid}, pool_create_params_ref::Ref{OraPoolCreateParams})
    ccall((:dpiContext_initPoolCreateParams, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraPoolCreateParams}), context_handle, pool_create_params_ref)
end

# void dpiContext_getError(const dpiContext *context, dpiErrorInfo *errorInfo)¶
function dpiContext_getError(context_handle::Ptr{Cvoid}, error_info_ref::Ref{OraErrorInfo})
    ccall((:dpiContext_getError, libdpi), Cvoid, (Ptr{Cvoid}, Ref{OraErrorInfo}), context_handle, error_info_ref)
end

# int dpiContext_initConnCreateParams(const dpiContext *context, dpiConnCreateParams *params)
function dpiContext_initConnCreateParams(context_handle::Ptr{Cvoid}, conn_create_params_ref::Ref{OraConnCreateParams})
    ccall((:dpiContext_initConnCreateParams, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraConnCreateParams}), context_handle, conn_create_params_ref)
end

#
# ODPI Connection Functions
#

# int dpiConn_release(dpiConn *conn)
function dpiConn_release(connection_handle::Ptr{Cvoid})
    ccall((:dpiConn_release, libdpi), OraResult, (Ptr{Cvoid},), connection_handle)
end

# int dpiConn_create(const dpiContext *context, const char *userName, uint32_t userNameLength, const char *password, uint32_t passwordLength, const char *connectString, uint32_t connectStringLength, dpiCommonCreateParams *commonParams, dpiConnCreateParams *createParams, dpiConn **conn)
function dpiConn_create(context_handle::Ptr{Cvoid}, user::String, password::String, connect_string::String, common_params_ref::Ref{OraCommonCreateParams}, conn_create_params_ref::Ref{OraConnCreateParams}, dpi_conn_handle_ref::Ref{Ptr{Cvoid}})
    userNameLength = sizeof(user)
    passwordLength = sizeof(password)
    connectStringLength = sizeof(connect_string)

    ccall((:dpiConn_create, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{OraCommonCreateParams}, Ref{OraConnCreateParams}, Ref{Ptr{Cvoid}}), context_handle, user, userNameLength, password, passwordLength, connect_string, connectStringLength, common_params_ref, conn_create_params_ref, dpi_conn_handle_ref)
end

# int dpiConn_getServerVersion(dpiConn *conn, const char **releaseString, uint32_t *releaseStringLength, dpiVersionInfo *versionInfo)
function dpiConn_getServerVersion(connection_handle::Ptr{Cvoid}, release_string_ptr_ref::Ref{Ptr{UInt8}}, release_string_length_ref::Ref{UInt32}, version_info_ref::Ref{OraVersionInfo})
    ccall((:dpiConn_getServerVersion, libdpi), OraResult, (Ptr{Cvoid}, Ref{Ptr{UInt8}}, Ref{UInt32}, Ref{OraVersionInfo}), connection_handle, release_string_ptr_ref, release_string_length_ref, version_info_ref)
end

#int dpiConn_ping(dpiConn *conn)
function dpiConn_ping(connection_handle::Ptr{Cvoid})
    ccall((:dpiConn_ping, libdpi), OraResult, (Ptr{Cvoid},), connection_handle)
end

# int dpiConn_startupDatabase(dpiConn *conn, dpiStartupMode mode)
function dpiConn_startupDatabase(connection_handle::Ptr{Cvoid}, startup_mode::OraStartupMode)
    ccall((:dpiConn_startupDatabase, libdpi), OraResult, (Ptr{Cvoid}, OraStartupMode), connection_handle, startup_mode)
end

# int dpiConn_shutdownDatabase(dpiConn *conn, dpiShutdownMode mode)
function dpiConn_shutdownDatabase(connection_handle::Ptr{Cvoid}, shutdown_mode::OraShutdownMode)
    ccall((:dpiConn_shutdownDatabase, libdpi), OraResult, (Ptr{Cvoid}, OraShutdownMode), connection_handle, shutdown_mode)
end

# int dpiConn_prepareStmt(dpiConn *conn, int scrollable, const char *sql, uint32_t sqlLength, const char *tag, uint32_t tagLength, dpiStmt **stmt)
function dpiConn_prepareStmt(connection_handle::Ptr{Cvoid}, scrollable::Bool, sql::String, tag::String, stmt_handle_ref::Ref{Ptr{Cvoid}})
    sqlLength = sizeof(sql)

    if tag == ""
        return ccall((:dpiConn_prepareStmt, libdpi), OraResult, (Ptr{Cvoid}, Cint, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{Ptr{Cvoid}}), connection_handle, scrollable, sql, sqlLength, C_NULL, 0, stmt_handle_ref)
    else
        tagLength = sizeof(tag)
        return ccall((:dpiConn_prepareStmt, libdpi), OraResult, (Ptr{Cvoid}, Cint, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{Ptr{Cvoid}}), connection_handle, scrollable, sql, sqlLength, tag, tagLength, stmt_handle_ref)
    end
end

# int dpiConn_close(dpiConn *conn, dpiConnCloseMode mode, const char *tag, uint32_t tagLength)
function dpiConn_close(connection_handle::Ptr{Cvoid}; close_mode::OraConnCloseMode=ORA_MODE_CONN_CLOSE_DEFAULT, tag::String="")
    if tag == ""
        return ccall((:dpiConn_close, libdpi), OraResult, (Ptr{Cvoid}, OraConnCloseMode, Ptr{UInt8}, UInt32), connection_handle, close_mode, C_NULL, 0)
    else
        tagLength = sizeof(tag)
        return ccall((:dpiConn_close, libdpi), OraResult, (Ptr{Cvoid}, OraConnCloseMode, Ptr{UInt8}, UInt32), connection_handle, close_mode, tag, tagLength)
    end
end

# int dpiConn_commit(dpiConn *conn)
function dpiConn_commit(connection_handle::Ptr{Cvoid})
    ccall((:dpiConn_commit, libdpi), OraResult, (Ptr{Cvoid},), connection_handle)
end

# int dpiConn_rollback(dpiConn *conn)
function dpiConn_rollback(connection_handle::Ptr{Cvoid})
    ccall((:dpiConn_rollback, libdpi), OraResult, (Ptr{Cvoid},), connection_handle)
end

# int dpiConn_getEncodingInfo(dpiConn *conn, dpiEncodingInfo *info)
function dpiConn_getEncodingInfo(connection_handle::Ptr{Cvoid}, encoding_info_ref::Ref{OraEncodingInfo})
    ccall((:dpiConn_getEncodingInfo, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraEncodingInfo}), connection_handle, encoding_info_ref)
end

# int dpiConn_getCurrentSchema(dpiConn *conn, const char **value, uint32_t *valueLength)
function dpiConn_getCurrentSchema(connection_handle::Ptr{Cvoid}, value_char_array_ref::Ref{Ptr{UInt8}}, value_length_ref::Ref{UInt32})
    ccall((:dpiConn_getCurrentSchema, libdpi), OraResult, (Ptr{Cvoid}, Ref{Ptr{UInt8}}, Ref{UInt32}), connection_handle, value_char_array_ref, value_length_ref)
end

# int dpiConn_newVar(dpiConn *conn, dpiOracleTypeNum oracleTypeNum, dpiNativeTypeNum nativeTypeNum, uint32_t maxArraySize, uint32_t size, int sizeIsBytes, int isArray, dpiObjectType *objType, dpiVar **var, dpiData **data)
function dpiConn_newVar(connection_handle::Ptr{Cvoid}, oracle_type::OraOracleTypeNum, native_type::OraNativeTypeNum, max_array_size::UInt32, size::UInt32, size_is_bytes::Int32, is_array::Int32, obj_type_handle::Ptr{Cvoid}, var_handle_ref::Ref{Ptr{Cvoid}}, dpi_data_array_ref::Ref{Ptr{OraData}})
    ccall((:dpiConn_newVar, libdpi), OraResult, (Ptr{Cvoid}, OraOracleTypeNum, OraNativeTypeNum, UInt32, UInt32, Int32, Int32, Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Ref{Ptr{OraData}}), connection_handle, oracle_type, native_type, max_array_size, size, size_is_bytes, is_array, obj_type_handle, var_handle_ref, dpi_data_array_ref)
end

# int dpiConn_getStmtCacheSize(dpiConn *conn, uint32_t *cacheSize)
function dpiConn_getStmtCacheSize(connection_handle::Ptr{Cvoid}, cache_size_ref::Ref{UInt32})
    ccall((:dpiConn_getStmtCacheSize, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}), connection_handle, cache_size_ref)
end

# int dpiConn_setStmtCacheSize(dpiConn *conn, uint32_t cacheSize)
function dpiConn_setStmtCacheSize(connection_handle::Ptr{Cvoid}, cache_size::UInt32)
    ccall((:dpiConn_setStmtCacheSize, libdpi), OraResult, (Ptr{Cvoid}, UInt32), connection_handle, cache_size)
end

# int dpiConn_newTempLob(dpiConn *conn, dpiOracleTypeNum lobType, dpiLob **lob)
function dpiConn_newTempLob(connection_handle::Ptr{Cvoid}, lob_type::OraOracleTypeNum, lob_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:dpiConn_newTempLob, libdpi), OraResult, (Ptr{Cvoid}, OraOracleTypeNum, Ref{Ptr{Cvoid}}), connection_handle, lob_type, lob_handle_ref)
end

#
# ODPI Pool Functions
#

# int dpiPool_create(const dpiContext *context, const char *userName, uint32_t userNameLength, const char *password, uint32_t passwordLength, const char *connectString, uint32_t connectStringLength, dpiCommonCreateParams *commonParams, dpiPoolCreateParams *createParams, dpiPool **pool)
function dpiPool_create(context_handle::Ptr{Cvoid}, user::String, password::String, connect_string::String, common_params_ref::Ref{OraCommonCreateParams}, pool_create_params_ref::Ref{OraPoolCreateParams}, pool_handle_ref::Ref{Ptr{Cvoid}})
    userNameLength = sizeof(user)
    passwordLength = sizeof(password)
    connectStringLength = sizeof(connect_string)

    ccall((:dpiPool_create, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{OraCommonCreateParams}, Ref{OraPoolCreateParams}, Ref{Ptr{Cvoid}}), context_handle, user, userNameLength, password, passwordLength, connect_string, connectStringLength, common_params_ref, pool_create_params_ref, pool_handle_ref)
end

# int dpiPool_release(dpiPool *pool)
function dpiPool_release(dpi_pool_handle::Ptr{Cvoid})
    ccall((:dpiPool_release, libdpi), OraResult, (Ptr{Cvoid},), dpi_pool_handle)
end

# int dpiPool_close(dpiPool *pool, dpiPoolCloseMode closeMode)
function dpiPool_close(pool_handle::Ptr{Cvoid}, close_mode::OraPoolCloseMode)
    ccall((:dpiPool_close, libdpi), OraResult, (Ptr{Cvoid}, OraPoolCloseMode), pool_handle, close_mode)
end

# int dpiPool_getGetMode(dpiPool *pool, dpiPoolGetMode *value)
function dpiPool_getGetMode(pool_handle::Ptr{Cvoid}, pool_get_mode_ref::Ref{OraPoolGetMode})
    ccall((:dpiPool_getGetMode, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraPoolGetMode}), pool_handle, pool_get_mode_ref)
end

# int dpiPool_acquireConnection(dpiPool *pool, const char *userName, uint32_t userNameLength, const char *password, uint32_t passwordLength, dpiConnCreateParams *params, dpiConn **conn)
function dpiPool_acquireConnection(pool_handle::Ptr{Cvoid}, user::String, password::String, conn_create_params_ref::Ref{OraConnCreateParams}, connection_handle_ref::Ref{Ptr{Cvoid}})
    userNameLength = sizeof(user)
    passwordLength = sizeof(password)
    ccall((:dpiPool_acquireConnection, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{OraConnCreateParams}, Ref{Ptr{Cvoid}}), pool_handle, user, userNameLength, password, passwordLength, conn_create_params_ref, connection_handle_ref)
end

function dpiPool_acquireConnection(pool_handle::Ptr{Cvoid}, conn_create_params_ref::Ref{OraConnCreateParams}, connection_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:dpiPool_acquireConnection, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, Ptr{UInt8}, UInt32, Ref{OraConnCreateParams}, Ref{Ptr{Cvoid}}), pool_handle, C_NULL, 0, C_NULL, 0, conn_create_params_ref, connection_handle_ref)
end

#
# ODPI Statement Functions
#

# int dpiStmt_release(dpiStmt *stmt)
function dpiStmt_release(stmt_handle::Ptr{Cvoid})
    ccall((:dpiStmt_release, libdpi), OraResult, (Ptr{Cvoid},), stmt_handle)
end

# int dpiStmt_close(dpiStmt *stmt, const char *tag, uint32_t tagLength)
function dpiStmt_close(stmt_handle::Ptr{Cvoid}; tag::String="")
    if tag == ""
        return ccall((:dpiStmt_close, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32), stmt_handle, C_NULL, 0)
    else
        tagLength = sizeof(tag)
        return ccall((:dpiStmt_close, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32), stmt_handle, tag, tagLength)
    end
end

# int dpiStmt_execute(dpiStmt *stmt, dpiExecMode mode, uint32_t *numQueryColumns)
function dpiStmt_execute(stmt_handle::Ptr{Cvoid}, exec_mode::OraExecMode, num_query_columns_ref::Ref{UInt32})
    ccall((:dpiStmt_execute, libdpi), OraResult, (Ptr{Cvoid}, OraExecMode, Ref{UInt32}), stmt_handle, exec_mode, num_query_columns_ref)
end

# int dpiStmt_executeMany(dpiStmt *stmt, dpiExecMode mode, uint32_t numIters)
function dpiStmt_executeMany(stmt_handle::Ptr{Cvoid}, exec_mode::OraExecMode, num_iters::UInt32)
    ccall((:dpiStmt_executeMany, libdpi), OraResult, (Ptr{Cvoid}, OraExecMode, UInt32), stmt_handle, exec_mode, num_iters)
end

# exec_mode may be "ored" together
function dpiStmt_executeMany(stmt_handle::Ptr{Cvoid}, exec_mode::UInt32, num_iters::UInt32)
    ccall((:dpiStmt_executeMany, libdpi), OraResult, (Ptr{Cvoid}, UInt32, UInt32), stmt_handle, exec_mode, num_iters)
end

# int dpiStmt_getRowCounts(dpiStmt *stmt, uint32_t *numRowCounts, uint64_t **rowCounts)
function dpiStmt_getRowCounts(stmt_handle::Ptr{Cvoid}, row_counts_length_ref::Ref{UInt32}, row_counts_array_ref::Ref{Ptr{UInt64}})
    ccall((:dpiStmt_getRowCounts, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}, Ref{Ptr{UInt64}}), stmt_handle, row_counts_length_ref, row_counts_array_ref)
end

# int dpiStmt_getNumQueryColumns(dpiStmt *stmt, uint32_t *numQueryColumns)
function dpiStmt_getNumQueryColumns(stmt_handle::Ptr{Cvoid}, num_query_columns_ref::Ref{UInt32})
    ccall((:dpiStmt_getNumQueryColumns, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}), stmt_handle, num_query_columns_ref)
end

# int dpiStmt_getQueryInfo(dpiStmt *stmt, uint32_t pos, dpiQueryInfo *info)
function dpiStmt_getQueryInfo(stmt_handle::Ptr{Cvoid}, pos::UInt32, query_info_ref::Ref{OraQueryInfo})
    ccall((:dpiStmt_getQueryInfo, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ref{OraQueryInfo}), stmt_handle, pos, query_info_ref)
end

# int dpiStmt_getInfo(dpiStmt *stmt, dpiStmtInfo *info)
function dpiStmt_getInfo(stmt_handle::Ptr{Cvoid}, stmt_info_ref::Ref{OraStmtInfo})
    ccall((:dpiStmt_getInfo, libdpi), OraResult, (Ptr{Cvoid}, Ref{OraStmtInfo}), stmt_handle, stmt_info_ref)
end

# int dpiStmt_getFetchArraySize(dpiStmt *stmt, uint32_t *arraySize)
function dpiStmt_getFetchArraySize(stmt_handle::Ptr{Cvoid}, array_size_ref::Ref{UInt32})
    ccall((:dpiStmt_getFetchArraySize, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}), stmt_handle, array_size_ref)
end

# int dpiStmt_setFetchArraySize(dpiStmt *stmt, uint32_t arraySize)
function dpiStmt_setFetchArraySize(stmt_handle::Ptr{Cvoid}, array_size::UInt32)
    ccall((:dpiStmt_setFetchArraySize, libdpi), OraResult, (Ptr{Cvoid}, UInt32), stmt_handle, array_size)
end

# int dpiStmt_fetch(dpiStmt *stmt, int *found, uint32_t *bufferRowIndex)
function dpiStmt_fetch(stmt_handle::Ptr{Cvoid}, found_ref::Ref{Int32}, buffer_row_index_ref::Ref{UInt32})
    ccall((:dpiStmt_fetch, libdpi), OraResult, (Ptr{Cvoid}, Ref{Int32}, Ref{UInt32}), stmt_handle, found_ref, buffer_row_index_ref)
end

# int dpiStmt_fetchRows(dpiStmt *stmt, uint32_t maxRows, uint32_t *bufferRowIndex, uint32_t *numRowsFetched, int *moreRows)
function dpiStmt_fetchRows(stmt_handle::Ptr{Cvoid}, max_rows::UInt32, buffer_row_index_ref::Ref{UInt32}, num_rows_fetched_ref::Ref{UInt32}, more_rows_ref::Ref{Int32})
    ccall((:dpiStmt_fetchRows, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ref{UInt32}, Ref{UInt32}, Ref{Int32}), stmt_handle, max_rows, buffer_row_index_ref, num_rows_fetched_ref, more_rows_ref)
end

# int dpiStmt_getQueryValue(dpiStmt *stmt, uint32_t pos, dpiNativeTypeNum *nativeTypeNum, dpiData **data)
function dpiStmt_getQueryValue(stmt_handle::Ptr{Cvoid}, pos::UInt32, native_type_num_ref::Ref{OraNativeTypeNum}, data_handle_ref::Ref{Ptr{OraData}})
    ccall((:dpiStmt_getQueryValue, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ref{OraNativeTypeNum}, Ref{Ptr{OraData}}), stmt_handle, pos, native_type_num_ref, data_handle_ref)
end

# int dpiStmt_bindValueByName(dpiStmt *stmt, const char *name, uint32_t nameLength, dpiNativeTypeNum nativeTypeNum, dpiData *data)
function dpiStmt_bindValueByName(stmt_handle::Ptr{Cvoid}, name::String, native_type::OraNativeTypeNum, dpi_data_ref::Ref{OraData})
    nameLength = sizeof(name)
    ccall((:dpiStmt_bindValueByName, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, OraNativeTypeNum, Ref{OraData}), stmt_handle, name, nameLength, native_type, dpi_data_ref)
end

# int dpiStmt_bindValueByPos(dpiStmt *stmt, uint32_t pos, dpiNativeTypeNum nativeTypeNum, dpiData *data)
function dpiStmt_bindValueByPos(stmt_handle::Ptr{Cvoid}, pos::UInt32, native_type::OraNativeTypeNum, dpi_data_ref::Ref{OraData})
    ccall((:dpiStmt_bindValueByPos, libdpi), OraResult, (Ptr{Cvoid}, UInt32, OraNativeTypeNum, Ref{OraData}), stmt_handle, pos, native_type, dpi_data_ref)
end

# int dpiStmt_getRowCount(dpiStmt *stmt, uint64_t *count)
function dpiStmt_getRowCount(stmt_handle::Ptr{Cvoid}, count_ref::Ref{UInt64})
    ccall((:dpiStmt_getRowCount, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt64}), stmt_handle, count_ref)
end

# int dpiStmt_getBindCount(dpiStmt *stmt, uint32_t *count)
function dpiStmt_getBindCount(stmt_handle::Ptr{Cvoid}, count_ref::Ref{UInt32})
    ccall((:dpiStmt_getBindCount, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}), stmt_handle, count_ref)
end

# int dpiStmt_getBindNames(dpiStmt *stmt, uint32_t *numBindNames, const char **bindNames, uint32_t *bindNameLengths)
function dpiStmt_getBindNames(stmt_handle::Ptr{Cvoid}, num_bind_names_ref::Ref{UInt32}, bind_names_vec_ptr::Ptr{Ptr{UInt8}}, bind_name_lengths_vector::Ptr{UInt32})
    ccall((:dpiStmt_getBindNames, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}, Ref{Ptr{UInt8}}, Ptr{UInt32}), stmt_handle, num_bind_names_ref, bind_names_vec_ptr, bind_name_lengths_vector)
end

# int dpiStmt_define(dpiStmt *stmt, uint32_t pos, dpiVar *var)
function dpiStmt_define(stmt_handle::Ptr{Cvoid}, pos::UInt32, variable_handle::Ptr{Cvoid})
    ccall((:dpiStmt_define, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), stmt_handle, pos, variable_handle)
end

# int dpiStmt_bindByName(dpiStmt *stmt, const char *name, uint32_t nameLength, dpiVar *var)
function dpiStmt_bindByName(stmt_handle::Ptr{Cvoid}, name::String, variable_handle::Ptr{Cvoid})
    nameLength = sizeof(name)
    ccall((:dpiStmt_bindByName, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt32, Ptr{Cvoid}), stmt_handle, name, nameLength, variable_handle)
end

# int dpiStmt_bindByPos(dpiStmt *stmt, uint32_t pos, dpiVar *var)
function dpiStmt_bindByPos(stmt_handle::Ptr{Cvoid}, pos::UInt32, variable_handle::Ptr{Cvoid})
    ccall((:dpiStmt_bindByPos, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), stmt_handle, pos, variable_handle)
end

#
# ODPI Data Functions
#

# int dpiData_getBool(dpiData *data)
function dpiData_getBool(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getBool, libdpi), Cint, (Ref{OraData},), dpi_data_handle)
end

# double dpiData_getDouble(dpiData *data)
function dpiData_getDouble(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getDouble, libdpi), Cdouble, (Ref{OraData},), dpi_data_handle)
end

# float dpiData_getFloat(dpiData *data)
function dpiData_getFloat(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getFloat, libdpi), Float32, (Ref{OraData},), dpi_data_handle)
end

# int64_t dpiData_getInt64(dpiData *data)
function dpiData_getInt64(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getInt64, libdpi), Int64, (Ref{OraData},), dpi_data_handle)
end

# uint64_t dpiData_getUint64(dpiData *data)
function dpiData_getUint64(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getUint64, libdpi), UInt64, (Ref{OraData},), dpi_data_handle)
end

# dpiBytes *dpiData_getBytes(dpiData *data)
function dpiData_getBytes(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getBytes, libdpi), Ptr{OraBytes}, (Ref{OraData},), dpi_data_handle)
end

# dpiTimestamp *dpiData_getTimestamp(dpiData *data)
function dpiData_getTimestamp(dpi_data_handle::Ref{OraData})
    ccall((:dpiData_getTimestamp, libdpi), Ptr{OraTimestamp}, (Ref{OraData},), dpi_data_handle)
end

# int dpiData_getIsNull(dpiData *data)
function dpiData_getIsNull(data_handle::Ref{OraData})
    ccall((:dpiData_getIsNull, libdpi), Cint, (Ref{OraData},), data_handle)
end

# dpiLob *dpiData_getLOB(dpiData *data)
function dpiData_getLOB(data_handle::Ref{OraData})
    ccall((:dpiData_getLOB, libdpi), Ptr{Cvoid}, (Ref{OraData},), data_handle)
end

# dpiNumber dpiData_getNumber(dpiData *data);
function dpiData_getNumber(data_handle::Ref{OraData})
    ccall((:dpiData_getNumber, libdpi), OraNumber, (Ref{OraData},), data_handle)
end

#
# NOTE ON SET FUNCTIONS
#
# Ref{OraData} <: Ptr{OraData}
#

# void dpiData_setBytes(dpiData *data, char *ptr, uint32_t length)
# cannot be used for setting strings to variables
function dpiData_setBytes(dpi_data_ptr::Ref{OraData}, str::String)
    ccall((:dpiData_setBytes, libdpi), Cvoid, (Ref{OraData}, Ptr{UInt8}, UInt32), dpi_data_ptr, str, sizeof(str))
end

function dpiData_setBytes(dpi_data_ptr::Ref{OraData}, bytes::Vector{UInt8})
    ccall((:dpiData_setBytes, libdpi), Cvoid, (Ref{OraData}, Ptr{UInt8}, UInt32), dpi_data_ptr, bytes, length(bytes))
end

function dpiData_setBytes(dpi_data_ptr::Ref{OraData}, bytes_ptr::Ptr{UInt8}, bytes_len::UInt32)
    ccall((:dpiData_setBytes, libdpi), Cvoid, (Ref{OraData}, Ptr{UInt8}, UInt32), dpi_data_ptr, bytes_ptr, bytes_len)
end

# void dpiData_setDouble(dpiData *data, double value)
function dpiData_setDouble(dpi_data_ptr::Ref{OraData}, value::Float64)
    ccall((:dpiData_setDouble, libdpi), Cvoid, (Ref{OraData}, Cdouble), dpi_data_ptr, value)
end

# void dpiData_setInt64(dpiData *data, int64_t value)
function dpiData_setInt64(dpi_data_ptr::Ref{OraData}, value::Int64)
    ccall((:dpiData_setInt64, libdpi), Cvoid, (Ref{OraData}, Int64), dpi_data_ptr, value)
end

# void dpiData_setUint64(dpiData *data, uint64_t value)
function dpiData_setUint64(dpi_data_ptr::Ref{OraData}, value::UInt64)
    ccall((:dpiData_setUint64, libdpi), Cvoid, (Ref{OraData}, UInt64), dpi_data_ptr, value)
end

# void dpiData_setTimestamp(dpiData *data, int16_t year, uint8_t month, uint8_t day, uint8_t hour, uint8_t minute, uint8_t second, uint32_t fsecond, int8_t tzHourOffset, int8_t tzMinuteOffset)
function dpiData_setTimestamp(dpi_data_ptr::Ref{OraData}, ts::OraTimestamp)
    ccall((:dpiData_setTimestamp, libdpi), Cvoid, (Ref{OraData}, Int16, UInt8, UInt8, UInt8, UInt8, UInt8, UInt32, Int8, Int8), dpi_data_ptr, ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second, ts.fsecond, ts.tzHourOffset, ts.tzMinuteOffset)
end

# void dpiData_setNull(dpiData *data)
function dpiData_setNull(dpi_data_ptr::Ref{OraData})
    ccall((:dpiData_setNull, libdpi), Cvoid, (Ref{OraData},), dpi_data_ptr)
end

# void dpiData_setLOB(dpiData *data, dpiLob *lob)
function dpiData_setLOB(dpi_data_ptr::Ref{OraData}, lob_handle::Ptr{Cvoid})
    ccall((:dpiData_setLOB, libdpi), Cvoid, (Ref{OraData}, Ptr{Cvoid}), dpi_data_ptr, lob_handle)
end

# void dpiData_setNumber(dpiData *data, dpiNumber number);
function dpiData_setNumber(dpi_data_ptr::Ref{OraData}, number::OraNumber)
    ccall((:dpiData_setNumber, libdpi), Cvoid, (Ref{OraData}, OraNumber), dpi_data_ptr, number)
end

#
# ODPI-C Variable Functions
#

# int dpiVar_release(dpiVar *var)
function dpiVar_release(var_handle::Ptr{Cvoid})
    ccall((:dpiVar_release, libdpi), OraResult, (Ptr{Cvoid},), var_handle)
end

# int dpiVar_setFromBytes(dpiVar *var, uint32_t pos, const char *value, uint32_t valueLength)
function dpiVar_setFromBytes(var_handle::Ptr{Cvoid}, pos::UInt32, value::String)
    valueLength = sizeof(value)
    ccall((:dpiVar_setFromBytes, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ptr{UInt8}, UInt32), var_handle, pos, value, valueLength)
end

function dpiVar_setFromBytes(var_handle::Ptr{Cvoid}, pos::UInt32, value::Vector{UInt8})
    ccall((:dpiVar_setFromBytes, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ptr{UInt8}, UInt32), var_handle, pos, value, length(value))
end

# int dpiVar_setFromLob(dpiVar *var, uint32_t pos, dpiLob *lob)
function dpiVar_setFromLob(var_handle::Ptr{Cvoid}, pos::UInt32, lob_handle::Ptr{Cvoid})
    ccall((:dpiVar_setFromLob, libdpi), OraResult, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), var_handle, pos, lob_handle)
end

#
# ODPI-C LOB Functions
#

# int dpiLob_release(dpiLob *lob)
function dpiLob_release(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_release, libdpi), OraResult, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_addRef(dpiLob *lob)
function dpiLob_addRef(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_addRef, libdpi), OraResult, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_close(dpiLob *lob)
function dpiLob_close(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_close, libdpi), OraResult, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_getChunkSize(dpiLob *lob, uint32_t *size)
function dpiLob_getChunkSize(lob_handle::Ptr{Cvoid}, chunk_size_ref::Ref{UInt32})
    ccall((:dpiLob_getChunkSize, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt32}), lob_handle, chunk_size_ref)
end

# int dpiLob_getSize(dpiLob *lob, uint64_t *size)
function dpiLob_getSize(lob_handle::Ptr{Cvoid}, lob_size_ref::Ref{UInt64})
    ccall((:dpiLob_getSize, libdpi), OraResult, (Ptr{Cvoid}, Ref{UInt64}), lob_handle, lob_size_ref)
end

# int dpiLob_readBytes(dpiLob *lob, uint64_t offset, uint64_t amount, char *value, uint64_t *valueLength)
function dpiLob_readBytes(lob_handle::Ptr{Cvoid}, offset::UInt64, amount::UInt64, buffer::Ptr{UInt8}, buffer_len_ref::Ref{UInt64})
    ccall((:dpiLob_readBytes, libdpi), OraResult, (Ptr{Cvoid}, UInt64, UInt64, Ptr{UInt8}, Ref{UInt64}), lob_handle, offset, amount, buffer, buffer_len_ref)
end

# int dpiLob_writeBytes(dpiLob *lob, uint64_t offset, const char *value, uint64_t valueLength)
function dpiLob_writeBytes(lob_handle::Ptr{Cvoid}, offset::UInt64, buffer::Ptr{UInt8}, buffer_len::UInt64)
    ccall((:dpiLob_writeBytes, libdpi), OraResult, (Ptr{Cvoid}, UInt64, Ptr{UInt8}, UInt64), lob_handle, offset, buffer, buffer_len)
end

# int dpiLob_openResource(dpiLob *lob)
function dpiLob_openResource(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_openResource, libdpi), OraResult, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_closeResource(dpiLob *lob)
function dpiLob_closeResource(lob_handle::Ptr{Cvoid})
    ccall((:dpiLob_closeResource, libdpi), OraResult, (Ptr{Cvoid},), lob_handle)
end

# int dpiLob_getIsResourceOpen(dpiLob *lob, int *isOpen)
function dpiLob_getIsResourceOpen(lob_handle::Ptr{Cvoid}, is_open_ref::Ref{Int32})
    ccall((:dpiLob_getIsResourceOpen, libdpi), OraResult, (Ptr{Cvoid}, Ref{Int32}), lob_handle, is_open_ref)
end

# int dpiLob_getBufferSize(dpiLob *lob, uint64_t sizeInChars, uint64_t *sizeInBytes)
function dpiLob_getBufferSize(lob_handle::Ptr{Cvoid}, size_in_chars::UInt64, size_in_bytes_ref::Ref{UInt64})
    ccall((:dpiLob_getBufferSize, libdpi), OraResult, (Ptr{Cvoid}, UInt64, Ref{UInt64}), lob_handle, size_in_chars, size_in_bytes_ref)
end

# int dpiLob_trim(dpiLob *lob, uint64_t newSize)
function dpiLob_trim(lob_handle::Ptr{Cvoid}, new_size::UInt64)
    ccall((:dpiLob_trim, libdpi), OraResult, (Ptr{Cvoid}, UInt64), lob_handle, new_size)
end

# int dpiLob_setFromBytes(dpiLob *lob, const char *value, uint64_t valueLength)
function dpiLob_setFromBytes(lob_handle::Ptr{Cvoid}, buffer::Ptr{UInt8}, buffer_len::UInt64)
    ccall((:dpiLob_setFromBytes, libdpi), OraResult, (Ptr{Cvoid}, Ptr{UInt8}, UInt64), lob_handle, buffer, buffer_len)
end
