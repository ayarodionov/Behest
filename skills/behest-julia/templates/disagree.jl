# Disagreement check (scratch file: never commit, never approve).
# NOT RUN where this template was written (no Julia available): run it first.
#
# Put the real implementation and the alternative in scope, then:
#     julia --project scratch/disagree.jl
# Each input where they differ is a missing example for the contract: show the
# human both answers and ask which is right.
# behest-effects: none
using Random

# include("../src/Median.jl"); using .Median
# include("alt_median.jl")                 # defines alt_median(xs); must pass the contract first

real(xs) = try median(copy(xs)) catch e; e end   # a thrown error counts as an answer
alt(xs)  = try alt_median(copy(xs)) catch e; e end

same(a, b) = (a isa Exception && b isa Exception && typeof(a) == typeof(b)) || isequal(a, b)
disagree(xs) = !same(real(xs), alt(xs))

# Simplest failing input: drop elements, then halve and round values, while it still disagrees.
function shrink(xs)
    changed = true
    while changed
        changed = false
        for i in eachindex(xs)
            ys = xs[[j for j in eachindex(xs) if j != i]]
            if disagree(ys); xs = ys; changed = true; break; end
        end
        changed && continue
        for i in eachindex(xs)
            for v in (0.0, round(xs[i] / 2))
                v == xs[i] && continue
                ys = copy(xs); ys[i] = v
                if disagree(ys); xs = ys; changed = true; break; end
            end
            changed && break
        end
    end
    return xs
end

function run(n = 1000; seed = 1)
    rng = MersenneTwister(seed)
    for _ in 1:n
        xs = rand(rng, -5.0:1.0:5.0, rand(rng, 0:8))      # small values: ties and zeros show up
        if disagree(xs)
            s = shrink(xs)
            println("DISAGREE on ", s, "\n  real = ", real(s), "\n  alt  = ", alt(s))
            return s
        end
    end
    println("no disagreement in $n runs")
    return nothing
end

run()
