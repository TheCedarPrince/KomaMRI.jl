# TODO: Consider different Extrapolations apart from periodic LinerInterpolator{T,ETPType}
#       Interpolator{T,Degree,ETPType}, 
#           Degree = Linear,Cubic.... 
#           ETPType = Periodic, Flat...
const LinearInterpolator = Interpolations.Extrapolation{T, 1, Interpolations.GriddedInterpolation{T, 1, V, Gridded{Linear{Throw{OnGrid}}}, Tuple{V}}, Gridded{Linear{Throw{OnGrid}}}, Periodic{Nothing}} where {T<:Real, V<:AbstractVector{T}}

mutable struct ArbitraryMotion{T<:Real, V<:AbstractVector{T}} <: MotionModel
	ux::Vector{LinearInterpolator{T, V}}
    uy::Vector{LinearInterpolator{T, V}}
    uz::Vector{LinearInterpolator{T, V}}
end

# TODO:
# mutable struct ArbitraryMotion{T<:Real} <: MotionModel
#     dur::AbstractVector{T}
#     Δx::AbstractArray{T, 2}
#     Δy::AbstractArray{T, 2}
#     Δz::AbstractArray{T, 2}
# end

# Optimize: ver https://github.com/cncastillo/KomaMRI.jl/issues/73
# t0 = [0; cumsum(dur)] 
# time = repeat(.., [1, length(dur)])
# time = time .+ t0'
# time = time[:]

function ArbitraryMotion( dur::AbstractVector{T},
                          Δx::AbstractArray{T, 2},
                          Δy::AbstractArray{T, 2},
                          Δz::AbstractArray{T, 2}) where {T<:Real}

    Ns = size(Δx)[1]
    K = size(Δx)[2] + 1
    limits = get_pieces_limits(dur,K)

    Δ = zeros(Ns,length(limits),4)
    Δ[:,:,1] = hcat(repeat(hcat(zeros(Ns,1),Δx),1,length(dur)),zeros(Ns,1))
    Δ[:,:,2] = hcat(repeat(hcat(zeros(Ns,1),Δy),1,length(dur)),zeros(Ns,1))
    Δ[:,:,3] = hcat(repeat(hcat(zeros(Ns,1),Δz),1,length(dur)),zeros(Ns,1))

    etpx = [extrapolate(interpolate((limits,), Δ[i,:,1], Gridded(Linear())), Periodic()) for i in 1:Ns]
    etpy = [extrapolate(interpolate((limits,), Δ[i,:,2], Gridded(Linear())), Periodic()) for i in 1:Ns]
    etpz = [extrapolate(interpolate((limits,), Δ[i,:,3], Gridded(Linear())), Periodic()) for i in 1:Ns]

    return ArbitraryMotion(etpx,etpy,etpz)
end


"""
    limits = get_pieces_limits(obj.motion)

Returns the pieces limits from dur and K values

Example: -----------------------------
    motion.dur = [1, 0.5]
    motion.K = 4

    limits = [0, 0.25, 0.5, 0.75, 1, 1.125, 1.25, 1.375, 1.5]
--------------------------------------
"""
# Revise this function to make it more efficient
function get_pieces_limits(dur::AbstractVector, K::Int)
	steps = dur/K
	mat = reduce(hcat,[steps for i in 1:K])'
	limits = reshape(mat,(K*length(dur),))
	cumsum!(limits,limits)
	limits = vcat(0,limits)
    limits
end

Base.getindex(motion::ArbitraryMotion, p::Union{AbstractRange,AbstractVector,Colon}) = begin
    return ArbitraryMotion(
        motion.ux[p],
        motion.uy[p],
        motion.uz[p]
    )
end

# TODO: Calculate interpolation functions "on the fly"
function displacement_x(motion::ArbitraryMotion{T}, x::AbstractVector{T}, y::AbstractVector{T}, z::AbstractVector{T}, t::AbstractArray{T}) where {T<:Real}
    return reduce(vcat, [etp.(t) for etp in motion.ux])
end

function displacement_y(motion::ArbitraryMotion{T}, x::AbstractVector{T}, y::AbstractVector{T}, z::AbstractVector{T}, t::AbstractArray{T}) where {T<:Real}
    return reduce(vcat, [etp.(t) for etp in motion.uy])
end

function displacement_z(motion::ArbitraryMotion{T}, x::AbstractVector{T}, y::AbstractVector{T}, z::AbstractVector{T}, t::AbstractArray{T}) where {T<:Real}
    return reduce(vcat, [etp.(t) for etp in motion.uz])
end



