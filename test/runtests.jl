using Test

using LinearAlgebra
using SparseArrays

using Tulip
TLP = Tulip

import Convex

const TvTYPES = [Float64, BigFloat]

# write your own tests here
const testdir = dirname(@__FILE__)


@testset "Unit tests" begin
    include("Core/problemData.jl")
    include("Solvers/HSD.jl")
end

@testset "KKT" begin
    include("KKTSolver/KKTSolver.jl")
end

@testset "Presolve" begin
    include("Presolve/presolve.jl")
end

@testset "Examples" begin
    include("examples.jl")
end

@testset "Interfaces" begin
    include("Interfaces/MOI_wrapper.jl")
end

@testset "Convex Problem Depot tests" begin
    for T in TvTYPES
        @testset "$T" begin
            Convex.ProblemDepot.run_tests(;  exclude=[r"mip", r"exp", r"socp", r"sdp"], T = T) do problem
                Convex.solve!(problem, () -> Tulip.Optimizer{T}())
            end
        end
    end
end