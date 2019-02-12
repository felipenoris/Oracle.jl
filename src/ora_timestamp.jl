
using Oracle.Timestamps

OraTimestamp(date::Date) = OraTimestamp(Dates.year(date), Dates.month(date), Dates.day(date), 0, 0, 0, 0, 0, 0)
OraTimestamp(datetime::DateTime) = OraTimestamp(Dates.year(datetime), Dates.month(datetime), Dates.day(datetime), Dates.hour(datetime), Dates.minute(datetime), Dates.second(datetime), Int64(Dates.millisecond(datetime)*1E6), 0, 0)

function OraTimestamp(ts::Timestamp)
    yy = Int16(Dates.year(ts))
    mm = UInt8(Dates.month(ts))
    dd = Dates.day(ts)
    hh = Dates.hour(ts)
    mi = Dates.minute(ts)
    ss = Dates.second(ts)
    fsecond = Dates.millisecond(ts) * 1_000_000 + Dates.microsecond(ts) * 1_000 + Dates.nanosecond(ts)
    return OraTimestamp(yy, mm, dd, hh, mi, ss, fsecond, 0, 0)
end

function OraTimestamp(ts::TimestampTZ)
    yy = Int16(Dates.year(ts))
    mm = UInt8(Dates.month(ts))
    dd = Dates.day(ts)
    hh = Dates.hour(ts)
    mi = Dates.minute(ts)
    ss = Dates.second(ts)
    fsecond = Dates.millisecond(ts) * 1_000_000 + Dates.microsecond(ts) * 1_000 + Dates.nanosecond(ts)
    return OraTimestamp(yy, mm, dd, hh, mi, ss, fsecond, ts.tz_offset.hour, ts.tz_offset.minute)
end

function parse_timestamp(oracle_type::OraOracleTypeNum, oracle_timestamp::OraTimestamp) :: Union{Dates.DateTime, Timestamp, TimestampTZ}
    if oracle_type == ORA_ORACLE_TYPE_DATE
        return parse_datetime(oracle_timestamp)
    elseif oracle_type == ORA_ORACLE_TYPE_TIMESTAMP
        return parse_timestamp(oracle_timestamp)
    elseif oracle_type == ORA_ORACLE_TYPE_TIMESTAMP_TZ
        return parse_timestamp_tz(oracle_timestamp)
    elseif oracle_type == ORA_ORACLE_TYPE_TIMESTAMP_LTZ
        return parse_timestamp_ltz(oracle_timestamp)
    else
        error("Unexpected oracle type for timestamp: $oracle_type.")
    end
end

function parse_datetime(ts::OraTimestamp) :: Dates.DateTime
    @assert ts.fsecond == 0
    @assert ts.tzHourOffset == 0
    @assert ts.tzMinuteOffset == 0
    return DateTime(ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second)
end

function parse_timestamp(ts::OraTimestamp) :: Timestamp
    @assert ts.tzHourOffset == 0
    @assert ts.tzMinuteOffset == 0
    return Timestamp(ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second, ts.fsecond)
end

function parse_timestamp_tz(ts::OraTimestamp) :: TimestampTZ
    return TimestampTZ(false, ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second, ts.fsecond, ts.tzHourOffset, ts.tzMinuteOffset)
end

function parse_timestamp_ltz(ts::OraTimestamp) :: TimestampTZ
    return TimestampTZ(true, ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second, ts.fsecond, ts.tzHourOffset, ts.tzMinuteOffset)
end
