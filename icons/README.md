# Toolbar icons

Current set: Lazarus IDE, `general_purpose` icons by Roland Hahn
(https://www.rhsoft.de/), license Creative Commons CC0 1.0 Universal
(see `png/readme_general_purpose.txt`, `svg/readme_RolandHahn.txt`).

- `png/` - the 24x24 PNG files as they are in Lazarus
  (https://github.com/fpc/Lazarus, `images/general_purpose`).
- `svg/` - SVG sources of the two floppies (`Save_01`, `SaveAs_01`) from
  https://gitlab.com/freepascal.org/lazarus/resources, folder
  `image_sources/images/general_purpose/svg (Roland Hahn)`. The floppy body
  is recoloured from blue to black (grey on the dark strip) by
  `make_icons.py`.

`make_icons.py` puts the icons into two 32-bit strips with premultiplied
alpha (`icons_light.bmp`, `icons_dark.bmp`: 24*15 x 48, row 0 normal,
row 1 disabled) and writes `..\toolbar_icons.res` (same as
`brcc32 toolbar_icons.rc`). The order in the list `ICONS` must match the
constants `IconOpen` .. `IconStepOver` in Unit1.pas. Needs Python 3, Pillow
and cairosvg.

## Old sets (`old/`)

- `old/tiles28` - own flat tiles, 28x28, 24-bit with clFuchsia as the
  transparent colour; generator `make_icons.py` in that folder.
- `old/lazarus28` - the same Lazarus icons rendered from SVG at 28x28
  (its `make_icons.py` has the icon order wrong: SavePrj before Undo).

Each folder has its `toolbar_icons.res`. To go back to one of them, copy it
over `..\toolbar_icons.res` and set `ToolIconSize = 28` in Unit1.pas.
