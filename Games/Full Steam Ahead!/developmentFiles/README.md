# Development files

Editable sources for the game's art. `images/<family>/<name>.aseprite` exports to `assets/images/<family>/<name>.png`, and every source uses the palette in `images/palette.gpl`.

This whole folder is excluded from builds (`developmentFiles/*` in `build.settings` `excludeFiles`).

## Which export an image uses

- An image with more than one frame or with a slice is a sheet export (PNG + JSON). A slice with a centre is what makes an image a nine-slice in the game, and only the JSON carries it.
- Every other image is a plain PNG export.
- An image that already has a `.json` beside its `.png` in `assets/images/` is a sheet export.

## Sheet export: File > Export Sprite Sheet

- Layout tab: Sheet type "Horizontal Strip", Constraints none, Merge Duplicates off, Ignore Empty off.
- Sprite tab: Source "Sprite", Layers "Visible layers", Frames "All frames".
- Borders tab: Border Padding 0, Spacing 0, Inner Padding 0, Trim Sprite off, Trim Cels off, Extrude on.
- Output tab: Output File `<name>.png` beside the JSON, JSON Data on, format "Hash", Item Filename and Item Tagname left at their defaults, Meta: Layers, Tags and Slices all on.
- Save both files to `assets/images/<family>/`.

CLI equivalent:

```sh
aseprite -b <name>.aseprite --sheet <name>.png --sheet-type horizontal --extrude --format json-hash --data <name>.json --list-layers --list-tags --list-slices
```

## Plain PNG export: File > Export As

- Save as `assets/images/<family>/<name>.png` at scale 100%, with no JSON.

CLI equivalent:

```sh
aseprite -b <name>.aseprite --save-as <name>.png
```
