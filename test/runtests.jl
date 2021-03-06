using Optimize
using NLPModels
using AmplNLReader
using OptimizationProblems
using Compat
import Compat.String

models = [AmplModel("dixmaanj.nl"), MathProgNLPModel(dixmaanj(), name="dixmaanj")]
@static if is_unix()
  using CUTEst
  push!(models, CUTEstModel("DIXMAANJ", "-param", "M=30"))
end
solvers = [trunk, lbfgs]

for model in models
  for solver in solvers
    stats = solve_problem(solver, model, verbose=false)
    assert(all([stats...] .>= 0))
    reset!(model)
  end
  finalize(model)
end

# test benchmark helpers, skip constrained problems (hs7 has constraints)
solve_problem(trunk, AmplModel("dixmaanj"), verbose=true, monotone=false)
probs = [dixmaane, dixmaanf, dixmaang, dixmaanh, dixmaani, dixmaanj, hs7]

# here we use array comprehension to pass on julia 0.4
# a generator should be used on julia ≥ 0.5
models = [MathProgNLPModel(p(99), name=string(p)) for p in probs]
stats = bmark_solvers(solvers, models, skipif=m -> m.meta.ncon > 0)
println(stats)
println(size(stats[Symbol(solvers[1])], 1))
println(length(probs))
assert(size(stats[Symbol(solvers[1])], 1) == length(probs) - 1)
stats = bmark_solvers(solvers, models, skipif=m -> m.meta.ncon > 0, prune=false)
assert(size(stats[Symbol(solvers[1])], 1) == length(probs))
