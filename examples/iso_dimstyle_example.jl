using DrawingDim
using Plots

DIMSTYLE(
    text_height=8,
    arrow_size=2.5,
    arrowhead_style=:open_out,
    ext_line_offset=1.0,
    ext_line_extension=1.25,
    line_width=0.25,
    decimals=2,
    unit_suffix="",
    color=:black,
    text_font="Palatino Roman",
    text_orientation=:aligned,
    text_placement=:above,
    fit_mode=:best,
    hand_drawn=true,
    tolerance_mode=:symmetric,
    tolerance_plus=0.05,
)

outline_x = [0.0, 60.0, 60.0, 0.0, 0.0]
outline_y = [0.0, 0.0, 30.0, 30.0, 0.0]

d_width = DIMLINEAR((0.0, 0.0), (60.0, 0.0); orientation=:horizontal, offset=-8.0)
d_height = DIMLINEAR((60.0, 0.0), (60.0, 30.0); orientation=:vertical, offset=8.0)
d_diag = DIMALIGNED((0.0, 0.0), (60.0, 30.0); offset=7.0, tol_plus=0.10, tol_minus=0.05)
d_hole_center = DIMCENTER((20.0, 15.0); size=6.0)
d_hole_dia = DIMDIAMETER((20.0, 15.0), (20.0, 20.0); tol_plus=0.03)

plot(legend=false, aspect_ratio=:equal, title="ISO-style DIMSTYLE Example")
plot!(outline_x, outline_y, seriestype=:path, color=:black, linewidth=1)
plot!(d_width)
plot!(d_height)
plot!(d_diag)
plot!(d_hole_center)
plot!(d_hole_dia)

display(current())
