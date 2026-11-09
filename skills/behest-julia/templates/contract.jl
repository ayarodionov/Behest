# behest-effects: none
#
# Contract for `median`. Approved by the human; do not edit to make a build pass.
# Run by a user: 6 examples, the empty-input test and 3000 property checks pass.
using Test
using Random

# include("../src/Median.jl"); using .Median   # adjust to your package

@testset "examples" begin
    @test median([3.0, 1.0, 2.0]) == 2.0     # odd length: the middle value
    @test median([1.0, 2.0]) == 1.5          # even length: mean of the middle two
    @test median([0.0, 0.0]) == 0.0
    @test median([5.0]) == 5.0
    @test median([0.0, -1.0]) == -0.5
    @test median([1, 2, 3]) isa Float64      # answer: the result is always a Float64
end

# Answer to an open question: an empty vector is an error, not a default.
@testset "empty input" begin
    @test_throws ArgumentError median(Float64[])
end

# Properties: random inputs from a seeded rng, so a failure can be replayed.
const RNG = MersenneTwister(20260101)
randvec(rng) = rand(rng, -1000.0:0.5:1000.0, rand(rng, 1:12))   # ties likely

@testset "properties" begin
    for _ in 1:1000
        xs = randvec(RNG)
        m = median(xs)
        # order does not matter
        @test m == median(shuffle(RNG, xs))
        # between min and max
        @test minimum(xs) <= m <= maximum(xs)
        # does not modify its input
        ys = copy(xs); median(ys); @test ys == xs
    end
end
