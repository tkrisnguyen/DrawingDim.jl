abstract type AbstractDimension end

struct LinearDimension <: AbstractDimension
    p1::Point2D
    p2::Point2D
    ext1::Point2D
    ext2::Point2D
    dim1::Point2D
    dim2::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct AlignedDimension <: AbstractDimension
    p1::Point2D
    p2::Point2D
    ext1::Point2D
    ext2::Point2D
    dim1::Point2D
    dim2::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct AngularDimension <: AbstractDimension
    vertex::Point2D
    p1::Point2D
    p2::Point2D
    radius::Float64
    θ1::Float64
    θ2::Float64
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct ArcDimension <: AbstractDimension
    center::Point2D
    p1::Point2D
    p2::Point2D
    radius::Float64
    θ1::Float64
    θ2::Float64
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct CenterDimension <: AbstractDimension
    center::Point2D
    h1::Point2D
    h2::Point2D
    v1::Point2D
    v2::Point2D
    style::DimStyle
end

struct JoggedDimension <: AbstractDimension
    p1::Point2D
    p2::Point2D
    ext1::Point2D
    ext2::Point2D
    dim1::Point2D
    jog1::Point2D
    jog_apex::Point2D
    jog2::Point2D
    dim2::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct RadialDimension <: AbstractDimension
    center::Point2D
    point::Point2D
    leader_end::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct DiameterDimension <: AbstractDimension
    center::Point2D
    p1::Point2D
    p2::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

struct OrdinateDimension <: AbstractDimension
    point::Point2D
    origin::Point2D
    axis::Symbol
    elbow::Point2D
    text_pos::Point2D
    text::String
    style::DimStyle
end

_pt(p::Point2D) = p
_pt(p::Tuple{<:Real,<:Real}) = Point2D(p)

function _format_dim_text(value::Real, style::DimStyle)
    rounded = round(value; digits=style.decimals)
    return string(rounded, style.unit_suffix)
end

function _apply_tolerance(base_text::String, style::DimStyle; tol_plus=nothing, tol_minus=nothing)
    plus = tol_plus
    minus = tol_minus

    if plus === nothing && minus === nothing
        if style.tolerance_mode === :none
            return base_text
        elseif style.tolerance_mode === :symmetric
            plus = style.tolerance_plus
            minus = style.tolerance_plus
        elseif style.tolerance_mode === :deviation
            plus = style.tolerance_plus
            minus = style.tolerance_minus
        else
            return base_text
        end
    elseif plus === nothing
        plus = minus
    elseif minus === nothing
        minus = plus
    end

    plus === nothing && return base_text
    minus === nothing && return base_text

    plus_str = _format_dim_text(abs(float(plus)), style)
    minus_str = _format_dim_text(abs(float(minus)), style)
    tol_eps = max(1e-12, 0.5 * 10.0^(-style.decimals))

    if abs(float(plus)) <= tol_eps && abs(float(minus)) <= tol_eps
        return base_text
    end

    if abs(abs(float(plus)) - abs(float(minus))) <= tol_eps
        return string(base_text, " ±", plus_str)
    end
    return string(base_text, " +", plus_str, "/-", minus_str)
end

function _style_text_side(style::DimStyle)
    if style.text_placement === :above
        return 1.0
    elseif style.text_placement === :below
        return -1.0
    else
        return 0.0
    end
end

function _text_offset_direction(dim_vec::Point2D, style::DimStyle)
    if style.text_orientation === :horizontal
        return Point2D(0.0, 1.0)
    elseif style.text_orientation === :vertical
        return Point2D(1.0, 0.0)
    else
        return unit(perp(dim_vec))
    end
end

function _dimension_text_position(dim1::Point2D, dim2::Point2D, style::DimStyle)
    span_vec = dim2 - dim1
    span = norm2d(span_vec)
    span == 0 && return dim1

    u = unit(span_vec)
    side = _style_text_side(style)
    if side == 0.0
        return midpoint(dim1, dim2)
    end

    n = _text_offset_direction(span_vec, style)
    inside_pos = midpoint(dim1, dim2) + side * style.text_height * 0.4 * n
    needed_span = style.text_height * style.fit_text_gap_factor

    if style.fit_mode === :text_outside || (style.fit_mode === :best && span < needed_span)
        return dim2 + side * style.text_height * 1.1 * n + style.text_height * 0.8 * u
    end

    return inside_pos
end

function _radial_text_position(start::Point2D, dim_dir::Point2D, style::DimStyle)
    side = _style_text_side(style)
    side == 0.0 && return start
    n = if style.text_orientation === :horizontal
        Point2D(0.0, 1.0)
    elseif style.text_orientation === :vertical
        Point2D(1.0, 0.0)
    else
        unit(dim_dir)
    end
    return start + side * style.text_height * n
end

function DIMTOLERANCE(value::Real; plus=nothing, minus=nothing, style::DimStyle=current_dimstyle())
    base_text = _format_dim_text(value, style)
    return _apply_tolerance(base_text, style; tol_plus=plus, tol_minus=minus)
end

function DIMLIMITS(nominal::Real, lower::Real, upper::Real; style::DimStyle=current_dimstyle())
    lower > upper && throw(ArgumentError("lower must be <= upper"))
    nominal < lower && throw(ArgumentError("nominal must be >= lower"))
    nominal > upper && throw(ArgumentError("nominal must be <= upper"))

    upper_text = _format_dim_text(upper, style)
    lower_text = _format_dim_text(lower, style)
    return string(upper_text, " / ", lower_text)
end

measure(d::LinearDimension) = distance(d.p1, d.p2)
measure(d::AlignedDimension) = distance(d.p1, d.p2)
measure(d::AngularDimension) = abs(atan(cross2d(d.p1 - d.vertex, d.p2 - d.vertex), dot2d(d.p1 - d.vertex, d.p2 - d.vertex)))
measure(d::ArcDimension) = d.radius * abs(d.θ2 - d.θ1)
measure(d::CenterDimension) = 0.0
measure(d::JoggedDimension) = distance(d.p1, d.p2)
measure(d::RadialDimension) = distance(d.center, d.point)
measure(d::DiameterDimension) = distance(d.p1, d.p2)
measure(d::OrdinateDimension) = d.axis === :x ? d.point.x - d.origin.x : d.point.y - d.origin.y

function DIMLINEAR(p1, p2; orientation::Symbol=:auto, offset::Real=10.0, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    a = _pt(p1)
    b = _pt(p2)

    if orientation === :auto
        orientation = abs(b.x - a.x) >= abs(b.y - a.y) ? :horizontal : :vertical
    end

    if orientation === :horizontal
        yref = (a.y + b.y) / 2 + float(offset)
        dim1 = Point2D(a.x, yref)
        dim2 = Point2D(b.x, yref)
        ext1 = Point2D(a.x, yref + sign(offset) * style.ext_line_extension)
        ext2 = Point2D(b.x, yref + sign(offset) * style.ext_line_extension)
    elseif orientation === :vertical
        xref = (a.x + b.x) / 2 + float(offset)
        dim1 = Point2D(xref, a.y)
        dim2 = Point2D(xref, b.y)
        ext1 = Point2D(xref + sign(offset) * style.ext_line_extension, a.y)
        ext2 = Point2D(xref + sign(offset) * style.ext_line_extension, b.y)
    else
        throw(ArgumentError("orientation must be :auto, :horizontal, or :vertical"))
    end

    dtext = if text === nothing
        _apply_tolerance(_format_dim_text(distance(a, b), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    tpos = _dimension_text_position(dim1, dim2, style)

    return LinearDimension(a, b, ext1, ext2, dim1, dim2, tpos, dtext, style)
end

function DIMALIGNED(p1, p2; offset::Real=10.0, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    a = _pt(p1)
    b = _pt(p2)

    dir = unit(b - a)
    n = perp(dir)

    dim1 = a + float(offset) * n
    dim2 = b + float(offset) * n
    ext1 = dim1 + sign(offset) * style.ext_line_extension * n
    ext2 = dim2 + sign(offset) * style.ext_line_extension * n

    dtext = if text === nothing
        _apply_tolerance(_format_dim_text(distance(a, b), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    tpos = _dimension_text_position(dim1, dim2, style)

    return AlignedDimension(a, b, ext1, ext2, dim1, dim2, tpos, dtext, style)
end

function DIMANGULAR(vertex, p1, p2; radius::Real=20.0, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    v = _pt(vertex)
    a = _pt(p1)
    b = _pt(p2)

    va = a - v
    vb = b - v
    norm2d(va) == 0 && throw(ArgumentError("p1 cannot coincide with vertex"))
    norm2d(vb) == 0 && throw(ArgumentError("p2 cannot coincide with vertex"))

    θ1 = angle_of(va)
    δ = atan(cross2d(va, vb), dot2d(va, vb))
    θ2 = θ1 + δ
    θm = (θ1 + θ2) / 2

    dtext = if text === nothing
        _apply_tolerance(_format_dim_text(abs(δ) * 180 / π, style) * "°", style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    radial = Point2D(cos(θm), sin(θm))
    tpos = _radial_text_position(v + float(radius) * radial, radial, style)

    return AngularDimension(v, a, b, float(radius), θ1, θ2, tpos, dtext, style)
end

function DIMARC(center, p1, p2; radius::Union{Nothing,Real}=nothing, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    c = _pt(center)
    a = _pt(p1)
    b = _pt(p2)

    va = a - c
    vb = b - c
    norm2d(va) == 0 && throw(ArgumentError("p1 cannot coincide with center"))
    norm2d(vb) == 0 && throw(ArgumentError("p2 cannot coincide with center"))

    θ1 = angle_of(va)
    δ = atan(cross2d(va, vb), dot2d(va, vb))
    θ2 = θ1 + δ

    r = radius === nothing ? (norm2d(va) + norm2d(vb)) / 2 : float(radius)
    r <= 0 && throw(ArgumentError("radius must be positive"))

    θm = (θ1 + θ2) / 2
    radial = Point2D(cos(θm), sin(θm))
    tpos = _radial_text_position(c + r * radial, radial, style)
    dtext = if text === nothing
        _apply_tolerance("ARC " * _format_dim_text(r * abs(δ), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end

    return ArcDimension(c, a, b, r, θ1, θ2, tpos, dtext, style)
end

function DIMCENTER(center; size::Real=10.0, style::DimStyle=current_dimstyle())
    c = _pt(center)
    half = float(size) / 2
    h1 = Point2D(c.x - half, c.y)
    h2 = Point2D(c.x + half, c.y)
    v1 = Point2D(c.x, c.y - half)
    v2 = Point2D(c.x, c.y + half)
    return CenterDimension(c, h1, h2, v1, v2, style)
end

function DIMJOGGED(p1, p2; orientation::Symbol=:auto, offset::Real=10.0, jog_size::Real=6.0, jog_fraction::Real=0.12, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    a = _pt(p1)
    b = _pt(p2)
    base = DIMLINEAR(a, b; orientation=orientation, offset=offset, style=style)

    dim_vec = base.dim2 - base.dim1
    u = unit(dim_vec)
    n = perp(u)
    s = offset == 0 ? 1.0 : sign(offset)

    span = norm2d(dim_vec)
    jog_half = max(float(jog_size) / 2, 1e-6)
    along = max(span * float(jog_fraction) / 2, jog_half)
    mid = midpoint(base.dim1, base.dim2)

    j1 = mid - along * u
    j_apex = mid + s * float(jog_size) * n
    j2 = mid + along * u

    dtext = if text === nothing
        _apply_tolerance(_format_dim_text(distance(a, b), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    tpos = _dimension_text_position(base.dim1, base.dim2, style)

    return JoggedDimension(a, b, base.ext1, base.ext2, base.dim1, j1, j_apex, j2, base.dim2, tpos, dtext, style)
end

function _collect_points(points)
    return [_pt(p) for p in points]
end

function DIMBASELINE(base_point, points...; orientation::Symbol=:auto, offset::Real=10.0, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    base = _pt(base_point)
    others = _collect_points(points)
    isempty(others) && throw(ArgumentError("DIMBASELINE needs at least one target point"))

    dims = Vector{LinearDimension}(undef, length(others))
    for (index, target) in enumerate(others)
        dims[index] = DIMLINEAR(base, target; orientation=orientation, offset=offset + (index - 1) * style.text_height, tol_plus=tol_plus, tol_minus=tol_minus, style=style)
    end
    return dims
end

    function DIMCONTINUE(start_point, points...; orientation::Symbol=:auto, offset::Real=10.0, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    chain = vcat([_pt(start_point)], _collect_points(points))
    length(chain) < 2 && throw(ArgumentError("DIMCONTINUE needs at least two points"))

    dims = Vector{LinearDimension}(undef, length(chain) - 1)
    for index in 1:(length(chain) - 1)
        dims[index] = DIMLINEAR(chain[index], chain[index + 1]; orientation=orientation, offset=offset, tol_plus=tol_plus, tol_minus=tol_minus, style=style)
    end
    return dims
end

    function DIMRADIAL(center, point; offset::Real=10.0, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    c = _pt(center)
    p = _pt(point)
    dir = p - c
    norm2d(dir) == 0 && throw(ArgumentError("point cannot coincide with center"))

    u = unit(dir)
    leader_end = p + float(offset) * u
    tpos = _radial_text_position(leader_end, perp(u), style)

    dtext = if text === nothing
        _apply_tolerance("R" * _format_dim_text(distance(c, p), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    return RadialDimension(c, p, leader_end, tpos, dtext, style)
end

function DIMDIAMETER(center, point; text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    c = _pt(center)
    p1 = _pt(point)
    dir = p1 - c
    norm2d(dir) == 0 && throw(ArgumentError("point cannot coincide with center"))

    p2 = c - dir
    u = unit(dir)
    tpos = _dimension_text_position(p1, p2, style)

    dtext = if text === nothing
        _apply_tolerance("⌀" * _format_dim_text(distance(p1, p2), style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    return DiameterDimension(c, p1, p2, tpos, dtext, style)
end

function DIMORDINATE(point; axis::Symbol=:x, origin=(0.0, 0.0), offset::Real=10.0, text=nothing, tol_plus=nothing, tol_minus=nothing, style::DimStyle=current_dimstyle())
    p = _pt(point)
    o = _pt(origin)

    if axis === :x
        elbow = Point2D(p.x, p.y + float(offset))
        side = _style_text_side(style)
        tpos = side == 0.0 ? elbow : Point2D(elbow.x + style.text_height, elbow.y + side * style.text_height * 0.5)
        value = p.x - o.x
    elseif axis === :y
        elbow = Point2D(p.x + float(offset), p.y)
        side = _style_text_side(style)
        tpos = side == 0.0 ? elbow : Point2D(elbow.x + side * style.text_height * 0.5, elbow.y + style.text_height)
        value = p.y - o.y
    else
        throw(ArgumentError("axis must be :x or :y"))
    end

    dtext = if text === nothing
        _apply_tolerance(_format_dim_text(value, style), style; tol_plus=tol_plus, tol_minus=tol_minus)
    else
        string(text)
    end
    return OrdinateDimension(p, o, axis, elbow, tpos, dtext, style)
end
