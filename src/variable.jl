
"Variable is a 1-indexed array of OraData."
function Variable(
        connection::Connection,
        ::Type{T},
        oracle_type::OraOracleTypeNum,
        native_type::OraNativeTypeNum,
        ;
        buffer_capacity::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE,
        max_byte_string_size::Integer=4000, # maximum size allowed for VARCHAR2 fields
        is_PLSQL_array::Bool=false,
        object_type_handle::Ptr{Cvoid}=C_NULL) where {T}

    var_handle_ref = Ref{Ptr{Cvoid}}()
    buffer_handle_ref = Ref{Ptr{OraData}}()

    size_is_bytes = Int32(1) # always pass max_byte_string_size in bytes

    result = dpiConn_newVar(
        connection.handle,
        oracle_type,
        native_type,
        UInt32(buffer_capacity),
        UInt32(max_byte_string_size),
        size_is_bytes,
        Int32(is_PLSQL_array),
        object_type_handle,
        var_handle_ref,
        buffer_handle_ref)

    error_check(context(connection), result)

    return Variable(
        connection,
        T,
        var_handle_ref[],
        oracle_type,
        native_type,
        UInt32(max_byte_string_size),
        Int32(is_PLSQL_array),
        object_type_handle,
        buffer_handle_ref[],
        UInt32(buffer_capacity))
end

"""
    define(stmt::QueryStmt, column_position::Integer, variable::Variable)

Defines the variable that will be used to fetch rows from the statement.
`stmt` must be an executed statement.

A Variable `v` bound to a statement `stmt` must satisfy:

`v.buffer_capacity >= fetch_array_size(stmt)`
"""
function define(stmt::QueryStmt, column_position::Integer, variable::Variable)
    @assert variable.buffer_capacity >= fetch_array_size(stmt) "Variable buffer capacity ($(variable.buffer_capacity)) must be greater than statement fetch array size ($(fetch_array_size(stmt)))."
    result = dpiStmt_define(stmt.handle, UInt32(column_position), variable.handle)
    error_check(context(stmt), result)
    nothing
end

function Base.setindex!(variable::Variable, value, pos::Integer)
    check_bounds(variable, pos)
    oracle_value = ExternOracleValue(variable, variable.oracle_type, variable.native_type, variable.buffer_handle)
    oracle_value[pos] = value
    nothing
end

function Base.setindex!(variable::Variable, value::String, pos::Integer)
    check_bounds(variable, pos)
    result = dpiVar_setFromBytes(variable.handle, UInt32(pos-1), value)
    error_check(context(variable), result)
    nothing
end

function Base.setindex!(variable::Variable, value::Lob, pos::Integer)
    check_bounds(variable, pos)
    result = dpiVar_setFromLob(variable.handle, UInt32(pos-1), value.handle)
    error_check(context(variable), result)
    nothing
end

function Base.getindex(variable::Variable, pos::Integer)
    check_bounds(variable, pos)
    oracle_value = ExternOracleValue(variable, variable.oracle_type, variable.native_type, variable.buffer_handle)
    return oracle_value[pos]
end

Base.getindex(variable::Variable, pos::FetchResult) = getindex(variable, pos.buffer_row_index + 1)

@inline function check_bounds(variable::Variable, pos::Integer)
    # pos is 1-indexed
    @assert pos > 0 "Cannot bind variable at position $pos."
    @assert pos <= variable.buffer_capacity "Position $pos is greater than variable's buffer capacity $(variable.buffer_capacity)."
end

function find_max_byte_string_size(v::Vector{T}) where {T<:Union{Missing, AbstractString}}
    if isempty(v)
        return 0
    end

    len = length(v)
    @inbounds max_size = sizeof(v[1])

    if len == 1
        return max_size
    else
        for i in 2:len
            @inbounds max_size = max(max_size, sizeof(v[i]))
        end

        return max_size
    end
end

function find_max_byte_string_size(v::Vector{T}) where {T}
    return 0
end

function subtract_missing(::Type{T}) where {T}
    if isa(T, Union)
        if T.a <: Missing
            return subtract_missing(T.b)
        elseif T.b <: Missing
                return subtract_missing(T.a)
        else
            error("Can't subtract missing from data type $T.")
        end
    else
        @assert !(T <: Missing) "Datatype cannot be $T."
        return T
    end
end

@generated function Variable(conn::Connection, column::Vector{T};
    is_PLSQL_array::Bool=false, object_type_handle::Ptr{Cvoid}=C_NULL) where {T}

    if T == UInt8
        error("It's ambiguous whether this Variable has `UInt8` or `Vector{UInt8}` as the element type. Create this variable explicitly with `Variable(connection, type, oracle_type, native_type)`.")
    elseif T == Any
        # probably Julia v0.6. Will infer types in runtime.
        return :(build_variable_runtime_inferred_types(conn, column; is_PLSQL_array=is_PLSQL_array))
    else

        ELTYPE = subtract_missing(T)
        ott = infer_oracle_type_tuple(ELTYPE)

        return quote
            capacity = length(column)

            variable = Variable(conn, T, $(ott.oracle_type), $(ott.native_type);
                buffer_capacity=capacity,
                max_byte_string_size=find_max_byte_string_size(column),
                is_PLSQL_array=is_PLSQL_array,
                object_type_handle=object_type_handle)

            for i in 1:capacity
                variable[i] = column[i]
            end

            return variable
        end
    end
end

function Variable(conn::Connection, value::T;
    is_PLSQL_array::Bool=false, object_type_handle::Ptr{Cvoid}=C_NULL) where {T}
    return Variable(conn, [ value ], is_PLSQL_array=is_PLSQL_array, object_type_handle=object_type_handle)
end

@generated function Variable(
        connection::Connection,
        ::Type{T}
        ;
        buffer_capacity::Integer=ORA_DEFAULT_FETCH_ARRAY_SIZE,
        max_byte_string_size::Integer=4000, # maximum size allowed for VARCHAR2 fields
        is_PLSQL_array::Bool=false,
        object_type_handle::Ptr{Cvoid}=C_NULL) where {T}

    ELTYPE = subtract_missing(T)
    ott = infer_oracle_type_tuple(ELTYPE)

    return quote
        Variable(connection, T, $(ott.oracle_type), $(ott.native_type),
            buffer_capacity=buffer_capacity,
            max_byte_string_size=max_byte_string_size,
            is_PLSQL_array=is_PLSQL_array,
            object_type_handle=object_type_handle)
    end
end

function infer_eltype(column::Vector)
    types = unique([ typeof(i) for i in column ])

    if length(types) == 1
        @inbounds return types[1]
    elseif (Missing ∈ types) && (length(types) == 2)
        filter!( t -> t != Missing , types)
        return Union{Missing, types[1]}
    else
        error("Julia type $T not supported for Variables.")
    end
end

function build_variable_runtime_inferred_types(conn::Connection, column::Vector{T}; is_PLSQL_array::Bool=false) where T
    ELTYPE = infer_eltype(column)
    new_column = Vector{ELTYPE}()
    for element in column
        push!(new_column, element)
    end

    # going back to the generated function with appropriate type information.
    return Variable(conn, new_column, is_PLSQL_array=is_PLSQL_array)
end
