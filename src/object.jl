
function ObjectType(conn::Connection, name::AbstractString)
    obj_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_getObjectType(conn.handle, name, obj_ref)
    error_check(context(conn), result)
    return ObjectType(conn, obj_ref[])
end

object_type_schema(obj::ObjectType) = unsafe_string(obj.type_info.schema, obj.type_info.schema_length)
object_type_name(obj::ObjectType) = unsafe_string(obj.type_info.name, obj.type_info.name_length)
object_type_num_attributes(obj::ObjectType) = Int(obj.type_info.num_attributes)
object_type_is_collection(obj::ObjectType) = obj.type_info.is_collection != 0

function object_type_element_type_info(obj::ObjectType) :: Union{Nothing, OraDataTypeInfo}
    if object_type_is_collection(obj)
        return obj.element_type_info
    else
        return nothing
    end
end
