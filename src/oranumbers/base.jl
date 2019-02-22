
@inline Base.signbit(num::OraNumber) = isnegative(num)

@inline function Base.exponent(num::OraNumber) :: Int
    return Int(decode_exponent_byte(num))
end

function Base.show(io::IO, num::OraNumber)
    print(io, "OraNumber(\"")
    print_number_string(io, num)
    print(io, "\")")
end

function Base.string(num::OraNumber)
    io = IOBuffer()
    print_number_string(io, num)
    return String(take!(io))
end

@inline Base.zero(::Type{OraNumber}) = OraNumber(0x01, 0x80, (0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00))
@inline Base.one(::Type{OraNumber}) = OraNumber(0x02, 0xc1, (0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00))

@inline OraNumber(::Nothing) = OraNumber(0xff, 0x00, (0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00))

function Base.:(==)(num1::OraNumber, num2::OraNumber)
    @assert isnormalized(num1) && isnormalized(num2) "Can't compare non-normalized OraNumbers."

    if num1.len != num2.len || num1.ex != num2.ex
        return false
    end

    # compare mantissa
    for i in 1:sizeof_mantissa(num1)
        if num1.mantissa[i] != num2.mantissa[i]
            return false
        end
    end

    return true
end
