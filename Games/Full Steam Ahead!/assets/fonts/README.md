# Fonts

Pixelify Sans, licensed under the SIL Open Font License 1.1 (`OFL.txt`).

## Source

- File: [PixelifySans[wght].ttf at google/fonts 47d54ca1](https://github.com/google/fonts/blob/47d54ca1ebb14fd864695f1d39dc734f39017c33/ofl/pixelifysans/PixelifySans%5Bwght%5D.ttf)
- SHA-256: `9ba86cd010a4de309d263ceff8e8044092c9db7efda869620cb9ff1c4389e8a5`
- `OFL.txt` comes from the same folder at the same commit.

## Static instances

google/fonts ships this family only as a variable font, so both files are static instances cut with fontTools 4.63.0:

```sh
python3 -m fontTools.varLib.instancer "PixelifySans[wght].ttf" wght=400 --static --update-name-table -o PixelifySans-Regular.ttf
python3 -m fontTools.varLib.instancer "PixelifySans[wght].ttf" wght=700 --static --update-name-table -o PixelifySans-Bold.ttf
```

The Solar2D Windows font loader deduplicates fonts by family name, so the Bold instance is renamed to its own family with fontTools after instancing:

- Name ID 1 (family) and 4 (full name): `Pixelify Sans Bold`
- Name ID 2 (subfamily): `Regular`
- Name ID 6 (PostScript name): `PixelifySansBold-Regular`, with name ID 3 updated to match
- Name IDs 16 and 17 removed, `OS/2.fsSelection` set to Regular, the `head.macStyle` bold bit cleared

## Hashes

- `PixelifySans-Regular.ttf` (wght 400): `33ce373d95e13a88f2d740a0e7bfbfb089d4e54f85c4ac7ae93b197fa49aac79`
- `PixelifySans-Bold.ttf` (wght 700, renamed): `bd586ccad0ae9e27179f81de5bd4b900cad8d5f97cd147acb5601d326317b7ea`

*This file will be excluded from builds.*
