import LDLFactorizations
const LDLF = LDLFactorizations

# ==============================================================================
#   LDLFact_SymQuasDef
# ==============================================================================

"""
    LDLFact_SymQuasDef{Tv}

Linear solver for the 2x2 augmented system with ``A`` sparse.

Uses LDLFactorizations.jl to compute an LDLᵀ factorization of the quasi-definite augmented system.

```julia
model.params.KKTOptions = Tulip.KKT.SolverOptions(LDLFact_SymQuasDef)
```
"""
mutable struct LDLFact_SymQuasDef{Tv<:Real} <: AbstractKKTSolver{Tv}
    m::Int  # Number of rows
    n::Int  # Number of columns

    # TODO: allow for user-provided ordering,
    #   and add flag (default to false) to know whether user ordering should be used

    # Problem data
    A::SparseMatrixCSC{Tv, Int}
    θ::Vector{Tv}
    regP::Vector{Tv}  # primal regularization
    regD::Vector{Tv}  # dual regularization

    # Factorization
    F::LDLF.LDLFactorization{Tv}

    # TODO: constructor with initial memory allocation
    function LDLFact_SymQuasDef(A::AbstractMatrix{Tv}) where{Tv<:Real}
        m, n = size(A)
        θ = ones(Tv, n)

        S = [
            spdiagm(0 => -θ)  A';
            A spdiagm(0 => ones(m))
        ]

        # TODO: PSD-ness checks
        F = LDLF.ldl(S)
        return new{Tv}(m, n, A, θ, ones(Tv, n), ones(Tv, m), F)
    end

end

setup(::Type{LDLFact_SymQuasDef}, A) = LDLFact_SymQuasDef(A)

backend(::LDLFact_SymQuasDef) = "LDLFactorizations.jl"
linear_system(::LDLFact_SymQuasDef) = "Augmented system"

"""
    update!(kkt, θ, regP, regD)

Update LDLᵀ factorization of the augmented system.

Update diagonal scaling ``\\theta``, primal-dual regularizations, and re-compute
    the factorization.
Throws a `PosDefException` if matrix is not quasi-definite.
"""
function update!(
    kkt::LDLFact_SymQuasDef{Tv},
    θ::AbstractVector{Tv},
    regP::AbstractVector{Tv},
    regD::AbstractVector{Tv}
) where{Tv<:Real}
    # Sanity checks
    length(θ)  == kkt.n || throw(DimensionMismatch(
        "θ has length $(length(θ)) but linear solver is for n=$(kkt.n)."
    ))
    length(regP) == kkt.n || throw(DimensionMismatch(
        "regP has length $(length(regP)) but linear solver has n=$(kkt.n)"
    ))
    length(regD) == kkt.m || throw(DimensionMismatch(
        "regD has length $(length(regD)) but linear solver has m=$(kkt.m)"
    ))

    # Update diagonal scaling
    kkt.θ .= θ
    # Update regularizers
    kkt.regP .= regP
    kkt.regD .= regD

    # Re-compute factorization
    # TODO: Keep S in memory, only change diagonal
    S = [
        spdiagm(0 => -kkt.θ .- regP)  kkt.A';
        kkt.A spdiagm(0 => regD)
    ]

    # TODO: PSD-ness checks
    try
        kkt.F = LDLF.ldl(S)
    catch err
        isa(err, LDLF.SQDException) && throw(PosDefException(-1))
        rethrow(err)
    end

    return nothing
end

"""
    solve!(dx, dy, kkt, ξp, ξd)

Solve the augmented system, overwriting `dx, dy` with the result.
"""
function solve!(
    dx::Vector{Tv}, dy::Vector{Tv},
    kkt::LDLFact_SymQuasDef{Tv},
    ξp::Vector{Tv}, ξd::Vector{Tv}
) where{Tv<:Real}
    m, n = kkt.m, kkt.n
    
    # Set-up right-hand side
    ξ = [ξd; ξp]

    # Solve augmented system
    d = kkt.F \ ξ

    # Recover dx, dy
    @views dx .= d[1:n]
    @views dy .= d[(n+1):(m+n)]

    # TODO: Iterative refinement
    return nothing
end
