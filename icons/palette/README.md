# Palette icons (DsgIcons.pas)

Smooth icons of the component palette are drawn in code from short scripts
(format: see the header of `DsgIcons.pas`).

- `icons.py` - the scripts, one per component class (`ICONS`), and aliases
  for own components whose analog has another name (`ALIAS`).
- `render.py` - preview: `python3 render.py` writes `sheet_light.png` and
  `sheet_dark.png` with every icon at 2x and 1x. Needs Pillow and the
  Liberation Sans font (metrics of Arial, which the editor uses).
- `gen.py` - `python3 gen.py` writes `..\..\DsgIcons.pas` (CP1251, CRLF)
  from `icons.py`.

Edit `icons.py`, check the preview, run `gen.py`, rebuild the editor.
