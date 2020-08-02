
struct OraExecMode
    val::UInt32
end

UInt32(exec_mode::OraExecMode) = exec_mode.val

Base.convert(::Type{OraExecMode}, val::UInt32) = OraExecMode(val)
Base.convert(::Type{UInt32}, exec_mode::OraExecMode) = exec_mode.val

OraExecMode(val::Integer) = OraExecMode(UInt32(val))

const ORA_MODE_EXEC_DEFAULT             = OraExecMode(0)
const ORA_MODE_EXEC_DESCRIBE_ONLY       = OraExecMode(16)
const ORA_MODE_EXEC_COMMIT_ON_SUCCESS   = OraExecMode(32)
const ORA_MODE_EXEC_BATCH_ERRORS        = OraExecMode(128)
const ORA_MODE_EXEC_PARSE_ONLY          = OraExecMode(256)
const ORA_MODE_EXEC_ARRAY_DML_ROWCOUNTS = OraExecMode(1048576)

# `OraExecMode` can be "ored" together
Base.:|(a::OraExecMode, b::OraExecMode) = OraExecMode(a.val | b.val)
Base.:&(a::OraExecMode, b::OraExecMode) = OraExecMode(a.val & b.val)
