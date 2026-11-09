# Disagreement check (scratch file: never commit, never approve).
# Run on a Mac by the author's user (Julia available there); the shrinker's pair removal is new and not yet re-run.
#
# Put the real implementation and the alternative in scope, then:
#     julia --project scratch/disagree.jl
# Each input where they differ is a missing example for the contract: show the
# human both answers and ask which is right.
# behest-effects: none
using Random

# include("../src/Median.jl"); using .Median
# include("alt_median.jl")                 # defines alt_median(xs); must pass the contract first

real_answer(xs) = try median(copy(xs)) catch e; e end   # a thrown error counts as an answer
alt_answer(xs)  = try alt_median(copy(xs)) catch e; e end

# Equal answers: same exception type, or equal values. `isequal` makes NaN equal to NaN,
# and the extra `==` makes 0.0 equal to -0.0 (isequal alone would call them different, and
# the shrinker, which can produce -0.0, would then drift to a signed-zero "disagreement").
same(a, b) = (a isa Exception && b isa Exception && typeof(a) == typeof(b)) ||
             isequal(a, b) || (a isa Number && b isa Number && a == b)
disagree(xs) = !same(real_answer(xs), alt_answer(xs))

# Simplest failing input: drop one or two elements, then halve and round values, while it still disagrees.
function shrink(xs)
    changed = true
    while changed
        changed = false
        for i in eachindex(xs)
            ys = xs[[j for j in eachindex(xs) if j != i]]
            if disagree(ys); xs = ys; changed = true; break; end
        end
        changed && continue
        # Also try removing two elements: removing one can flip odd/even length and hide a gap.
        for i in eachindex(xs), j in eachindex(xs)
            i < j || continue
            ys = xs[[k for k in eachindex(xs) if k != i && k != j]]
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

function main(n = 1000; seed = 1)
    rng = MersenneTwister(seed)
    for _ in 1:n
        xs = rand(rng, -5.0:1.0:5.0, rand(rng, 0:8))      # small values: ties and zeros show up
        if disagree(xs)
            s = shrink(xs)
            println("DISAGREE on ", s, "\n  real = ", real_answer(s), "\n  alt  = ", alt_answer(s))
            return s
        end
    end
    println("no disagreement in $n runs")
    return nothing
end

main()
