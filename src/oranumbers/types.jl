
const MAX_SIZEOF_MANTISSA = 20

struct OraNumber <: Real
    len::UInt8
    ex::UInt8
    mantissa::NTuple{MAX_SIZEOF_MANTISSA, UInt8}
end
