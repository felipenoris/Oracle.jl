
module Timestamps

import Dates
import Dates: Date,
              Time,
              AbstractDateTime,
              DateTime,
              Hour,
              Minute,
              Second,
              Nanosecond,
              UTInstant,
              totaldays,
              argerror,
              daysinmonth,
              days,
              value,
              year, month, day, hour, minute, second, millisecond, microsecond, nanosecond

export Timestamp, TimestampTZ, tz_hour_offset, tz_minute_offset

"Nanosecond precision Date and Time."
abstract type AbstractTimestamp <: AbstractDateTime end

struct Timestamp <: AbstractTimestamp
    date::Date
    time::Time
end

struct TimestampTZ{L} <: AbstractTimestamp
    ts::Timestamp
    tz_hour_offset::Int8
    tz_minute_offset::Int8
end

TimestampTZ(local_time_zone::Bool, ts::Timestamp, hour_offset::Integer, minute_offset::Integer) = TimestampTZ{local_time_zone}(ts, Int8(hour_offset), Int8(minute_offset))

ts_date(t::Timestamp) = t.date
ts_time(t::Timestamp) = t.time

ts_date(t::TimestampTZ) = ts_date(t.ts)
ts_time(t::TimestampTZ) = ts_time(t.ts)

function is_ltz(t::TimestampTZ{L}) :: Bool where {L}
    return L
end

"""
    Timestamp(y, [m, d, h, mi, s, ns]) -> Timestamp
Construct a `Timestamp` type by parts. Arguments must be convertible to [`Int64`](@ref).
"""
function Timestamp(y::Integer, m::Integer=1, d::Integer=1,
                   h::Integer=0, mi::Integer=0, s::Integer=0, ns::Integer=0)
    date = Date(y,m,d)
    time = Time(Nanosecond( ns + 1E9 * ( s + 60*mi + 3600*h ) ))
    return Timestamp(date, time)
end

function TimestampTZ(local_time_zone::Bool, y::Integer, m::Integer=1, d::Integer=1,
                     h::Integer=0, mi::Integer=0, s::Integer=0, ns::Integer=0,
                     tz_hour_offset::Integer=0, tz_minute_offset::Integer=0)
    ts = Timestamp(y, m, d, h, mi, s, ns)
    return TimestampTZ(local_time_zone, ts, tz_hour_offset, tz_minute_offset)
end

Base.eps(t::AbstractTimestamp) = Nanosecond(1)
Base.:(==)(t1::Timestamp, t2::Timestamp) = t1.date == t2.date && t1.time == t2.time
Base.:(==)(t1::TimestampTZ, t2::TimestampTZ) = t1.ts == t2.ts && t1.tz_hour_offset == t2.tz_hour_offset && t1.tz_minute_offset == t2.tz_minute_offset
Base.hash(ts::Timestamp) = 1 + hash(ts.date) + hash(ts.time)
Base.hash(ts::TimestampTZ) = 2 + hash(ts.ts) + hash(ts.tz_hour_offset) + hash(ts.tz_minute_offset)

function Base.:(==)(ts::Timestamp, dt::DateTime)
    if microsecond(ts) == 0 && nanosecond(ts) == 0
        return (
               days(ts) == days(dt)
            && hour(ts) == hour(dt)
            && minute(ts) == minute(dt)
            && second(ts) == second(dt)
            && millisecond(ts) == millisecond(dt)
        )
    else
        # Timestamp has nanosecond precision. DateTime has millisecond precision.
        return false
    end
end

Base.:(==)(dt::DateTime, ts::Timestamp) = ts == dt

Dates.days(t::AbstractTimestamp) = Dates.days(ts_date(t))
nanoseconds(t::AbstractTimestamp) = Dates.value(ts_time(t))

for fun in (:hour, :minute, :second, :millisecond, :microsecond, :nanosecond)
    @eval begin
        ($fun)(t::AbstractTimestamp) = ($fun)(ts_time(t))
    end
end

function Timestamp(dt::DateTime)
    return Timestamp(year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt), Int64(millisecond(dt)*1E6))
end

end # module Timestamps

using ..Timestamps

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
    return OraTimestamp(yy, mm, dd, hh, mi, ss, fsecond, ts.tz_hour_offset, ts.tz_minute_offset)
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
