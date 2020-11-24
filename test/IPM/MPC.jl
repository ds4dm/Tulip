function run_tests_mpc(T::Type)

    Tv = Vector{T}

    params = TLP.IPMOptions{T}()
    kkt_options = TLP.KKTOptions{T}()

    @testset "step length" begin
        m, n, p = 2, 2, 1
        pt = TLP.Point{T, Tv}(m, n, p, hflag=false)
        pt.x  .= one(T)
        pt.xl .= one(T)
        pt.xu .= one(T)
        pt.y  .= zero(T)
        pt.zl .= zero(T)
        pt.zu .= zero(T)
        pt.τ   = one(T)
        pt.κ   = one(T)
        pt.μ   = one(T)

        d = TLP.Point{T, Tv}(m, n, p, hflag=false)
        d.x  .= one(T)
        d.xl .= one(T)
        d.xu .= one(T)
        d.y  .= zero(T)
        d.zl .= zero(T)
        d.zu .= zero(T)
        d.τ   = one(T)
        d.κ   = one(T)
        d.μ   = one(T)

        # Max step length for a single (x, d)
        @inferred TLP.max_step_length(pt.x, d.x)
        @test TLP.max_step_length(ones(T, 1), ones(T, 1)) == T(Inf)
        @test TLP.max_step_length(ones(T, 1), -ones(T, 1)) ≈ one(T)
        @test TLP.max_step_length(zeros(T, 1), -ones(T, 1)) ≈ zero(T)
        @test TLP.max_step_length(zeros(T, 1), ones(T, 1)) == T(Inf)

        # Max step length for the whole primal-dual point
        @inferred TLP.max_step_length(pt, d)
        @test TLP.max_step_length(pt, d) ≈ one(T)
    end

    # Simple example:
    #=
        min     x1 - x2
        s.τ.    x1 + x2 = 1
                x1 - x2 = 0
                0 <= x1 <= 2
                0 <= x2 <= 2
    =#
    m, n = 2, 2
    p = 2 * n
    A = Matrix{T}([
        [1    1];
        [1   -1]
    ])
    b = Vector{T}([1,  0])
    c = Vector{T}([1, -1])
    c0 = zero(T)
    l = Vector{T}([0, 0])
    u = Vector{T}([2, 2])
    dat = Tulip.IPMData(A, b, true, c, c0, l, u)

    ipm = TLP.MPC(dat, kkt_options)

    # Primal-dual optimal solution
    # x1 = x2 = 0.5; xl = 0.5; xu = 1.5; τ = 1
    # y1 = 0, y2 = 1; zl = zu = 0; κ = 0
    ipm.pt.x  .= T.([1 // 2, 1 // 2])
    ipm.pt.xl .= T.([1 // 2, 1 // 2])
    ipm.pt.xu .= T.([3 // 2, 3 // 2])
    ipm.pt.y  .= T.([0, 1])
    ipm.pt.zl .= T.([0, 0])
    ipm.pt.zu .= T.([0, 0])
    
    ipm.pt.τ  = 1
    ipm.pt.κ  = 0
    ipm.pt.μ  = 0

    ϵ = sqrt(eps(T))

    @testset "Residuals" begin
        @inferred TLP.compute_residuals!(ipm)
        TLP.compute_residuals!(ipm)
        
        @test isapprox(ipm.res.rp_nrm, zero(T); atol=ϵ, rtol=ϵ)
        @test isapprox(ipm.res.ru_nrm, zero(T); atol=ϵ, rtol=ϵ)
        @test isapprox(ipm.res.rd_nrm, zero(T); atol=ϵ, rtol=ϵ)
        @test isapprox(ipm.res.rg_nrm, zero(T); atol=ϵ, rtol=ϵ)
        
    end

    @testset "Convergence" begin

    ipm.solver_status = TLP.Trm_Unknown
        TLP.update_solver_status!(ipm, ϵ, ϵ, ϵ, ϵ)
        @test ipm.solver_status == TLP.Trm_Optimal

        # TODO: dual infeasible

        # TODO: primal infeasible

        # TODO: ill-posed

    end
end

@testset "MPC" begin
    for T in TvTYPES
        @testset "$T" begin run_tests_mpc(T) end
    end
end