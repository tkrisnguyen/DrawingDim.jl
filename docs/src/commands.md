```@meta
CurrentModule = DrawingDim
```

# Command Reference

`DrawingDim` provides AutoCAD-style commands:

- `DIMSTYLE`
- `DIMLINEAR`, `DIMALIGNED`, `DIMANGULAR`, `DIMARC`
- `DIMCENTER`, `DIMJOGGED`
- `DIMRADIAL`, `DIMDIAMETER`, `DIMORDINATE`
- `DIMBASELINE`, `DIMCONTINUE`

## Arrow styles

- `:closed_filled`
- `:closed`
- `:closed_blank`
- `:open`
- `:open30`
- `:open90`
- `:open_out`
- `:open30_out`
- `:open90_out`
- `:small_open`
- `:oblique`
- `:hook`
- `:tick`
- `:dot`
- `:dot_small`
- `:none`

## Text behavior

- `text_orientation`: `:aligned`, `:horizontal`, `:vertical`
- `text_placement`: `:above`, `:below`, `:centered`
- `fit_mode`: `:best`, `:text_inside`, `:text_outside`
