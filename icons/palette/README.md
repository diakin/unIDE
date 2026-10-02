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

## Without Python: the editor's own icon window

View - Palette Icons (or right click on a palette button - Edit Icon) opens
`DlgIconEdit`: the list of icons, the script one command per line, a live
preview for the light and the dark theme (x4 and real size, coordinates
under the mouse), a colour picker that inserts `@ RRGGBB`. Apply writes
`palette_icons.txt` next to the exe (lines `Class=script`); a script there
replaces the built-in one at start and right after Apply. "Built-in" removes
the own script. The Python files are only needed to move icons into
`DsgIcons.pas` for good.
