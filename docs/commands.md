# Command Reference

All points can be passed as `(x, y)` tuples or `Point2D`.

## Style

### DIMSTYLE
Set active global style.

```julia
DIMSTYLE(
    text_height=8.0,
    arrow_size=3.0,
    arrowhead_style=:small_open,
    decimals=2,
    unit_suffix=" mm",
    text_font="Helvetica",
    text_orientation=:aligned,
    text_placement=:above,
    fit_mode=:best,
    hand_drawn=false,
    tolerance_mode=:symmetric,
    tolerance_plus=0.05,
)
```

Style option notes:

- `arrowhead_style`: `:closed_filled`, `:closed`, `:closed_blank`, `:open`, `:open30`, `:open90`, `:open_out`, `:open30_out`, `:open90_out`, `:small_open`, `:oblique`, `:tick`, `:dot`, `:dot_small`, `:hook`, `:none`
- `text_font`: font family hint for plot annotation text (GR-safe default is `Helvetica`)
- `text_orientation`: `:aligned`, `:horizontal`, `:vertical`
- `text_placement`: `:above`, `:below`, `:centered`
- `fit_mode`: `:best`, `:text_inside`, `:text_outside`
- `hand_drawn`: when `true`, dimension lines are rendered with a sketch-like wobble
- `tolerance_mode`: `:symmetric`, `:deviation`, `:none`

## Linear-family commands

### DIMLINEAR
Horizontal/vertical linear dimensions.

```julia
d = DIMLINEAR((0, 0), (40, 0); orientation=:horizontal, offset=10)
```

### DIMALIGNED
True-length aligned dimension.

```julia
d = DIMALIGNED((0, 0), (30, 20); offset=10)
```

### DIMBASELINE
Stack dimensions from one base point.

```julia
ds = DIMBASELINE((0, 0), (20, 0), (40, 0), (60, 0); orientation=:horizontal, offset=10)
```

### DIMCONTINUE
Chain dimensions from consecutive points.

```julia
ds = DIMCONTINUE((0, 0), (20, 0), (40, 0), (60, 0); orientation=:horizontal, offset=6)
```

### DIMJOGGED
Linear dimension with jog break.

```julia
d = DIMJOGGED((0, 10), (80, 10); orientation=:horizontal, offset=12, jog_size=5)
```

## Angular/arc commands

### DIMANGULAR
Dimension angle between two rays.

```julia
d = DIMANGULAR((0, 0), (20, 0), (10, 15); radius=14)
```

### DIMARC
Dimension arc length.

```julia
d = DIMARC((0, 0), (20, 0), (0, 20); radius=20)
```

## Circle and coordinate commands

### DIMCENTER
Center mark (crosshair).

```julia
d = DIMCENTER((25, 25); size=8)
```

### DIMRADIAL
Radius dimension.

```julia
d = DIMRADIAL((25, 25), (35, 25); offset=8)
```

### DIMDIAMETER
Diameter dimension.

```julia
d = DIMDIAMETER((25, 25), (25, 35))
```

### DIMORDINATE
Ordinate value from an origin.

```julia
dx = DIMORDINATE((60, 25); axis=:x, origin=(0, 0), offset=10)
dy = DIMORDINATE((60, 25); axis=:y, origin=(0, 0), offset=10)
```

## Plot integration

All dimension objects are directly plottable.

```julia
plot(legend=false, aspect_ratio=:equal)
plot!(d)
plot!(ds) # for vectors from DIMBASELINE or DIMCONTINUE
```
