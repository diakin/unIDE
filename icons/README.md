# Toolbar icons

Source: Lazarus IDE, `general_purpose` icon set by Roland Hahn (https://www.rhsoft.de/),
license Creative Commons CC0 1.0 Universal (see `svg/readme_RolandHahn.txt`).
SVG files in `svg/` are copied from
https://gitlab.com/freepascal.org/lazarus/resources, folder
`image_sources/images/general_purpose/svg (Roland Hahn)`.

Changes: the floppy body in `Save_01` and `SaveAs_01` is recoloured
(black on the light theme, grey on the dark theme) by `make_icons.py`.

`make_icons.py` renders the icons at 28x28 into two 32-bit strips with
premultiplied alpha (`icons_light.bmp`, `icons_dark.bmp`, row 0 normal,
row 1 disabled) and writes `..\toolbar_icons.res` (same as
`brcc32 toolbar_icons.rc`). Needs Python 3, Pillow and cairosvg.
