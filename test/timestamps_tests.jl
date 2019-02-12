
import Oracle
import Oracle.Timestamps

if VERSION < v"0.7-"
    using Base.Test
    using Missings
    using Base.Dates
else
    using Test
    using Dates
end

@testset "Timestamps" begin

    @testset "Timestamp" begin
        ts = Timestamps.Timestamp(2018, 12, 31, 23, 58, 59, 999_200_300)

        @test year(ts) == 2018
        @test month(ts) == 12
        @test day(ts) == 31
        @test hour(ts) == 23
        @test minute(ts) == 58
        @test second(ts) == 59
        @test millisecond(ts) == 999
        @test microsecond(ts) == 200
        @test nanosecond(ts) == 300
    end

    @testset "TimestampTZ" begin
        @test_throws AssertionError Timestamps.TimestampTZ(false, 2018, 12, 31, 23, 58, 59, 999_200_300, -3, 30)

        ts = Timestamps.TimestampTZ(false, 2018, 12, 31, 23, 58, 59, 999_200_300, -3, -30)
        @test Timestamps.is_ltz(ts) == false
        @test year(ts) == 2018
        @test month(ts) == 12
        @test day(ts) == 31
        @test hour(ts) == 23
        @test minute(ts) == 58
        @test second(ts) == 59
        @test millisecond(ts) == 999
        @test microsecond(ts) == 200
        @test nanosecond(ts) == 300
    end

    @testset "TimestampLTZ" begin
        ts = Timestamps.TimestampTZ(true, 2018, 12, 31, 23, 58, 59, 999_200_300, -3, -30)
        @test Timestamps.is_ltz(ts) == true
        @test year(ts) == 2018
        @test month(ts) == 12
        @test day(ts) == 31
        @test hour(ts) == 23
        @test minute(ts) == 58
        @test second(ts) == 59
        @test millisecond(ts) == 999
        @test microsecond(ts) == 200
        @test nanosecond(ts) == 300
    end

    @testset "OraTimestamp" begin
        @testset "Constructors" begin
            ora_ts = Oracle.OraTimestamp(Timestamps.Timestamp(2018, 12, 31, 23, 58, 59, 999_200_300))
            @test ora_ts.year == 2018
            @test ora_ts.month == 12
            @test ora_ts.day == 31
            @test ora_ts.hour == 23
            @test ora_ts.minute == 58
            @test ora_ts.second == 59
            @test ora_ts.fsecond == 999_200_300

            ora_ts_tz = Oracle.OraTimestamp(Timestamps.TimestampTZ(false, 2018, 12, 31, 23, 58, 59, 999_200_400, -3, -30))
            @test ora_ts_tz.year == 2018
            @test ora_ts_tz.month == 12
            @test ora_ts_tz.day == 31
            @test ora_ts_tz.hour == 23
            @test ora_ts_tz.minute == 58
            @test ora_ts_tz.second == 59
            @test ora_ts_tz.fsecond == 999_200_400
            @test ora_ts_tz.tzHourOffset == -3
            @test ora_ts_tz.tzMinuteOffset == -30
        end

        @testset "ts Conversion" begin
            ts = Timestamps.Timestamp(2018, 12, 31, 23, 58, 59, 999_200_300)
            @test Oracle.parse_timestamp(Oracle.OraTimestamp(ts)) == ts
        end

        @testset "DateTime comparison" begin
            dt = now()
            ts = Timestamps.Timestamp(dt)
            @test ts == dt
            @test dt == ts
        end
    end
end
