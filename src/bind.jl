
@inline function check_bind_bounds(stmt::Stmt, pos::Integer)
    @assert pos > 0 && pos <= stmt.bind_count "Bind position $pos out of bounds."
end

@inline function check_bind_bounds(stmt::Stmt, name::AbstractString)
    name_upper = uppercase(name)
    @assert haskey(stmt.bind_names_index, name_upper) "Bind name $name_upper not found in statement."
end

@inline check_bind_bounds(stmt::Stmt, name::Symbol) = check_bind_bounds(stmt, string(name))

const NameOrPositionTypes = Union{Integer, String, Symbol}

#
# Bind Variable to Stmt
#

@inline function Base.setindex!(stmt::Stmt, value::Variable, name_or_position::NameOrPositionTypes)
    bind!(stmt, value, name_or_position)
end

@generated function bind!(stmt::Stmt, variable::Variable, name_or_position::K) where {K<:NameOrPositionTypes}

    if name_or_position <: Integer
        name_or_position_exp = :(UInt32(name_or_position))
        bind_function_name = :dpiStmt_bindByPos
    elseif name_or_position <: Symbol
        name_or_position_exp = :(string(name_or_position))
        bind_function_name = :dpiStmt_bindByName
    elseif name_or_position <: String
        name_or_position_exp = :name_or_position
        bind_function_name = :dpiStmt_bindByName
    else
        error("Unsupported type for argument `name_or_position`: $name_or_position.")
    end

    return quote
        key = $name_or_position_exp
        check_bind_bounds(stmt, key)
        result = $(bind_function_name)(stmt.handle, key, variable.handle)
        error_check(context(stmt), result)
        nothing
    end
end

#
# Bind Value to Stmt
#

@generated function bind!(stmt::Stmt, value::JuliaOracleValue{O,N}, name_or_position::K) where {K<:NameOrPositionTypes,O,N}

    # https://github.com/oracle/odpi/issues/99
    if O == ORA_ORACLE_TYPE_TIMESTAMP_TZ || O == ORA_ORACLE_TYPE_TIMESTAMP_LTZ
        error("Can't bind Timestamp with TimeZone directly to Statement. Use a Variable instead.")
    end

    if O == ORA_ORACLE_TYPE_RAW || O == ORA_ORACLE_TYPE_LONG_RAW
        error("Can't bind RAW data type directly to Statement. Use a Variable instead.")
    end

    if name_or_position <: Integer
        name_or_position_exp = :(UInt32(name_or_position))
        bind_function_name = :dpiStmt_bindValueByPos
    elseif name_or_position <: Symbol
        name_or_position_exp = :(string(name_or_position))
        bind_function_name = :dpiStmt_bindValueByName
    elseif name_or_position <: String
        name_or_position_exp = :name_or_position
        bind_function_name = :dpiStmt_bindValueByName
    else
        error("Unsupported type for argument `name_or_position`: $name_or_position.")
    end

    return quote
        key = $name_or_position_exp
        check_bind_bounds(stmt, key)
        data_ref = Ref{OraData}()
        set_oracle_value_at!(value, value[], data_ref)
        result = $(bind_function_name)(stmt.handle, key, N, data_ref)
        error_check(context(stmt), result)
        nothing
    end
end

@inline function Base.setindex!(stmt::Stmt, value::JuliaOracleValue, name_or_position::N) where {N<:NameOrPositionTypes}
    bind!(stmt, value, name_or_position)
end

@inline function Base.setindex!(stmt::Stmt, value::T, name_or_position::N) where {T, N<:NameOrPositionTypes}
    bind!(stmt, JuliaOracleValue(value), name_or_position)
end

@inline function Base.setindex!(stmt::Stmt, ::Missing, name_or_position::N) where {N<:NameOrPositionTypes}
    error("Cannot bind missing value to statement without type information. Use `stmt[pos, julia_type] = value` or `stmt[pos, oracle_type, native_type] = value`.")
end

@inline function Base.setindex!(stmt::Stmt, ::Missing, name_or_position::N, oracle_type::OraOracleTypeNum, native_type::OraNativeTypeNum) where {N<:NameOrPositionTypes}
    val = JuliaOracleValue(oracle_type, native_type, Missing)
    val[] = missing
    bind!(stmt, val, name_or_position)
end

@inline function Base.setindex!(stmt::Stmt, m::Missing, name_or_position::N, ::Type{T}) where {T,N<:NameOrPositionTypes}
    ott = infer_oracle_type_tuple(T)
    setindex!(stmt, m, name_or_position, ott.oracle_type, ott.native_type)
end
