using Test
using Dates
using FileFormatHelper
using FileFormatHelper: roundtrip

#-----------------------------------------------------------------------------# Test Structs
@iodef struct T1
    a::UInt8
end
t1 = T1(1)

@iodef struct T2 <: AbstractString
    len::UInt8
    data::String = String(read(io, len))
end
t2 = T2(3, "abc")

@iodef struct T3
    t1::T1
    t2::T2
end
t3 = T3(t1, t2)

#-----------------------------------------------------------------------------# Tests
@testset "roundtrips" begin
    for t in [t1, t2, t3]
        @test roundtrip(t) == t
    end
end
