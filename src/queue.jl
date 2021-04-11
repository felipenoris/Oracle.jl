
function Queue(conn::Connection, name::AbstractString)
    queue_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_newQueue(conn.handle, name, C_NULL, queue_handle_ref)
    error_check(context(conn), result)
    return Queue(conn, queue_handle_ref[], name)
end

function enqueue(queue::Queue, msg::Message)
    result = dpiQueue_enqOne(queue.handle, msg.handle)
    error_check(context(queue), result)
    nothing
end

function enqueue(queue::Queue, msgs::Vector{T}) where {T<:Message}
    msg_handles = [ msg.handle for msg in msgs ]
    result = dpiQueue_enqMany(queue.handle, length(msg_handles), pointer(msg_handles))
    error_check(context(queue), result)
    nothing
end

function dequeue(queue::Queue) :: Message
    msg_props_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiQueue_deqOne(queue.handle, msg_props_handle_ref)
    error_check(context(queue), result)
    return Message(queue, msg_props_handle_ref[])
end

function dequeue(queue::Queue, max_msgs::Integer) :: Vector{Message}
    num_props = Ref{UInt32}(max_msgs)
    msg_handle_array_ref = Ref{Ptr{Cvoid}}()

    # dpiMsgProps **props
    # an array of references to message properties which will be populated upon successful completion of this function.
    # Each of these references should be released when they are no longer needed by calling the function dpiMsgProps_release().
    buffer = Vector{Ptr{Cvoid}}(undef, max_msgs)
    err = dpiQueue_deqMany(queue.handle, num_props, pointer(buffer))
    error_check(context(queue), err)

    if iszero(num_props[])
        return Vector{Message}()
    end

    result = Vector{Message}(undef, num_props[])
    for i in 1:num_props[]
        result[i] = Message(queue, buffer[i])
    end

    return result
end
