using OrdinaryDiffEq, DiffEqDevTools, DiffEqBase, Base.Test, ODEInterfaceDiffEq

const linear_bigα5 = parse(BigFloat,"1.01")
f = (u,p,t) -> (linear_bigα5*u)
(::typeof(f))(::Type{Val{:analytic}},u0,p,t) = u0*exp(linear_bigα5*t)
prob_ode_bigfloatlinear = ODEProblem(f,parse(BigFloat,"0.5"),(0.0,10.0))

f = (du,u,p,t) -> begin
  for i in 1:length(u)
    du[i] = linear_bigα5*u[i]
  end
end
(::typeof(f))(::Type{Val{:analytic}},u0,p,t) = u0*exp(linear_bigα5*t)
probbig = ODEProblem(f,map(BigFloat,rand(4,2)).*ones(4,2)/2,(0.0,10.0))

linear = (u,p,t) -> (1.01*u)
(::typeof(linear))(::Type{Val{:analytic}},u0,p,t) = u0*exp(1.01*t)
probnum = ODEProblem(linear,1/2,(0.0,10.0))

probnumbig = prob_ode_bigfloatlinear
#prob    = prob_ode_large2Dlinear


f_2dlinear = (du,u,p,t) -> begin
  for i in 1:length(u)
    du[i] = 1.01*u[i]
  end
end
(::typeof(f_2dlinear))(::Type{Val{:analytic}},u0,p,t) = u0*exp.(1.01*t)
prob = ODEProblem(f_2dlinear,rand(4,2),(0.0,10.0))

dts = 1.//2.^(7:-1:4)
testTol = .2
bools = Vector{Bool}(0)

## DP5()
sim = test_convergence(dts,probnum,DP5())
@test abs.(sim.𝒪est[:l2]-5) < testTol
sim = test_convergence(dts,prob,DP5())
@test abs.(sim.𝒪est[:l2]-5) < testTol

tabalg = ExplicitRK()
sol1 =solve(probnum,DP5(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnum,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(prob,DP5(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(prob,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 3e-10)

sol1 =solve(probnum,DP5(),dt=1/2^6,beta2=0.04)
sol2 =solve(probnum,tabalg,dt=1/2^6,beta2=0.04)


# Should be identical
sol1 =solve(probnum,DP5())
sol2 =solve(probnum,tabalg,beta2=0.04,beta1=0.17)
sol3 =solve(probnum,dopri5())

@test sol1.t ≈ sol2.t ≈ sol3.t

sol1 =solve(prob,DP5(),dt=1/8)
sol2 =solve(prob,tabalg,beta2=0.04,beta1=0.17,dt=1/8)
sol3 =solve(prob,dopri5(),dt=1/8)

@test sol1.t ≈ sol2.t ≈ sol3.t

sol4 =solve(prob,DP5(),dt=1/8,calck=false)

@test sol1.t == sol4.t

### BS3()
sim = test_convergence(dts,probnum,BS3())
@test abs.(sim.𝒪est[:l2]-3) < testTol
sim = test_convergence(dts,prob,BS3())
@test abs.(sim.𝒪est[:l2]-3) < testTol

tabalg = ExplicitRK(tableau=constructBogakiShampine3())
sol1 =solve(probnum,BS3(),dt=1/2^1,adaptive=false,save_everystep=false)
sol2 =solve(probnum,tabalg,dt=1/2^1,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(prob,BS3(),dt=1/2^1,adaptive=false,save_everystep=false)
sol2 =solve(prob,tabalg,dt=1/2^1,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,BS3(),dt=1/2^6)

@test length(sol1) == length(sol2)

### BS5()
dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,BS5())
@test abs.(sim.𝒪est[:l2]-5) < testTol
sim = test_convergence(dts,probbig,BS5())
@test abs.(sim.𝒪est[:l2]-5) < testTol

tabalg = ExplicitRK(tableau=constructBogakiShampine5())
sol1 =solve(probnum,BS5(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnum,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(prob,BS5(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(prob,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,BS5(),dt=1/2^6)

@test length(sol1) <= length(sol2) # Dual error estimators is more strict

### Tsit5()

dts = 1.//2.^(7:-1:3)
sim = test_convergence(dts,probnum,Tsit5())
@test abs.(sim.𝒪est[:l2]-5) < testTol+.1
sim = test_convergence(dts,prob,Tsit5())
@test abs.(sim.𝒪est[:l2]-5) < testTol+.1

tabalg = ExplicitRK(tableau=constructTsitouras5())
sol1 =solve(probnum,Tsit5(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnum,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(prob,Tsit5(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(prob,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,Tsit5(),dt=1/2^6)

@test length(sol1) == length(sol2)

### Vern6()

dts = 1.//2.^(8:-1:5)
sim = test_convergence(dts,probnumbig,Vern6())
@test abs.(sim.𝒪est[:l2]-6) < testTol
sim = test_convergence(dts,probbig,Vern6())
@test abs.(sim.𝒪est[:l2]-6) < testTol

tabalg = ExplicitRK(tableau=constructVernerEfficient6(BigFloat))
sol1 =solve(probnumbig,Vern6(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnumbig,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(probbig,Vern6(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(probbig,tabalg,dt=1/2^6)
sol2 =solve(probbig,Vern6(),dt=1/2^6)

@test length(sol1) == length(sol2)

### Vern7()

dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,Vern7(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-7) < testTol
sim = test_convergence(dts,probbig,Vern7(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-7) < testTol

tabalg = ExplicitRK(tableau=constructVerner7(BigFloat))
sol1 =solve(probnumbig,Vern7(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnumbig,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(probbig,Vern7(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(probbig,tabalg,dt=1/2^6)
sol2 =solve(probbig,Vern7(),dt=1/2^6)

@test length(sol1) == length(sol2)

### TanYam7()

dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,TanYam7())
@test abs.(sim.𝒪est[:l2]-7) < testTol
sim = test_convergence(dts,probbig,TanYam7())
@test abs.(sim.𝒪est[:l2]-7) < testTol

tabalg = ExplicitRK(tableau=constructTanakaYamashitaEfficient7(Float64))
sol1 =solve(probnum,TanYam7(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnum,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 2e-9

tabalg = ExplicitRK(tableau=constructTanakaYamashitaEfficient7(BigFloat))
sol1 =solve(probbig,TanYam7(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,TanYam7(),dt=1/2^6)

@test length(sol1) == length(sol2)

### Vern8()

dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,Vern8(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-8) < testTol
sim = test_convergence(dts,probbig,Vern8(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-8) < testTol

tabalg = ExplicitRK(tableau=constructVerner8(BigFloat))
sol1 =solve(probnumbig,Vern8(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnumbig,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(probbig,Vern8(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,Vern8(),dt=1/2^6)

@test length(sol1) == length(sol2)

### DP8()

dts = 1.//2.^(3:-1:1)
sim = test_convergence(dts,probnumbig,DP8())
@test abs.(sim.𝒪est[:l2]-8) < testTol
sim = test_convergence(dts,probbig,DP8())
@test abs.(sim.𝒪est[:l2]-8) < testTol

sol1 =solve(probnum,DP8(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnum,DP8(),dt=1/2^6)

# Should be identical
sol1 =solve(probnum,DP8())
sol2 =solve(probnum,dop853())

@test sol1.t ≈ sol2.t

# Should be identical
sol1 =solve(probbig,DP8(),dt=1/2^6)
sol2 =solve(probbig,dop853(),dt=1/2^6)

@test sol1.t ≈ sol2.t

### TsitPap8()

dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,TsitPap8())
@test abs.(sim.𝒪est[:l2]-8) < testTol
sim = test_convergence(dts,probbig,TsitPap8())
@test abs.(sim.𝒪est[:l2]-8) < testTol

tabalg = ExplicitRK(tableau=constructTsitourasPapakostas8(BigFloat))
sol1 =solve(probnumbig,TsitPap8(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnumbig,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test sol1.u[end] - sol2.u[end] < 1e-10

sol1 =solve(probbig,TsitPap8(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(sol1.u[end] - sol2.u[end] .< 1e-10)

sol1 =solve(prob,tabalg,dt=1/2^6)
sol2 =solve(prob,TsitPap8(),dt=1/2^6)

@test length(sol1) == length(sol2)

### Vern9()

dts = 1.//2.^(6:-1:3)
sim = test_convergence(dts,probnumbig,Vern9(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-9) < testTol
sim = test_convergence(dts,probbig,Vern9(),dense_errors=true)
@test abs.(sim.𝒪est[:l2]-9) < testTol


tabalg = ExplicitRK(tableau=constructVernerEfficient9(BigFloat))
sol1 =solve(probnumbig,Vern9(),dt=1/2^6,adaptive=false,save_everystep=false)
sol2 =solve(probnumbig,tabalg,dt=1/2^6,adaptive=false,save_everystep=false)

@test abs.(sol1.u[end] - sol2.u[end]) < 1e-15

sol1 =solve(probbig,Vern9(),dt=1/2^3,adaptive=false,save_everystep=false)
sol2 =solve(probbig,tabalg,dt=1/2^3,adaptive=false,save_everystep=false)

@test minimum(abs.(sol1.u[end] - sol2.u[end]) .< 1e-15)

sol1 =solve(probbig,tabalg,dt=1/2^6)
sol2 =solve(probbig,Vern9(),dt=1/2^6)

@test length(sol1) == length(sol2)
