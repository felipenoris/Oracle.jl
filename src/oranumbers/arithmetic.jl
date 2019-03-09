
"""
Increments the exponent of a number, without altering it's final value.
The result is a non-normalized OraNumber.

# Example

Given a number "2244" = 22.44 x 100e1 (mantissa 22 44, exponent 1)
If `by_exponent = 2`, the result will be 00.002244 x 100e3 ( 00 00 22 44, exponent 3 )
"""
@inline function inc_exponent(num::OraNumber, by_exponent::Int8) :: OraNumber
    @assert by_exponent >= 0

    if by_exponent == Int8(0)
        return num
    end

    if iszero(num) || is_negative_1e126(num)
        error("inc_exponent not supported for $num.")
    end

    new_len = num.len + by_exponent

    if new_len > UInt8(21)
        error("Overflow on inc_exponent $num by $by_exponent")
    end

    old_exponent_byte = decode_exponent_byte(num)
    new_exponent_byte = old_exponent_byte + by_exponent
    if new_exponent_byte < old_exponent_byte
        error("Overflow on inc_exponent $num by $by_exponent.")
    end

    _isnegative = isnegative(num)
    new_exponent_encoded = encode_exponent_byte(new_exponent_byte, _isnegative)

    @inline function f(i)
        if i <= by_exponent
            return encode_mantissa_byte(0x00, _isnegative)
        else
            return num.mantissa[i-by_exponent]
        end
    end

    new_mantissa = Tuple( f(i) for i in 1:MAX_SIZEOF_MANTISSA )

    return OraNumber(new_len, new_exponent_encoded, new_mantissa)
end

@inline inc_exponent(num::OraNumber, by_exponent::Integer) = inc_exponent(num, Int8(by_exponent))

@inline function isnormalized(num::OraNumber) :: Bool
    if sizeof_mantissa(num) == 0x00
        # 0 of -1e126
        return true
    end

    # the number is considered normalized when the first mantissa byte is not zero
    return decode_mantissa_byte(num, 1) != 0x00
end

@inline function normalize(num::OraNumber) :: OraNumber
    # gets the number of left-hand-size zeros in the mantissa
    local lhs_mantissa_zero_bytes::Int8 = Int8(0)
    _isnegative = isnegative(num)
    _sizeof_mantissa = sizeof_mantissa(num)
    for i in 1:_sizeof_mantissa
        if decode_mantissa_byte(num, i, _isnegative) != 0x00
            break
        end

        lhs_mantissa_zero_bytes += Int8(1)
        @assert lhs_mantissa_zero_bytes != 0x00 "Overflow on normalizing $num."
    end

    if lhs_mantissa_zero_bytes == Int8(0)
        # num is already normalized
        return num
    else
        # will decrease exponent by `lhs_mantissa_zero_bytes`
        new_len = num.len - lhs_mantissa_zero_bytes
        old_exponent_byte = decode_exponent_byte(num)
        new_exponent_byte = old_exponent_byte - lhs_mantissa_zero_bytes

        if new_exponent_byte > old_exponent_byte
            error("Underflow on normalizing $num.")
        end

        new_exponent_encoded = encode_exponent_byte(new_exponent_byte, _isnegative)

        @inline function f(i)
            index = i + lhs_mantissa_zero_bytes
            if index > MAX_SIZEOF_MANTISSA
                return 0x00
            else
                return num.mantissa[i + lhs_mantissa_zero_bytes]
            end
        end

        new_mantissa = Tuple( f(i) for i in 1:MAX_SIZEOF_MANTISSA )
        return OraNumber(new_len, new_exponent_encoded, new_mantissa)
    end
end

function Base.:(-)(num::OraNumber) :: OraNumber
    if iszero(num)
        return num
    elseif is_negative_1e126(num)
        error("Not supported.")
    end

    _isnegative = isnegative(num)
    new_exponent = encode_exponent_byte(decode_exponent_byte(num), !_isnegative)
    _sizeof_mantissa = sizeof_mantissa(num)

    @inline function f(i)
        if i > _sizeof_mantissa
            if !_isnegative && i == _sizeof_mantissa + 1
                # add trailing byte, because we can
                return TRAILING_BYTE_ON_NEGATIVE_NUMBERS
            else
                return 0x00
            end
        else
            return encode_mantissa_byte( decode_mantissa_byte(num, i, _isnegative) , !_isnegative )
        end
    end

    new_mantissa = Tuple(f(i) for i in 1:MAX_SIZEOF_MANTISSA)

    if _isnegative
        # new number is positive
        if num.mantissa[num.len-UInt8(1)] == TRAILING_BYTE_ON_NEGATIVE_NUMBERS
            # old number has a trailing byte. Let's remove it
            return OraNumber(num.len - UInt8(1), new_exponent, new_mantissa)
        end
    else
        # new number is negative
        if num.len < MAX_SIZEOF_MANTISSA + 1
            # there's room for a trailing byte. Let's add it, given that `f` added it to the mantissa.
            return OraNumber(num.len + UInt8(1), new_exponent, new_mantissa)
        end
    end

    return OraNumber(num.len, new_exponent, new_mantissa)
end
