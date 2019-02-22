
function debug_number(num::OraNumber)
    if isnull(num)
        error("number stores a null value.")
    end

    mantissa_length = sizeof_mantissa(num)
    if mantissa_length > 20
        error("Invalid mantissa length $(Int(mantissa_length))")
    end

    println("number: ", string(num))
    println("constructor: Oracle.OraNumber(", num.len, ", ", num.ex, ", ", num.mantissa, ")")
    println("is positive? ", ispositive(num))
    println("iszero? ", iszero(num))
    println("sizeof mantissa: ", Int(sizeof_mantissa(num)))
    println("exponent ", exponent(num))
    print_mantissa(num)
    print("\n")
end

function print_mantissa(num::OraNumber)
    print("mantissa: ")
    mantissa_bytes_count = Int(sizeof_mantissa(num))
    for i in 1:mantissa_bytes_count
        print( decode_mantissa_byte(num, i) )
        if i != mantissa_bytes_count
            print(", ")
        end
    end
    print("\n")
end

function print_number_string(io::IO, num::OraNumber)
    if isnull(num)
        print(io, "nothing")
    elseif iszero(num)
        print(io, '0')
    elseif is_negative_1e126(num)
        print(io, "-1e126")
    else
        is_negative = isnegative(num)
        _exponent = exponent(num)
        _sizeof_mantissa = sizeof_mantissa(num)

        if is_negative
            print(io, '-')
        end

        if _exponent < 0
            print(io, "0.")
            for i in 1:(abs(_exponent)-1)*2
                print(io, '0')
            end
        end

        for i in 1:_sizeof_mantissa
            if _exponent >= 0 && i == 1
                print(io, decode_mantissa_byte(num, i, is_negative) )
            else
                print(io, lpad(decode_mantissa_byte(num, i, is_negative), 2, '0') )
            end

            if i-1 == _exponent && i != _sizeof_mantissa
                print(io, '.')
            end
        end

        if _exponent >= _sizeof_mantissa
            zeros_rhs = (_exponent - _sizeof_mantissa + 1) * 2
            for i in 1:zeros_rhs
                print(io, '0')
            end
        end
    end
end
