Base.@kwdef struct DimStyle
    text_height::Float64 = 8.0
    arrow_size::Float64 = 2.5
    arrowhead_style::Symbol = :tick
    ext_line_offset::Float64 = 1.5
    ext_line_extension::Float64 = 1.5
    line_width::Float64 = 0.5
    color::Symbol = :black
    text_font::String = "Palatino Roman"
    text_orientation::Symbol = :aligned
    text_placement::Symbol = :above
    fit_mode::Symbol = :best
    fit_text_gap_factor::Float64 = 1.1
    hand_drawn::Bool = true
    hand_drawn_amplitude::Float64 = 0.15
    hand_drawn_wiggles::Int = 2
    decimals::Int = 2
    unit_suffix::String = ""
    tolerance_mode::Symbol = :symmetric
    tolerance_plus::Float64 = 0.0
    tolerance_minus::Float64 = 0.0
end

const _DIMSTYLE = Ref(DimStyle())

current_dimstyle() = _DIMSTYLE[]

function dimstyle!(style::DimStyle)
    _DIMSTYLE[] = style
    return style
end

function reset_dimstyle!()
    _DIMSTYLE[] = DimStyle()
    return _DIMSTYLE[]
end

function DIMSTYLE(; kwargs...)
    style = DimStyle(; kwargs...)
    return dimstyle!(style)
end
