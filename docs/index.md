# DrawingDim Docs

DrawingDim provides AutoCAD-style 2D dimensioning utilities for Julia and integrates directly with `Plots.jl` through recipes.

## Documentation map

- [Command Reference](commands.md)
- [Formatters](formatters.md)
- [Examples Guide](examples.md)
- [Registry Registration Guide](registration.md)

## Quick setup

```julia
using Pkg
Pkg.develop(path=".")
Pkg.instantiate()
```

## Quick use

```julia
using DrawingDim
using Plots

DIMSTYLE(decimals=2, unit_suffix=" mm", text_height=8.0)

d = DIMLINEAR((0.0, 0.0), (20.0, 0.0); orientation=:horizontal, offset=8)

plot(legend=false, aspect_ratio=:equal)
plot!(d)
```
