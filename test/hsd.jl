using SparseArrays
using LinearAlgebra
using Random

function test_augmented_system(A, F, θ, θxs, θwz, uind, ξp, ξd, ξu)

    dx = zeros(length(ξd))
    dy = zeros(length(ξp))
    dz = zeros(length(ξu))

    # Solve augmented system
    Tulip.solve_augsys_hsd!(A, F, θ, θwz, uind, dx, dy, dz, ξp, ξd, ξu)

    # println("dx  = $dx")
    # println("dy  = $dy")
    # println("dz  = $dz")

    # dx_, dy_, dz_ = Tulip.solve_augmented_system_hsd(A, F, θ, θwz, uind, ξp, ξd, ξu)
    # println("dx_ = $dx_")
    # println("dy_ = $dy_")
    # println("dz_ = $dz_")

    # Compute residuals
    rp = A*dx .- ξp

    dz_ = zeros(length(ξd))
    dz_[uind] .= dz
    rd = - θxs .* dx .+ transpose(A)*dy .- dz_ .- ξd

    ru = dx[uind] .- θwz .\ dz - ξu

    # Check numerics
    @test norm(rp, Inf) <= 1e-12
    @test norm(rd, Inf) <= 1e-12
    @test norm(ru, Inf) <= 1e-12

    return nothing
end

function test_newton_system(
    A, F, b, c, uind, uval, θ, θwz,
    p, q, r, ρ,
    x, w, y, s, z, t, k,
    ξp, ξd, ξu, ξg, ξxs, ξwz, ξtk
)

    dx = zeros(length(ξd))
    dw = zeros(length(ξu))
    dy = zeros(length(ξp))
    ds = zeros(length(ξd))
    dz = zeros(length(ξu))
    dt = Ref(0.0)
    dk = Ref(0.0)

    # Solve augmented system
    Tulip.solve_newton_hsd!(
        A, F, b, c, uind, uval, θ, θwz,
        p, q, r, ρ,
        x, w, y, s, z, t, k,
        dx, dw, dy, ds, dz, dt, dk,
        ξp, ξu, ξd, ξg, ξxs, ξwz, ξtk
    )

    # dx_, dw_, dy_, ds_, dz_, dt_, dk_ = Tulip.solve_newton_hsd(
    #     A, F, b, c, uval, uind, θ, θwz,
    #     x, w, y, s, z, t, k,
    #     ξp, ξu, ξd, ξg, ξxs, ξwz, ξtk
    # )

    # println("dx  = $dx")
    # println("dw  = $dw")
    # println("dy  = $dy")
    # println("ds  = $ds")
    # println("dz  = $dz")
    # println("dt  = $dt")
    # println("dk  = $dk")

    # println("dx_  = $dx_")
    # println("dw_  = $dw_")
    # println("dy_  = $dy_")
    # println("ds_  = $ds_")
    # println("dz_  = $dz_")
    # println("dt_  = $dt_")
    # println("dk_  = $dk_")

    return nothing
end

function test_step_length()
    @test Tulip.max_step_length([1.0], [1.0]) == Inf
    @test Tulip.max_step_length([1.0], [-2.0]) == 0.5
    @test try
        # This should raise a DimensionMismatch
        Tulip.max_step_length([1.0, 1.0], [1.0])
        false
    catch err
        isa(err, DimensionMismatch)
    end
    return nothing
end

m, n = 2, 3
Random.seed!(0)
A = sparse(rand(m, n))
uind = [2]
uval = [4.0]

x = rand(n)
w = rand(1)
y = rand(m)
s = rand(n)
z = rand(1)
t = Ref(1.0)
k = Ref(1.0)


θwz = w ./ z
θ = s ./ x
θxs = copy(θ)
θ[uind] .+= θwz
θ .\= 1.0

F = cholesky(Symmetric(A*Diagonal(θ)*A'))

ξp = rand(m)
ξd = rand(n)
ξu = rand(1)
ξg = rand()
ξxs = rand(n)
ξwz = rand(1)
ξtk = rand()

test_augmented_system(A, F, θ, θxs, θwz, uind, ξp, ξd, ξu)

p = zeros(n)
q = zeros(m)
r = zeros(1)
b = rand(m)
c = rand(n)

Tulip.solve_augsys_hsd!(
    A, F, θ, θwz, uind,
    p, q, r,
    b, c, uval
)
ρ = (k.x / t.x) - dot(c, p) + dot(b, q) - dot(uval, r)

test_newton_system(
    A, F, b, c, uind, uval, θ, θwz,
    p, q, r, ρ,
    x, w, y, s, z, t, k,
    ξp, ξd, ξu, ξg, ξxs, ξwz, ξtk
)