
import Oracle
import Oracle.OraNumbers

if VERSION < v"0.7-"
    using Base.Test
else
    using Test
end

@testset "OraNumbers" begin
    @testset "basic numbers" begin
        z = zero(OraNumbers.OraNumber)
        o = one(OraNumbers.OraNumber)

        @test string(z) == "0"
        @test string(o) == "1"
        @test string(OraNumbers.OraNumber(nothing)) == "nothing"
    end

    @testset "comparison" begin
        z = zero(OraNumbers.OraNumber)
        o = one(OraNumbers.OraNumber)

        @test z == z
        @test o == o
        @test z != o
    end

    @testset "normalize" begin
        normalized_one = one(OraNumbers.OraNumber)
        non_normalized_one = OraNumbers.inc_exponent(normalized_one, 2)
        @test OraNumbers.isnormalized(normalized_one) == true
        @test OraNumbers.isnormalized(non_normalized_one) == false
        new_one = OraNumbers.normalize(non_normalized_one)
        @test OraNumbers.isnormalized(new_one)
        @test new_one == normalized_one
    end

    @testset "arithmetic" begin
        z = zero(OraNumbers.OraNumber)
        o = one(OraNumbers.OraNumber)

        @test z == -z
        @test z == -(-z)
        @test o == -(-o)

        @test string(-z) == "0"
        @test string(-o) == "-1"
    end
end
