
const TRAILING_BYTE_ON_NEGATIVE_NUMBERS = 0x66

@inline isnull(num::OraNumber) = num.len == 0xff
@inline isnegative(num::OraNumber) = num.ex & 0x80 == 0x00
@inline ispositive(num::OraNumber) = !isnegative(num)
@inline iszero(num::OraNumber) = sizeof_mantissa(num) == 0x00 && ispositive(num)
@inline is_negative_1e126(num::OraNumber) = sizeof_mantissa(num) == 0x00 && isnegative(num)

@inline function sizeof_mantissa(num::OraNumber) :: UInt8
    @assert !isnull(num) "null number"

    len_byte = num.len

    if isnegative(num) && num.mantissa[len_byte-UInt(1)] == TRAILING_BYTE_ON_NEGATIVE_NUMBERS
        # ignore trailing byte that contains the number 102 on negative numbers
        return len_byte - UInt(2)
    else
        return len_byte - UInt(1)
    end
end

@inline function decode_exponent_byte(num::OraNumber) :: Int8
    @assert !isnull(num) "null value"
    iszero(num) && return 0x00
    is_negative_1e126(num) && return UInt8(126)

    byte = num.ex

    if isnegative(num)
        # bits are inverted for negative numbers
        byte = ~byte
    end

    # the byte has an offset of 11000001 (bit string)
    return reinterpret(Int8, byte - 0xc1)
end

# inverse of `decode_exponent_byte`. Should not be used for zero/special number
@inline function encode_exponent_byte(ex::Int8, is_negative::Bool) :: UInt8
    local byte::UInt8 = reinterpret(UInt8, ex) + 0xc1

    if is_negative
        byte = ~byte
    end

    return byte
end

@inline function encode_mantissa_byte(byte::UInt8, is_negative::Bool) :: UInt8
    if is_negative
        return 0x65 - byte
    else
        return byte + 0x01
    end
end

# returns a mantissa byte as a 100-base number
@inline function decode_mantissa_byte(num::OraNumber, index::Integer, is_negative::Bool=isnegative(num)) :: UInt8
    @assert index <= MAX_SIZEOF_MANTISSA "Out of bounds."

    # len is exponent + mantissa bytes, so we subtract one
    if index > num.len - UInt(1)
        # unused byte
        return 0x00
    end

    if is_negative
        if index == num.len - UInt(1) && num.mantissa[index] == TRAILING_BYTE_ON_NEGATIVE_NUMBERS
            # trailing byte on negative numbers
            return 0x00
        else
            # negative numbers are subtracted from the value 101
            return 0x65 - num.mantissa[index]
        end
    else
        # positive numbers have 1 added to them
        return num.mantissa[index] - 0x01
    end
end
