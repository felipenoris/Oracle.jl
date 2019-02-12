
module Timestamps

@static if VERSION < v"0.7-"
    import Base.Dates
    import Base.Dates: Date,
                  Time,
                  TimeType,
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
else

    import Dates
    import Dates: Date,
                  Time,
                  TimeType,
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
end

export Timestamp, TimestampTZ, TimeZoneOffset

"Nanosecond precision Date and Time."
abstract type AbstractTimestamp <: TimeType end

struct Timestamp <: AbstractTimestamp
    date::Date
    time::Time
end

# https://github.com/oracle/odpi/issues/38
# When fetched, tzMinuteOffset is negative if tzHourOffset is negative
# and is positive when tzHourOffset is positive.
struct TimeZoneOffset
    hour::Int8
    minute::Int8

    function TimeZoneOffset(hour::Int8, minute::Int8)
        @assert minute == 0 || signbit(hour) == signbit(minute) "`hour` and `minute` Time Zone offset must have the same sign."
        return new(hour, minute)
    end
end

TimeZoneOffset(hour::Integer, minute::Integer) = TimeZoneOffset(Int8(hour), Int8(minute))

struct TimestampTZ{L} <: AbstractTimestamp
    ts::Timestamp
    tz_offset::TimeZoneOffset

    function TimestampTZ{L}(ts::Timestamp, tz_offset::TimeZoneOffset) where {L}
        @assert isa(L, Bool)
        return new{L}(ts, tz_offset)
    end
end

TimestampTZ(local_time_zone::Bool, ts::Timestamp, tz_offset::TimeZoneOffset) = TimestampTZ{local_time_zone}(ts, tz_offset)

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
    return TimestampTZ(local_time_zone, ts, TimeZoneOffset(tz_hour_offset, tz_minute_offset))
end

Base.eps(t::AbstractTimestamp) = Nanosecond(1)
Base.:(==)(t1::Timestamp, t2::Timestamp) = t1.date == t2.date && t1.time == t2.time
Base.:(==)(o1::TimeZoneOffset, o2::TimeZoneOffset) = o1.hour == o2.hour && o1.minute == o2.minute
Base.:(==)(t1::TimestampTZ, t2::TimestampTZ) = t1.ts == t2.ts && t1.tz_offset == t2.tz_offset
Base.hash(ts::Timestamp) = 1 + hash(ts.date) + hash(ts.time)
Base.hash(ts::TimestampTZ) = 2 + hash(ts.ts) + hash(ts.tz_offset)
Base.hash(o::TimeZoneOffset) = 4 + hash(o.hour) + hash(o.minute)

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
