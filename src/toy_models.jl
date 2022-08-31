
"""
solid_body_rotation(np,nz)

Set up an idealized flow field which consists of 
[rigid body rotation](https://en.wikipedia.org/wiki/Rigid_body), 
plus a convergent term, plus a sinking term.

```
u,v,w=solid_body_rotation(12,4)
```
"""
function solid_body_rotation(np,nz)
    Γ=simple_periodic_domain(np)
    Γ = UnitGrid(Γ.XC.grid;option="full")
    γ=Γ.XC.grid;

    #Solid-body rotation around central location ...
    i=Int(np/2+1)
    u=-(Γ.YG.-Γ.YG[1][i,i])
    v=(Γ.XG.-Γ.XG[1][i,i])

    #... plus a convergent term to / from central location
    d=-0.01
    u=u+d*(Γ.XG.-Γ.XG[1][i,i])
    v=v+d*(Γ.YG.-Γ.YG[1][i,i])

    #Replicate u,v in vertical dimension
    uu=MeshArray(γ,γ.ioPrec,nz)
    [uu[k]=u[1] for k=1:nz]
    vv=MeshArray(γ,γ.ioPrec,nz)
    [vv[k]=v[1] for k=1:nz]

    #Vertical velocity component w    
    w=fill(-0.01,MeshArray(γ,γ.ioPrec,nz+1))

    return write(uu),write(vv),write(w)
end

"""
    random_flow_field(option::String;np=12,nq=18)

Generate random flow fields on a grid of `np x nq` points for use in simple examples.

The "Rotational Component" option is most similar to what is done 
in the standard example.

The other option, "Divergent Component", generates a purely divergent flow field instead.

```
(U,V,Φ)=random_flow_field("Rotational Component";np=2*nx,nq=nx)
F=convert_to_FlowFields(U,V,10.0)
I=Individuals(F,x,y,fill(1,length(x)))
```
"""
function random_flow_field(option::String;np=12,nq=18)

	#define gridded domain
	Γ=MeshArrays.simple_periodic_domain(np,nq)
	γ=Γ.XC.grid
	Γ=MeshArrays.UnitGrid(γ;option="full")

    #initialize 2D field of random numbers
    tmp1=randn(Float64,Tuple(γ.ioSize))
    ϕ=γ.read(tmp1,MeshArrays.MeshArray(γ,Float64))

    #apply smoother
    ϕ=MeshArrays.smooth(ϕ,3*Γ.DXC,3*Γ.DYC,Γ);

	#derive flow field
	if option=="Divergent Component"
		#For the convergent / scalar potential case, ϕ is interpreted as being 
		#on center points -- hence the standard gradient function readily gives 
		#what we need
		(u,v)=MeshArrays.gradient(ϕ,Γ) 
		tmp=(u[1],v[1],ϕ[1])
	elseif option=="Rotational Component"
		#For the rotational / streamfunction case, ϕ is interpreted as being 
		#on S/W corner points -- this is ok here since the grid is homegeneous, 
		#and conveniently yields an adequate substitution u,v <- -v,u; but note
		#that doing the same with gradient() would shift indices inconsistenly
		u=-(circshift(ϕ[1], (0,-1))-ϕ[1])
		v=(circshift(ϕ[1], (-1,0))-ϕ[1])
		tmp=(u,v,ϕ[1])
	else
		error("non-recognized option")
	end
	return tmp[1],tmp[2],tmp[3]
end