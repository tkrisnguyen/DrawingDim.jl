using RecipesBase
import Plots

function _arrow_segments(tip::Point2D, inward_dir::Point2D, size::Real; spread::Real=π / 7)
    d = unit(inward_dir)
    w1 = tip + rotate(-d, spread) * size
    w2 = tip + rotate(-d, -spread) * size
    return (w1, w2)
end

function _arrow_segments_by_style(tip::Point2D, inward_dir::Point2D, size::Real, style::Symbol)
    if style === :small_open
        return _arrow_segments(tip, inward_dir, size * 0.9; spread=π / 11)
    elseif style === :open30
        return _arrow_segments(tip, inward_dir, size; spread=π / 12)
    elseif style === :open90
        return _arrow_segments(tip, inward_dir, size * 0.9; spread=π / 4)
    elseif style === :open_out
        return _arrow_segments(tip, -inward_dir, size)
    elseif style === :open30_out
        return _arrow_segments(tip, -inward_dir, size; spread=π / 12)
    elseif style === :open90_out
        return _arrow_segments(tip, -inward_dir, size * 0.9; spread=π / 4)
    elseif style === :hook
        return _arrow_segments(tip, inward_dir, size * 0.75; spread=π / 10)
    end
    return _arrow_segments(tip, inward_dir, size)
end

function _arrow_path(style::Symbol, tip::Point2D, w1::Point2D, w2::Point2D)
    if style === :closed || style === :closed_blank
        x = [tip.x, w1.x, w2.x, tip.x]
        y = [tip.y, w1.y, w2.y, tip.y]
    elseif style === :hook
        h1 = w1 + 0.45 * (w1 - tip)
        h2 = w2 + 0.45 * (w2 - tip)
        x = [tip.x, w1.x, h1.x, NaN, tip.x, w2.x, h2.x]
        y = [tip.y, w1.y, h1.y, NaN, tip.y, w2.y, h2.y]
    else
        x = [tip.x, w1.x, NaN, tip.x, w2.x]
        y = [tip.y, w1.y, NaN, tip.y, w2.y]
    end
    return x, y
end

_is_slash_style(style::Symbol) = style === :tick || style === :oblique
_is_dot_style(style::Symbol) = style === :dot || style === :dot_small

function _slash_path(style::Symbol, tip::Point2D, inward_dir::Point2D, size::Real)
    d = unit(inward_dir)
    angle = style === :oblique ? π / 6 : π / 4
    t = rotate(-d, angle)
    half = 0.65 * size
    p1 = tip - half * t
    p2 = tip + half * t
    return [p1.x, p2.x], [p1.y, p2.y]
end

function _dot_markersize(style::Symbol, size::Real)
    return style === :dot_small ? max(1.6, size) : max(2.0, size * 1.4)
end

function _extension_segment(point::Point2D, extension_end::Point2D)
    v = extension_end - point
    len = norm2d(v)
    if len == 0
        return point, extension_end
    end
    start = point + 0.2 * v
    return start, extension_end
end

_rad2deg(θ::Real) = 180 * θ / π

function _upright_angle_deg(θdeg::Real)
    wrapped = mod(θdeg + 180, 360) - 180
    if wrapped > 90
        wrapped -= 180
    elseif wrapped < -90
        wrapped += 180
    end
    return wrapped
end

function _text_rotation_deg(d::Union{LinearDimension,AlignedDimension,JoggedDimension})
    if d.style.text_orientation === :horizontal
        return 0.0
    elseif d.style.text_orientation === :vertical
        return 90.0
    end
    return _upright_angle_deg(_rad2deg(angle_of(d.dim2 - d.dim1)))
end

function _text_rotation_deg(d::DiameterDimension)
    if d.style.text_orientation === :horizontal
        return 0.0
    elseif d.style.text_orientation === :vertical
        return 90.0
    end
    return _upright_angle_deg(_rad2deg(angle_of(d.p2 - d.p1)))
end

function _text_rotation_deg(d::RadialDimension)
    if d.style.text_orientation === :horizontal
        return 0.0
    elseif d.style.text_orientation === :vertical
        return 90.0
    end
    return _upright_angle_deg(_rad2deg(angle_of(d.leader_end - d.point)))
end

function _text_rotation_deg(d::OrdinateDimension)
    if d.style.text_orientation === :horizontal
        return 0.0
    elseif d.style.text_orientation === :vertical
        return 90.0
    end
    return d.axis === :x ? 0.0 : 90.0
end

function _text_rotation_deg(d::Union{AngularDimension,ArcDimension})
    if d.style.text_orientation === :horizontal
        return 0.0
    elseif d.style.text_orientation === :vertical
        return 90.0
    end
    θm = (d.θ1 + d.θ2) / 2
    tangent = θm + π / 2
    return _upright_angle_deg(_rad2deg(tangent))
end

function _plot_annotation(d)
    fontsize = max(6, Int(round(d.style.text_height * 2.4)))
    rot = _text_rotation_deg(d)
    txt = Plots.text(d.text, fontsize, d.style.color, family=d.style.text_font, rotation=rot)
    return (d.text_pos.x, d.text_pos.y, txt)
end

function _handdrawn_segment(a::Point2D, b::Point2D, style::DimStyle)
    if !style.hand_drawn
        return [a.x, b.x], [a.y, b.y]
    end

    v = b - a
    len = norm2d(v)
    if len == 0
        return [a.x], [a.y]
    end

    u = unit(v)
    n = perp(u)
    samples = max(6, Int(ceil(len / 4)))
    amp = style.hand_drawn_amplitude
    wiggles = max(style.hand_drawn_wiggles, 1)

    xs = Float64[]
    ys = Float64[]
    for i in 0:samples
        t = i / samples
        base = a + t * v
        env = 4 * t * (1 - t)
        off = amp * env * sin(2π * wiggles * t)
        p = base + off * n
        push!(xs, p.x)
        push!(ys, p.y)
    end
    return xs, ys
end

function _handdrawn_polyline(points::Vector{Point2D}, style::DimStyle)
    length(points) <= 1 && return [points[1].x], [points[1].y]

    xs = Float64[]
    ys = Float64[]
    for index in 1:(length(points) - 1)
        xseg, yseg = _handdrawn_segment(points[index], points[index + 1], style)
        if index > 1
            append!(xs, xseg[2:end])
            append!(ys, yseg[2:end])
        else
            append!(xs, xseg)
            append!(ys, yseg)
        end
    end
    return xs, ys
end

@recipe function f(d::Union{LinearDimension,AlignedDimension})
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    @series begin
        seriestype := :path
        e1s, e1e = _extension_segment(d.p1, d.ext1)
        x = [e1s.x, e1e.x]
        y = [e1s.y, e1e.y]
        x, y
    end

    @series begin
        seriestype := :path
        e2s, e2e = _extension_segment(d.p2, d.ext2)
        x = [e2s.x, e2e.x]
        y = [e2s.y, e2e.y]
        x, y
    end

    @series begin
        seriestype := :path
        x, y = _handdrawn_segment(d.dim1, d.dim2, d.style)
        x, y
    end

    center = midpoint(d.dim1, d.dim2)
    dir1 = center - d.dim1
    dir2 = center - d.dim2
    a11, a12 = _arrow_segments_by_style(d.dim1, dir1, d.style.arrow_size, d.style.arrowhead_style)
    a21, a22 = _arrow_segments_by_style(d.dim2, dir2, d.style.arrow_size, d.style.arrowhead_style)

    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.dim1.x, a11.x, a12.x]
            y = [d.dim1.y, a11.y, a12.y]
            x, y
        end
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.dim2.x, a21.x, a22.x]
            y = [d.dim2.y, a21.y, a22.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [d.dim1.x, d.dim2.x]
            y = [d.dim1.y, d.dim2.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, d.dim1, dir1, d.style.arrow_size)
        tx2, ty2 = _slash_path(d.style.arrowhead_style, d.dim2, dir2, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(tx1, [NaN], tx2)
            y = vcat(ty1, [NaN], ty2)
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, d.dim1, a11, a12)
        x2, y2 = _arrow_path(d.style.arrowhead_style, d.dim2, a21, a22)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(x1, [NaN], x2)
            y = vcat(y1, [NaN], y2)
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::AngularDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    v = d.vertex
    dir1 = unit(d.p1 - v)
    dir2 = unit(d.p2 - v)

    p1_arc = v + d.radius * dir1
    p2_arc = v + d.radius * dir2

    @series begin
        seriestype := :path
        x = [v.x, p1_arc.x]
        y = [v.y, p1_arc.y]
        x, y
    end

    @series begin
        seriestype := :path
        x = [v.x, p2_arc.x]
        y = [v.y, p2_arc.y]
        x, y
    end

    ts = range(d.θ1, d.θ2; length=60)
    arcx = [v.x + d.radius * cos(t) for t in ts]
    arcy = [v.y + d.radius * sin(t) for t in ts]

    @series begin
        seriestype := :path
        arcx, arcy
    end

    sgn = sign(d.θ2 - d.θ1)
    tan1 = sgn * perp(dir1)
    tan2 = -sgn * perp(dir2)
    a11, a12 = _arrow_segments_by_style(p1_arc, tan1, d.style.arrow_size, d.style.arrowhead_style)
    a21, a22 = _arrow_segments_by_style(p2_arc, tan2, d.style.arrow_size, d.style.arrowhead_style)

    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [p1_arc.x, a11.x, a12.x]
            y = [p1_arc.y, a11.y, a12.y]
            x, y
        end
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [p2_arc.x, a21.x, a22.x]
            y = [p2_arc.y, a21.y, a22.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [p1_arc.x, p2_arc.x]
            y = [p1_arc.y, p2_arc.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, p1_arc, tan1, d.style.arrow_size)
        tx2, ty2 = _slash_path(d.style.arrowhead_style, p2_arc, tan2, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(tx1, [NaN], tx2)
            y = vcat(ty1, [NaN], ty2)
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, p1_arc, a11, a12)
        x2, y2 = _arrow_path(d.style.arrowhead_style, p2_arc, a21, a22)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(x1, [NaN], x2)
            y = vcat(y1, [NaN], y2)
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::ArcDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    c = d.center
    u1 = unit(d.p1 - c)
    u2 = unit(d.p2 - c)
    p1_arc = c + d.radius * u1
    p2_arc = c + d.radius * u2

    @series begin
        seriestype := :path
        x = [d.p1.x, p1_arc.x]
        y = [d.p1.y, p1_arc.y]
        x, y
    end

    @series begin
        seriestype := :path
        x = [d.p2.x, p2_arc.x]
        y = [d.p2.y, p2_arc.y]
        x, y
    end

    ts = range(d.θ1, d.θ2; length=60)
    arcx = [c.x + d.radius * cos(t) for t in ts]
    arcy = [c.y + d.radius * sin(t) for t in ts]

    @series begin
        seriestype := :path
        arcx, arcy
    end

    sgn = sign(d.θ2 - d.θ1)
    tan1 = sgn * perp(u1)
    tan2 = -sgn * perp(u2)
    a11, a12 = _arrow_segments_by_style(p1_arc, tan1, d.style.arrow_size, d.style.arrowhead_style)
    a21, a22 = _arrow_segments_by_style(p2_arc, tan2, d.style.arrow_size, d.style.arrowhead_style)

    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [p1_arc.x, a11.x, a12.x]
            y = [p1_arc.y, a11.y, a12.y]
            x, y
        end
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [p2_arc.x, a21.x, a22.x]
            y = [p2_arc.y, a21.y, a22.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [p1_arc.x, p2_arc.x]
            y = [p1_arc.y, p2_arc.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, p1_arc, tan1, d.style.arrow_size)
        tx2, ty2 = _slash_path(d.style.arrowhead_style, p2_arc, tan2, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(tx1, [NaN], tx2)
            y = vcat(ty1, [NaN], ty2)
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, p1_arc, a11, a12)
        x2, y2 = _arrow_path(d.style.arrowhead_style, p2_arc, a21, a22)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(x1, [NaN], x2)
            y = vcat(y1, [NaN], y2)
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::CenterDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    @series begin
        seriestype := :path
        x = [d.h1.x, d.h2.x]
        y = [d.h1.y, d.h2.y]
        x, y
    end

    @series begin
        seriestype := :path
        x = [d.v1.x, d.v2.x]
        y = [d.v1.y, d.v2.y]
        x, y
    end
end

@recipe function f(d::JoggedDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    @series begin
        seriestype := :path
        e1s, e1e = _extension_segment(d.p1, d.ext1)
        x = [e1s.x, e1e.x]
        y = [e1s.y, e1e.y]
        x, y
    end

    @series begin
        seriestype := :path
        e2s, e2e = _extension_segment(d.p2, d.ext2)
        x = [e2s.x, e2e.x]
        y = [e2s.y, e2e.y]
        x, y
    end

    @series begin
        seriestype := :path
        x, y = _handdrawn_polyline([d.dim1, d.jog1, d.jog_apex, d.jog2, d.dim2], d.style)
        x, y
    end

    center = midpoint(d.dim1, d.dim2)
    dir1 = center - d.dim1
    dir2 = center - d.dim2
    a11, a12 = _arrow_segments_by_style(d.dim1, dir1, d.style.arrow_size, d.style.arrowhead_style)
    a21, a22 = _arrow_segments_by_style(d.dim2, dir2, d.style.arrow_size, d.style.arrowhead_style)

    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.dim1.x, a11.x, a12.x]
            y = [d.dim1.y, a11.y, a12.y]
            x, y
        end
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.dim2.x, a21.x, a22.x]
            y = [d.dim2.y, a21.y, a22.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [d.dim1.x, d.dim2.x]
            y = [d.dim1.y, d.dim2.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, d.dim1, dir1, d.style.arrow_size)
        tx2, ty2 = _slash_path(d.style.arrowhead_style, d.dim2, dir2, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(tx1, [NaN], tx2)
            y = vcat(ty1, [NaN], ty2)
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, d.dim1, a11, a12)
        x2, y2 = _arrow_path(d.style.arrowhead_style, d.dim2, a21, a22)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(x1, [NaN], x2)
            y = vcat(y1, [NaN], y2)
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::RadialDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    @series begin
        seriestype := :path
        x, y = _handdrawn_polyline([d.center, d.point, d.leader_end], d.style)
        x, y
    end

    a1, a2 = _arrow_segments_by_style(d.point, d.center - d.point, d.style.arrow_size, d.style.arrowhead_style)
    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.point.x, a1.x, a2.x]
            y = [d.point.y, a1.y, a2.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [d.point.x]
            y = [d.point.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, d.point, d.center - d.point, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = tx1
            y = ty1
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, d.point, a1, a2)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = x1
            y = y1
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::DiameterDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    @series begin
        seriestype := :path
        x, y = _handdrawn_segment(d.p1, d.p2, d.style)
        x, y
    end

    a11, a12 = _arrow_segments_by_style(d.p1, d.center - d.p1, d.style.arrow_size, d.style.arrowhead_style)
    a21, a22 = _arrow_segments_by_style(d.p2, d.center - d.p2, d.style.arrow_size, d.style.arrowhead_style)
    if d.style.arrowhead_style === :closed_filled
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.p1.x, a11.x, a12.x]
            y = [d.p1.y, a11.y, a12.y]
            x, y
        end
        @series begin
            seriestype := :shape
            fillcolor := d.style.color
            linecolor := d.style.color
            x = [d.p2.x, a21.x, a22.x]
            y = [d.p2.y, a21.y, a22.y]
            x, y
        end
    elseif _is_dot_style(d.style.arrowhead_style)
        @series begin
            seriestype := :scatter
            markerstrokecolor := d.style.color
            markercolor := d.style.color
            markershape := :circle
            markersize := _dot_markersize(d.style.arrowhead_style, d.style.arrow_size)
            x = [d.p1.x, d.p2.x]
            y = [d.p1.y, d.p2.y]
            x, y
        end
    elseif _is_slash_style(d.style.arrowhead_style)
        tx1, ty1 = _slash_path(d.style.arrowhead_style, d.p1, d.center - d.p1, d.style.arrow_size)
        tx2, ty2 = _slash_path(d.style.arrowhead_style, d.p2, d.center - d.p2, d.style.arrow_size)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(tx1, [NaN], tx2)
            y = vcat(ty1, [NaN], ty2)
            x, y
        end
    elseif d.style.arrowhead_style !== :none
        x1, y1 = _arrow_path(d.style.arrowhead_style, d.p1, a11, a12)
        x2, y2 = _arrow_path(d.style.arrowhead_style, d.p2, a21, a22)
        @series begin
            seriestype := :path
            linecolor := d.style.color
            x = vcat(x1, [NaN], x2)
            y = vcat(y1, [NaN], y2)
            x, y
        end
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(d::OrdinateDimension)
    linecolor --> d.style.color
    linewidth --> d.style.line_width
    label --> ""

    if d.axis === :x
        proj = Point2D(d.point.x, d.origin.y)
    else
        proj = Point2D(d.origin.x, d.point.y)
    end

    @series begin
        seriestype := :path
        x, y = _handdrawn_polyline([d.origin, proj, d.point, d.elbow, d.text_pos], d.style)
        x, y
    end

    @series begin
        seriestype := :scatter
        markerstrokewidth := 0
        markersize := 0
        markershape := :none
        annotations := [_plot_annotation(d)]
        x = [d.text_pos.x]
        y = [d.text_pos.y]
        x, y
    end
end

@recipe function f(ds::AbstractVector{<:AbstractDimension})
    linecolor --> :auto
    linewidth --> :auto
    label --> ""

    for d in ds
        @series begin
            d
        end
    end
end
