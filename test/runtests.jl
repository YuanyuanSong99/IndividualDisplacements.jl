using Test, Documenter
using IndividualDisplacements, Climatology, MeshArrays, NetCDF

Climatology.get_ecco_velocity_if_needed()
Climatology.get_occa_velocity_if_needed()
Climatology.get_ecco_variable_if_needed("THETA")
Climatology.get_ecco_variable_if_needed("SALT")

MeshArrays.GridLoad(MeshArrays.GridSpec("LatLonCap",MeshArrays.GRID_LLC90))
MeshArrays.GridLoad(MeshArrays.GridSpec("PeriodicChannel",MeshArrays.GRID_LL360))

@testset "downloads" begin
    p0=IndividualDisplacements.datadeps.getdata("global_ocean_circulation_inputs")
    IndividualDisplacements.datadeps.getdata("flt_example")
    @test ispath(p0)
end

@testset "global" begin
    p0=IndividualDisplacements.datadeps.getdata("global_ocean_circulation_inputs")
    p1=dirname(pathof(IndividualDisplacements))
    include(joinpath(p1,"../examples/worldwide/ECCO_FlowFields.jl"))
    P,D=ECCO_FlowFields.init_FlowFields()
    file_input=joinpath(p0,"initial_10_1.csv")
    df = ECCO_FlowFields.init_positions(10,filename=file_input)
    I=Individuals(P,df.x,df.y,df.f,(D=D,))
    T=(0.0,I.P.T[2])
    ∫!(I,T)

    add_lonlat!(I.🔴,D.XC,D.YC)
    add_lonlat!(I.🔴,D.XC,D.YC,P.update_location!)
    tmp=interp_to_xy(I.🔴,D.YC)
    gcdist(I)

    @test prod(abs.(tmp).<90.0)

    tmp1=randn_lonlat(10)
    tmp2=stproj_inv(stproj(30.0,30.0)...)
    @test prod(isapprox.(tmp2,30.0,atol=1.0))
end

@testset "various" begin
    u,v,w,pos=random_flow_field(format=:Array)
    F=FlowFields(u,u,v,v,[0,1.0])
    I=Individuals(F,pos...)
    ∫!(I)
    
    show(I)
    diff(I)
    size(I)
    J=similar(I)
    @test isa(J,Individuals)

    𝐺=convert_to_FlowFields(u,v,10.0)
    tmp2=nearest_to_xy(𝐺.u0,3.,3.,1.)
    @test isa(tmp2,Array)
    tmp3=nearest_to_xy(F.u0,3.,3.)
    @test isa(tmp3,Array)
end

@testset "doctests" begin
    doctest(IndividualDisplacements; manual = false)
end
