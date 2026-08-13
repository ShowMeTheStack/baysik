' ============================================================
' TITLE:    VGA Plasma (POKE &HA000 + Palette Cycling)
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     screen 13, video memory, a000, poke, palette, demoscene
' SUMMARY:  Classic demoscene plasma: POKE 64000 bytes into VGA memory, then animate it by rotating the DAC palette.
' ------------------------------------------------------------
' WHAT IT DOES
'   In SCREEN 13 (320x200, 256 colours) the picture is simply 64000
'   bytes at segment &HA000 - one byte per pixel, row after row:
'       offset = y * 320 + x
'   We POKE a smooth "plasma" pattern into that memory, made by adding
'   several sine waves together.  Drawing it is slow-ish, so we do it
'   only ONCE.  The animation then costs almost nothing: we keep
'   changing what colour each of the 256 byte values MEANS, by writing
'   new red/green/blue values to the VGA DAC through ports &H3C8 and
'   &H3C9.  This trick ("palette cycling") was used in countless 1990s
'   demos.
'
' HOW TO USE
'   Wait for the plasma to draw (a progress bar shows), then enjoy.
'   Keys 1-3 choose a colour scheme.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = &HA000 and the linear pixel layout of mode 13h
'   * Look-up tables: SIN computed once into an INTEGER array
'   * OUT &H3C8, index then OUT &H3C9, r, g, b (each 0..63)
'   * Why changing 768 palette bytes beats redrawing 64000 pixels
'
' THINGS TO TRY
'   * Change the wave frequencies in the plasma formula
'   * Add a fourth wave based on distance from a corner
'   * Speed up the cycle, or make it run backwards
' ============================================================

DEFINT A-Z
DIM sn(255)                    ' sine table: 0..255 in, 0..63 out
DIM pr(255), pg(255), pb(255)  ' the base palette, 0..63 each

SCREEN 13
CONST PI = 3.14159

' ---- 1. sine look-up table ---------------------------------------------
FOR i = 0 TO 255
    sn(i) = 32 + 31 * SIN(i * 2 * PI / 256)
NEXT i

scheme = 1
GOSUB MakePalette
GOSUB SetPalette

' ---- 2. draw the plasma straight into video memory ----------------------
DEF SEG = &HA000
FOR y = 0 TO 199
    off& = y * 320&                     ' start of this row in memory
    ty1 = sn((y * 2) AND 255)
    FOR x = 0 TO 319
        ' four waves: horizontal, vertical, diagonal, and a mixed one
        c = sn((x * 3) AND 255) + ty1 + sn((x + y) AND 255) + sn((x - y * 2 + 512) AND 255)
        POKE off& + x, c AND 255        ' sum is 0..252: one byte per pixel
    NEXT x
    IF INKEY$ = CHR$(27) THEN GOTO Finish
NEXT y
DEF SEG

' ---- 3. animate by rotating the palette ------------------------------
shift = 0
DO
    shift = (shift + 2) AND 255
    ' Wait for vertical retrace so the colour change does not tear.
    WAIT &H3DA, 8
    OUT &H3C8, 0                         ' start writing at colour 0
    FOR i = 0 TO 255
        j = (i + shift) AND 255          ' colour i borrows entry j's RGB
        OUT &H3C9, pr(j): OUT &H3C9, pg(j): OUT &H3C9, pb(j)
    NEXT i                               ' DAC auto-advances to next index

    k$ = INKEY$
    IF k$ >= "1" AND k$ <= "3" THEN scheme = VAL(k$): GOSUB MakePalette
LOOP UNTIL k$ = CHR$(27)

Finish:
DEF SEG
SCREEN 0: WIDTH 80
PRINT "Plasma finished."
END

' ---- build one of three smooth 256-entry colour ramps -----------------
MakePalette:
FOR i = 0 TO 255
    SELECT CASE scheme
        CASE 1   ' fire & ice: phase-shifted sine waves for R, G, B
            pr(i) = sn(i): pg(i) = sn((i + 85) AND 255): pb(i) = sn((i + 170) AND 255)
        CASE 2   ' ocean: blue with green highlights
            pr(i) = 0: pg(i) = sn((i * 2) AND 255) \ 2: pb(i) = sn(i)
        CASE 3   ' lava: red and yellow
            pr(i) = sn(i): pg(i) = sn((i * 2) AND 255) \ 2: pb(i) = 0
    END SELECT
NEXT i
RETURN

SetPalette:
OUT &H3C8, 0
FOR i = 0 TO 255
    OUT &H3C9, pr(i): OUT &H3C9, pg(i): OUT &H3C9, pb(i)
NEXT i
RETURN
