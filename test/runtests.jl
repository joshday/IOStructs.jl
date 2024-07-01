using Test
using IOStructs
using IOStructs: test_roundtrip

#-----------------------------------------------------------------------------# Test Structs
# Simple
@iodef struct T1
    a::UInt8
end
t1 = T1(1)

# Custom read
@iodef struct T2 <: AbstractString
    len::UInt8
    data::String = String(read(io, len))
end
t2 = T2(3, "abc")

# Nested
@iodef struct T3
    t1::T1
    t2::T2
end
t3 = T3(t1, t2)

# Custom read and write
@iodef struct T4
    n_records::UInt8
    record_length::UInt8
    b::Vector{String} = [
        [String(read(io, record_length)) for _ in 1:n_records],
        sum(write(io, x) for x in b)
    ]
end
t4 = T4(2, 3, ["abc", "def"])

#-----------------------------------------------------------------------------# Tests
@testset "roundtrips" begin
    for t in [t1, t2, t3, t4]
        @test test_roundtrip(t)
    end
end
