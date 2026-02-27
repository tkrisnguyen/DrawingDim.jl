using Test
using DrawingDim

@testset "DrawingDim commands" begin
    reset_dimstyle!()
    DIMSTYLE(decimals=1, unit_suffix=" mm", text_height=8.0, arrow_size=2.5)

    s = current_dimstyle()
    @test s.arrowhead_style isa Symbol
    @test !isempty(s.text_font)
    @test s.text_orientation === :aligned
    @test s.text_placement === :above
    @test s.fit_mode === :best
    @test s.tolerance_mode === :symmetric

    s2 = DIMSTYLE(decimals=1, unit_suffix=" mm", text_height=8.0, arrow_size=2.5, arrowhead_style=:small_open, text_orientation=:aligned, color=:black, hand_drawn=true)
    @test s2.arrowhead_style === :small_open
    @test s2.text_orientation === :aligned
    @test s2.color === :black
    @test s2.hand_drawn === true

    s3 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:tick)
    @test s3.arrowhead_style === :tick

    s4 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:hook)
    @test s4.arrowhead_style === :hook

    s5 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:oblique)
    @test s5.arrowhead_style === :oblique

    s6 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:open30)
    @test s6.arrowhead_style === :open30

    s7 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:open_out)
    @test s7.arrowhead_style === :open_out

    s8 = DIMSTYLE(decimals=1, unit_suffix=" mm", arrowhead_style=:open30_out)
    @test s8.arrowhead_style === :open30_out

    dlin = DIMLINEAR((0.0, 0.0), (10.0, 0.0); orientation=:horizontal, offset=5.0)
    @test dlin isa LinearDimension
    @test measure(dlin) ≈ 10.0
    @test dlin.text == "10.0 mm"

    dali = DIMALIGNED((0.0, 0.0), (3.0, 4.0); offset=3.0)
    @test dali isa AlignedDimension
    @test measure(dali) ≈ 5.0

    dang = DIMANGULAR((0.0, 0.0), (1.0, 0.0), (0.0, 1.0); radius=2.0)
    @test dang isa AngularDimension
    @test measure(dang) ≈ (π / 2)
    @test occursin("90.0", dang.text)

    darc = DIMARC((0.0, 0.0), (5.0, 0.0), (0.0, 5.0); radius=5.0)
    @test darc isa ArcDimension
    @test measure(darc) ≈ (5.0 * π / 2)
    @test startswith(darc.text, "ARC ")

    drad = DIMRADIAL((0.0, 0.0), (0.0, 5.0))
    @test drad isa RadialDimension
    @test measure(drad) ≈ 5.0
    @test startswith(drad.text, "R")

    ddia = DIMDIAMETER((0.0, 0.0), (0.0, 4.0))
    @test ddia isa DiameterDimension
    @test measure(ddia) ≈ 8.0
    @test startswith(ddia.text, "⌀")

    dordx = DIMORDINATE((12.0, 7.0); axis=:x, origin=(2.0, 0.0))
    @test dordx isa OrdinateDimension
    @test measure(dordx) ≈ 10.0
    @test dordx.axis === :x

    dordy = DIMORDINATE((12.0, 7.0); axis=:y, origin=(0.0, 2.0))
    @test measure(dordy) ≈ 5.0

    dbase = DIMBASELINE((0.0, 0.0), (10.0, 0.0), (20.0, 0.0); orientation=:horizontal, offset=5.0)
    @test length(dbase) == 2
    @test all(d -> d isa LinearDimension, dbase)
    @test measure(dbase[1]) ≈ 10.0
    @test measure(dbase[2]) ≈ 20.0

    dcont = DIMCONTINUE((0.0, 0.0), (10.0, 0.0), (20.0, 0.0); orientation=:horizontal, offset=5.0)
    @test length(dcont) == 2
    @test all(d -> d isa LinearDimension, dcont)
    @test measure(dcont[1]) ≈ 10.0
    @test measure(dcont[2]) ≈ 10.0

    dcen = DIMCENTER((5.0, 5.0); size=6.0)
    @test dcen isa CenterDimension
    @test measure(dcen) == 0.0

    djog = DIMJOGGED((0.0, 0.0), (15.0, 0.0); orientation=:horizontal, offset=5.0, jog_size=4.0)
    @test djog isa JoggedDimension
    @test measure(djog) ≈ 15.0

    dtol = DIMLINEAR((0.0, 0.0), (10.0, 0.0); orientation=:horizontal, tol_plus=0.2, tol_minus=0.1)
    @test occursin("+0.2 mm/-0.1 mm", dtol.text)

    DIMSTYLE(decimals=1, unit_suffix=" mm", tolerance_mode=:symmetric, tolerance_plus=0.3)
    dtol_style = DIMALIGNED((0.0, 0.0), (3.0, 4.0); offset=2.0)
    @test occursin("±0.3 mm", dtol_style.text)

    @test DIMTOLERANCE(12.34; plus=0.2, minus=0.1) == "12.3 mm +0.2 mm/-0.1 mm"
    @test DIMTOLERANCE(12.34; plus=0.2) == "12.3 mm ±0.2 mm"

    DIMSTYLE(decimals=2, unit_suffix=" mm", tolerance_mode=:deviation, tolerance_plus=0.05, tolerance_minus=0.02)
    @test DIMTOLERANCE(8.0) == "8.0 mm +0.05 mm/-0.02 mm"
    @test DIMLIMITS(25.0, 24.95, 25.05) == "25.05 mm / 24.95 mm"

    dfit = DIMSTYLE(text_height=10.0, unit_suffix=" mm", decimals=1, fit_mode=:best, text_placement=:above)
    dshort = DIMLINEAR((0.0, 0.0), (6.0, 0.0); orientation=:horizontal, offset=4.0)
    @test dshort.text_pos.x > max(dshort.dim1.x, dshort.dim2.x)

    DIMSTYLE(text_height=10.0, unit_suffix=" mm", decimals=1, fit_mode=:text_inside, text_placement=:below)
    dinside = DIMLINEAR((0.0, 0.0), (40.0, 0.0); orientation=:horizontal, offset=4.0)
    midy = (dinside.dim1.y + dinside.dim2.y) / 2
    @test dinside.text_pos.y < midy
end

@testset "DrawingDim validation" begin
    @test_throws ArgumentError DIMANGULAR((0.0, 0.0), (0.0, 0.0), (1.0, 0.0))
    @test_throws ArgumentError DIMARC((0.0, 0.0), (0.0, 0.0), (1.0, 0.0))
    @test_throws ArgumentError DIMRADIAL((0.0, 0.0), (0.0, 0.0))
    @test_throws ArgumentError DIMDIAMETER((1.0, 1.0), (1.0, 1.0))
    @test_throws ArgumentError DIMORDINATE((1.0, 2.0); axis=:z)
    @test_throws ArgumentError DIMBASELINE((0.0, 0.0); orientation=:horizontal)
    @test_throws ArgumentError DIMCONTINUE((0.0, 0.0); orientation=:horizontal)
    @test_throws ArgumentError DIMJOGGED((0.0, 0.0), (0.0, 0.0); orientation=:horizontal)
    @test_throws ArgumentError DIMLIMITS(25.0, 25.1, 24.9)
    @test_throws ArgumentError DIMLIMITS(24.8, 24.9, 25.1)
    @test_throws ArgumentError DIMLIMITS(25.2, 24.9, 25.1)
end
