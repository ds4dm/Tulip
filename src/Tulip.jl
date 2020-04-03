module Tulip

using LinearAlgebra
using Logging
using Printf
using SparseArrays

# Linear algebra
include("LinearAlgebra/LinearAlgebra.jl")
import .TLPLinearAlgebra:
    construct_matrix,
    AbstractLinearSolver, update_linear_solver!, solve_augmented_system!
const TLA = TLPLinearAlgebra

# Core data structures
include("Core/problemData.jl")
include("Core/parameters.jl")
include("Core/status.jl")    # Termination and solution statuses
include("Core/attributes.jl")

# TODO: Presolve module

# IPM solvers
include("./Solvers/Solvers.jl")

# Model
include("./model.jl")

# Interfaces
include("Interfaces/tulip_julia_api.jl")
include("Interfaces/MOI/MOI_wrapper.jl")

end # module