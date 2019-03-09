
@inline function oracle_type(::Lob{O}) :: OraOracleTypeNum where {O}
    return O
end

@inline function native_type(::Lob) :: OraNativeTypeNum
    return ORA_NATIVE_TYPE_LOB
end

function close(lob::Lob)
    if lob.is_open
        result = dpiLob_close(lob.handle)
        error_check(context(lob), result)
        lob.is_open = false
    end

    nothing
end

function add_ref(lob::Lob)
    result = dpiLob_addRef(lob.handle)
    error_check(context(lob), result)
end

@inline function check_valid_temp_lob_oracle_type_num(t::OraOracleTypeNum)
    is_valid = ( t == ORA_ORACLE_TYPE_CLOB
              || t == ORA_ORACLE_TYPE_NCLOB
              || t == ORA_ORACLE_TYPE_BLOB)

    @assert is_valid "Oracle type num $t is not allowed for a Temp Lob."
end

@inline function check_valid_lob_oracle_type_num(t::OraOracleTypeNum)
    is_valid = ( t == ORA_ORACLE_TYPE_CLOB
              || t == ORA_ORACLE_TYPE_NCLOB
              || t == ORA_ORACLE_TYPE_BLOB
              || t == ORA_ORACLE_TYPE_BFILE)

    @assert is_valid "Oracle type num $t is not allowed for Lob."
end

function Lob(conn::Connection, lob_type::OraOracleTypeNum)
    check_valid_temp_lob_oracle_type_num(lob_type)

    lob_handle_ref = Ref{Ptr{Cvoid}}()
    result = dpiConn_newTempLob(conn.handle, lob_type, lob_handle_ref)
    error_check(context(conn), result)
    return Lob(conn, lob_handle_ref[], lob_type)
end

# Reading and writing to the Lob in multiples of this size will improve performance.
function chunk_size(lob::Lob) :: UInt32
    chunk_size_ref = Ref{UInt32}()
    result = dpiLob_getChunkSize(lob.handle, chunk_size_ref)
    error_check(context(lob), result)
    return chunk_size_ref[]
end

# Returns the size of the data stored in the Lob. For character Lobs the size is in characters; for binary Lobs the size is in bytes.
function _lob_size(lob::Lob)
    lob_size_ref = Ref{UInt64}()
    result = dpiLob_getSize(lob.handle, lob_size_ref)
    error_check(context(lob), result)
    return lob_size_ref[]
end

function size_in_bytes(lob::Lob)
    @assert !is_character_data(lob) "This Lob holds character data. It's size is in Chars. Use `size_in_chars`."
    return _lob_size(lob)
end

function size_in_chars(lob::Lob)
    @assert is_character_data(lob) "This Lob holds byte data. It's size is in Bytes. Use `size_in_bytes`."
    return _lob_size(lob)
end

@inline function is_character_data(::T) :: Bool where {T<:Lob}
    return is_character_data(T)
end

function is_character_data(::Type{Lob{ORATYPE, T}}) :: Bool where {ORATYPE, T}
    if ORATYPE == ORA_ORACLE_TYPE_BFILE || ORATYPE == ORA_ORACLE_TYPE_BLOB
        return false
    else
        @assert ORATYPE == ORA_ORACLE_TYPE_CLOB || ORATYPE == ORA_ORACLE_TYPE_NCLOB
        return true
    end
end

# based on connection encoding/nencoding,
# returns the maximum number of bytes per char
# for this LOB. (CLOB -> encoding, NCLOB -> nencoding)
@inline function max_bytes_per_char(lob::Lob, size_in_chars::Integer=1) :: UInt64
    size_in_bytes_ref = Ref{UInt64}()
    result = dpiLob_getBufferSize(lob.handle, UInt64(size_in_chars), size_in_bytes_ref)
    error_check(context(lob), result)
    return size_in_bytes_ref[]
end

function Base.write(lob::Lob, data::Ptr{UInt8}, data_length::Integer)
    result = dpiLob_setFromBytes(lob.handle, data, UInt64(data_length))
    error_check(context(lob), result)
    nothing
end

Base.write(lob::Lob, data::Vector{UInt8}) = write(lob, pointer(data), length(data))
Base.write(lob::Lob, data::String) = write(lob, pointer(data), sizeof(data))

function Base.read(blob::Lob{ORA_ORACLE_TYPE_BLOB}) :: Vector{UInt8}
    blob_size = size_in_bytes(blob)
    result = undef_vector(UInt8, blob_size)

    open(blob, "r") do io
        i = 0
        while !eof(io)
            i += 1
            result[i] = read(io, UInt8)
        end
        @assert i == blob_size
    end

    return result
end

for ora_type in (ORA_ORACLE_TYPE_CLOB, ORA_ORACLE_TYPE_NCLOB)
    @eval begin
        function Base.read(clob::Lob{$ora_type}) :: String
            local result::String

            open(clob, "r") do io
                result = read(io, String)
            end

            return result
        end
    end
end

abstract type LobDataType end

struct BinaryLob <: LobDataType end
struct CharacterLob <: LobDataType end

abstract type AbstractLobIO{T<:LobDataType,L<:Lob,RW} <: IO end

#
# BinaryLobIO
#

mutable struct BinaryLobIO{L<:Lob,RW} <: AbstractLobIO{BinaryLob,L,RW}
    lob::L
    buffer::Vector{UInt8}
    buffer_start_pos::UInt64 # uninitialized implies 0. First position is 1.
    buffer_end_pos::UInt64
    pos::UInt64              # unread implies pos=0.
    mark::Int                # io.jl mark interface. Unmarked implies mark = -1.

    function BinaryLobIO(lob::Lob{O,P}, rw::Symbol, buffer::Vector{UInt8}) where {O,P}
        @assert !is_character_data(lob)
        check_lob_open_mode(rw)
        return new{Lob{O}, rw}(lob, buffer, 0, 0, 0, -1)
    end
end

mutable struct CharacterLobIO{L<:Lob,RW} <: AbstractLobIO{CharacterLob,L,RW}
    lob::L
    transfer_buffer::Vector{UInt8}
    transfer_buffer_capacity_in_chars::UInt64
    buffer::String
    buffer_start_pos::UInt64 # in chars
    buffer_end_pos::UInt64   # in chars
    pos::UInt64              # in chars
    buffer_pos_index::UInt64 # buffer string index relative to current position
    mark::Int

    function CharacterLobIO(lob::Lob{O,P}, rw::Symbol, transfer_buffer::Vector{UInt8}) where {O,P}
        @assert is_character_data(lob)
        check_lob_open_mode(rw)

        transfer_buffer_size_in_bytes = length(transfer_buffer)
        local transfer_buffer_capacity_in_chars::UInt64
        let
            bytes_per_char = max_bytes_per_char(lob)
            transfer_buffer_capacity_in_chars = UInt64(div(transfer_buffer_size_in_bytes, bytes_per_char))
        end

        return new{Lob{O}, rw}(lob, transfer_buffer, transfer_buffer_capacity_in_chars, "", 0, 0, 0, 0, -1)
    end
end

@inline function check_lob_open_mode(rw::Symbol)
    # TODO
    #@assert rw == :r || rw == :w || rw == :rw "Invalid mode for Lob IO: $rw."
    @assert rw == :r "Mode not supported: $rw."
end

function new_LobIO(lob::Lob, mode;
               buffer::Union{Nothing, Vector{UInt8}}=nothing,
               buffer_size::Union{Nothing, Integer}=nothing)

    buf = new_LobIO_buffer(lob, buffer, buffer_size)

    if is_character_data(lob)
        return CharacterLobIO(lob, Symbol(mode), buf)
    else
        return BinaryLobIO(lob, Symbol(mode), buf)
    end
end

function Base.open(f::Function, lob::Lob, mode;
              buffer::Union{Nothing, Vector{UInt8}}=nothing,
              buffer_size::Union{Nothing, Integer}=nothing)

    local io::AbstractLobIO = new_LobIO(lob, mode, buffer=buffer, buffer_size=buffer_size)

    try
        f(io)
    finally
    end
end

const APPROX_DEFAULT_CHUNK_SIZE_IN_BYTES = UInt64(1E6) # 1MB

function default_buffer_size_in_bytes(l::Lob)
    chunk_sz = chunk_size(l)
    num_chunks = div(APPROX_DEFAULT_CHUNK_SIZE_IN_BYTES, chunk_sz) + 1
    return chunk_sz*num_chunks
end

function new_LobIO_buffer(lob::Lob, buffer, capacity) :: Vector{UInt8}

    function alloc_buffer(cap) :: Vector{UInt8}
        buf = undef_vector(UInt8, cap)
        sizehint!(buf, cap)
        return buf
    end

    if buffer != nothing && capacity != nothing
        @assert length(buffer) == capacity "Provided capacity ($(Int(capacity))) argument diverges from provided buffer size ($(length(buffer)))."
        return buffer
    end

    if buffer != nothing
        return buffer
    end

    if capacity != nothing
        return alloc_buffer(capacity)
    end

    # both arguments were not given
    return alloc_buffer(default_buffer_size_in_bytes(lob))
end

@inline buffer_capacity_in_bytes(io::BinaryLobIO) = UInt64(length(io.buffer))
@inline buffer_capacity_in_bytes(io::CharacterLobIO) = UInt64(length(io.transfer_buffer))
@inline buffer_capacity_in_chars(io::CharacterLobIO) = io.transfer_buffer_capacity_in_chars

function read_chunk_to_buffer!(io::BinaryLobIO, pos::UInt64)
    @assert pos > 0 "Invalid Lob position: $(Int(pos))."
    max_bytes = buffer_capacity_in_bytes(io)
    buffer_len_ref = Ref{UInt64}(max_bytes)
    result = dpiLob_readBytes(io.lob.handle, pos, max_bytes, pointer(io.buffer), buffer_len_ref)
    error_check(context(io.lob), result)
    actual_bytes_read = buffer_len_ref[]

    @assert actual_bytes_read > 0 "Lob has no data at position $pos."

    io.pos = pos - 1 # put position right before the start of the new data

    io.buffer_start_pos = pos
    io.buffer_end_pos = pos + actual_bytes_read - 1

    nothing
end

function read_chunk_to_buffer!(io::CharacterLobIO, pos::UInt64)
    @assert pos > 0 "Invalid Lob position: $(Int(pos))."

    max_chars = buffer_capacity_in_chars(io)
    max_bytes = buffer_capacity_in_bytes(io)

    buffer_len_ref = Ref{UInt64}(max_bytes)
    result = dpiLob_readBytes(io.lob.handle, pos, max_chars, pointer(io.transfer_buffer), buffer_len_ref)
    error_check(context(io.lob), result)
    actual_bytes_read = buffer_len_ref[]

    @assert actual_bytes_read > 0 "Lob has no data at position $pos."

    # assign new data to buffer string, without truncating transfer_buffer
    io.buffer = unsafe_string(pointer(io.transfer_buffer), actual_bytes_read)

    io.pos = pos - 1 # put position right before the start of the new data
    io.buffer_start_pos = pos
    io.buffer_end_pos = pos + length(io.buffer) - 1 # length(io.buffer) is the actual number of characters in the string
    io.buffer_pos_index = 0

    nothing
end

@inline read_chunk_to_buffer!(io::AbstractLobIO, pos::Integer) = read_chunk_to_buffer!(io, UInt64(pos))

function read_next_chunk_to_buffer_if_exhausted!(io::AbstractLobIO)
    if buffer_data_available(io) == 0
        if io.buffer_start_pos == 0
            # this is the first time we read from the stream
            read_chunk_to_buffer!(io, 1) # read from first position
        else
            read_chunk_to_buffer!(io, io.buffer_end_pos + 1)
        end
    end
end

# Returns the number of chars or bytes available in the IO buffer.
function buffer_data_available(io::AbstractLobIO) :: UInt64

    if is_buffer_uninitialized(io)
        return UInt64(0)
    end

    if is_inside_buffer_position(io)
        # bytes available are the distance between end and current positions
        return io.buffer_end_pos - io.pos
    else
        # buffer is initialized, but nothing was read from it.
        return io.buffer_end_pos - io.buffer_start_pos + 1
    end
end

@inline function is_buffer_uninitialized(io::AbstractLobIO) :: Bool
    if io.buffer_start_pos == 0
        return true
    else
        # buffer must be initialized
        @assert io.buffer_end_pos > 0 "AbstractLobIO in inconsistent state."
        return false
    end
end

@inline function is_inside_buffer_position(io::AbstractLobIO, pos::Integer=io.pos) :: Bool
    return io.buffer_start_pos <= pos && pos <= io.buffer_end_pos
end

@inline function check_inside_buffer_position(io::AbstractLobIO)
    @assert is_inside_buffer_position(io) "AbstractLobIO in inconsistent state."
end

# we reach end-of-file if current position equals the size of the lob.
function Base.eof(io::AbstractLobIO) :: Bool
    if buffer_data_available(io) != 0
        return false
    else
        sz = _lob_size(io.lob) # number of chars or bytes, depending on Lob type
        return sz == 0 || sz == io.pos
    end
end

function prepare_read_next!(io::AbstractLobIO)
    if eof(io)
        throw(EOFError())
    end

    read_next_chunk_to_buffer_if_exhausted!(io)

    # inc position
    io.pos += 1
    check_inside_buffer_position(io)
    nothing
end

function Base.read(io::BinaryLobIO, ::Type{UInt8}) :: UInt8
    prepare_read_next!(io)
    @inbounds return io.buffer[io.pos - io.buffer_start_pos + 1]
end

function Base.read(io::CharacterLobIO, ::Type{Char}) :: Char
    prepare_read_next!(io)
    io.buffer_pos_index = nextind(io.buffer, io.buffer_pos_index)
    return io.buffer[io.buffer_pos_index]
end

function Base.read(io::CharacterLobIO, ::Type{String}) :: String
    prepare_read_next!(io)
    io.buffer_pos_index = nextind(io.buffer, io.buffer_pos_index)

    result = io.buffer[io.buffer_pos_index:end]
    io.pos = io.buffer_end_pos

    # continues till the end of the Lob
    while !eof(io)
        io.buffer_pos_index = 0
        read_chunk_to_buffer!(io, io.buffer_end_pos + 1)
        result *= io.buffer
        io.pos = io.buffer_end_pos
    end

    return result
end

function Base.position(io::AbstractLobIO) :: UInt64
    return io.pos
end

function Base.seek(io::AbstractLobIO, pos::Integer)
    if is_inside_buffer_position(io, pos)
        io.pos = pos # next read position will be pos + 1

        if isa(io, CharacterLobIO)
            char_number_in_buffer = io.pos - io.buffer_start_pos + 1
            char_index_in_buffer = firstindex(io.buffer)

            if char_number_in_buffer > 1
                for i in 2:char_number_in_buffer
                    char_index_in_buffer = nextind(io.buffer, char_index_in_buffer)
                end
            end

            io.buffer_pos_index = char_index_in_buffer
        end
    else
        read_chunk_to_buffer!(io, pos + 1)
    end

    nothing
end
