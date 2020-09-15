using Random, Plots, DataFrames, ColorSchemes

"""
    PlotBasic(df::DataFrame,nn::Integer,dMax::Float64=0.)

Plot random subset of size nn trajectories.
"""
function PlotBasic(df::DataFrame,nn::Integer,dMax::Float64=0.)
   IDs = randperm(maximum(df.ID))
   COs=["w" "y" "g" "k"]

   plt=plot(leg=false)
   df_by_ID = groupby(df, :ID)
   ID_list=[df_by_ID[i][1,:ID] for i in 1:length(df_by_ID)]
   for ii=1:nn
      jj=findall(ID_list.==IDs[ii])[1]
      tmp=df_by_ID[jj]
      if dMax > 0.
         d=abs.(diff(tmp[!,:lon]))
         jj=findall(d .> dMax)
         tmp[jj,:lon].=NaN; tmp[jj,:lat].=NaN
         d=abs.(diff(tmp[!,:lat]))
         jj=findall(d .> dMax)
         tmp[jj,:lon].=NaN; tmp[jj,:lat].=NaN
      end
      CO=COs[mod(ii,4)+1]
      
      hasproperty(df,:z) ? plot!(tmp[!,:lon],tmp[!,:lat],tmp[!,:z],linewidth=0.3) : nothing
      !hasproperty(df,:z) ? plot!(tmp[!,:lon],tmp[!,:lat],linewidth=0.3) : nothing
      #plot!(tmp[!,:lon],tmp[!,:lat],tmp[!,:z],linewidth=0.3)
   end
   return plt
end

"""
    scatter_subset(df,t)

```
nf=size(u0,2)
t=[ceil(i/nf) for i in 1:367*nf]
df[!,:t]=2000 .+ 10/365 * t

@gif for t in 2000:0.1:2016
   scatter_subset(df,t)
end
```
"""
function scatter_subset(df,t)
    dt=0.25
    df_t = df[ (df.t.>t-dt).&(df.t.<=t) , :]
    scatter(df_t.lon,df_t.lat,markersize=2,
    xlims=(-180.0,180.0),ylims=(-90.0,90.0))
end

"""
    scatter_zcolor(df,t,zc; plt=plot(),cam=(0, 90))

```
t=maximum(df[!,:t])
scatter_zcolor(df,t,df.z)
```
"""
function scatter_zcolor(df,t,zc; plt=plot(),cam=(0, 90), dt=1.0)
    lo=extrema(df.lon); lo=round.(lo).+(-5.0,5.0)
    la=extrema(df.lat); la=round.(la).+(-5.0,5.0)
    de=extrema(zc); de=round.(de).+(-5.0,5.0)

    df_t = df[ (df.t.>t-dt).&(df.t.<=t) , :]
    zc_t = Float64.(zc[ (df.t.>t-dt).&(df.t.<=t)])

    #fig=deepcopy(plt)
    scatter(df_t.lon,df_t.lat,zc_t,zcolor = zc_t,
    markersize=2,markerstrokewidth=0.1,camera = cam,
    xlims=lo,ylims=la,zlims=de,clims=de)
end

"""
    scatter_movie(𝐼; cam=(0, 90))

Animation using `scatter_zcolor()
```
𝐼,Γ=example3("OCCA", lon_rng=(-165.0,-155.0),lat_rng=(25.0,35.0), z_init=5.5,)
scatter_movie(𝐼,cam=(70, 70))
```
"""
function scatter_movie(𝐼; cam=(0, 90))
   df=𝐼.🔴
   nf=maximum(df.ID)
   nt=min(size(df,1)/nf,100)
   dt=maximum(df.t)/(nt-1)
   #println("nt="*"$nt"*"dt="*"$dt")
   return @gif for t in 0:nt-1
        scatter_zcolor(df,t*dt,df.z;cam=cam,dt=dt)
   end
end

"""
    phi_and_subset(Γ,ϕ,df,t,dt=5.0)

```
t=maximum(df[!,:t])
phi_and_subset(Γ,ϕ,df,t)
```
"""
function phi_and_subset(Γ,ϕ,df,t=missing,dt=5.0)
    ismissing(t) ? t=maximum(df[!,:t]) : nothing
    df_t = df[ (df.t.>t-dt).&(df.t.<=t) , :]
    nx,ny=size(ϕ[1])
    contourf(vec(Γ["XC"][1][:,1]),vec(Γ["YC"][1][1,:]),
        transpose(ϕ[1]),c = :blues,linewidth = 0.1)
    scatter!(df_t.x,df_t.y,markersize=2.0,c=:red,
    xlims=(0,nx),ylims=(0,ny),leg=:none,marker = (:circle, stroke(0)))
end

"""
    DL()

Compute Ocean depth logarithm.
"""
function DL()
    lon=[i for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    lat=[j for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    (f,i,j,w,_,_,_)=InterpolationFactors(𝐼.𝑃.Γ,vec(lon),vec(lat))
    DL=log10.(Interpolate(𝐼.𝑃.Γ["Depth"],f,i,j,w))
    DL[findall((!isfinite).(DL))].=NaN
    DL=transpose(reshape(DL,size(lon)));
    return lon[:,1],lat[1,:],DL
end

"""
    plot_end_points(𝐼::Individuals)

Plot initial and final positions, superimposed on a map of ocean depth log.
"""
function plot_end_points(𝐼::Individuals)
    plt=contourf(DL(),clims=(1.5,5),c = :ice, colorbar=false)

    t=𝑃.𝑇[2]
    df = 𝐼.🔴[ (𝐼.🔴.t.>t-1.0).&(𝐼.🔴.t.<=t) , :]
    scatter!(df.lon,df.lat,markersize=1.5,c=:red,leg=:none,
    xlims=(-180.0,180.0),ylims=(-90.0,90.0),marker = (:circle, stroke(0)))

    t=0.0
    df = 𝐼.🔴[ (𝐼.🔴.t.>t-1.0).&(𝐼.🔴.t.<=t) , :]
    scatter!(df.lon,df.lat,markersize=1.5,c=:yellow,leg=:none,
    xlims=(-180.0,180.0),ylims=(-90.0,90.0),marker = (:dot, stroke(0)))
    return plt
end
