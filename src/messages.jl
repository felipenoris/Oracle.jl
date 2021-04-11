
function Message(conn::Connection)
    msg_props_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_newMsgProps(conn.handle, msg_props_handle_ref)
    error_check(context(conn), result)
    return Message(conn, msg_props_handle_ref[])
end

function set_payload_bytes!(msg::Message, bytes::Vector{UInt8})
    result = dpiMsgProps_setPayloadBytes(msg.handle, pointer(bytes), length(bytes))
    error_check(context(msg), result)
    nothing
end

function get_payload_bytes(msg::Message) :: Vector{UInt8}
    dpi_object_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    bytes_array_ptr_ref = Ref{Ptr{UInt8}}(C_NULL)
    bytes_array_len_ref = Ref{UInt32}(0)
    result = dpiMsgProps_getPayload(msg.handle, dpi_object_handle_ref, bytes_array_ptr_ref, bytes_array_len_ref)
    error_check(context(msg), result)

    @assert dpi_object_handle_ref[] == C_NULL "Message payload is object"
    @assert bytes_array_ptr_ref[] != C_NULL

    return deepcopy(unsafe_wrap(Vector{UInt8}, bytes_array_ptr_ref[], bytes_array_len_ref[]))
end

function set_correlation!(msg::Message, correlation::AbstractString)
    err = dpiMsgProps_setCorrelation(msg.handle, pointer(correlation), sizeof(correlation))
    error_check(context(msg), err)
    nothing
end

#function clear_correlation!(msg::Message)
#    err = dpiMsgProps_setCorrelation(msg.handle, Ptr{UInt8}(C_NULL), 0)
#    error_check(context(msg), err)
#    nothing
#end

function get_correlation(msg::Message) :: Union{Nothing, String}
    val_ref = Ref{Ptr{UInt8}}()
    val_length_ref = Ref{UInt32}()
    err = dpiMsgProps_getCorrelation(msg.handle, val_ref, val_length_ref)
    error_check(context(msg), err)
    if val_ref[] == C_NULL
        return nothing
    else
        return unsafe_string(val_ref[], val_length_ref[])
    end
end
