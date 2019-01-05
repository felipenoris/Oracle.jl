
function is_null(val::DataValue)
#=
    # DataValue.dpi_data::dpiData

    if val.dpi_data.is_null == 0
        return false
    elseif val.dpi_data.is_null == 1
        return true
    else
        error("Unexpected value for dpiData.is_null field: $(val.dpi_data.is_null)")
    end
=#

    is_null_as_cint = dpiData_isNull(val.dpi_data_handle)
    if is_null_as_cint == 0
        return false
    elseif is_null_as_cint == 1
        return true
    else
        error("Unexpected value for dpiData.is_null field: $(Int(is_null_as_cint))")
    end
end

function parse_julia_value(val::DataValue)

	if is_null(val)
		return missing

	elseif val.native_type == DPI_NATIVE_TYPE_DOUBLE
		return dpiData_getDouble(val.dpi_data_handle)

	elseif val.native_type == DPI_NATIVE_TYPE_BOOLEAN
		result_bool = dpiData_getBool(val.dpi_data_handle)
		@assert result_bool == 0 || result_bool == 1
		return result_bool == 1

	elseif val.native_type == DPI_NATIVE_TYPE_FLOAT
		return dpiData_getFloat(val.dpi_data_handle)

	elseif val.native_type == DPI_NATIVE_TYPE_INT64
		return dpiData_getInt64(val.dpi_data_handle)

	elseif val.native_type == DPI_NATIVE_TYPE_UINT64
		return dpiData_getUint64(val.dpi_data_handle)

	elseif val.native_type == DPI_NATIVE_TYPE_BYTES
		return dpiData_getBytes(val.dpi_data_handle)

	else
		error("data type not supported")
	end
end

Base.getindex(val::DataValue) = parse_julia_value(val)
