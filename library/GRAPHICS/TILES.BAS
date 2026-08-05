' ============================================================
' TITLE:    PAINT Tile Pattern Gallery
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     paint, tiles, bits, chr$, screen 1, cga
' SUMMARY:  Fills shapes with home-made patterns by passing a tile string to PAINT, and explains how the bits map to pixels.
' ------------------------------------------------------------
' WHAT IT DOES
'   PAINT can fill an area with a repeating pattern instead of a
'   single colour. The pattern is a "tile" string: each character
'   is one row of the tile. This program builds eight tiles for
'   CGA 4-colour mode (SCREEN 1), fills eight boxes with them,
'   then fills a big circle with a plaid pattern.
'
' HOW TO USE
'   Press any key to see the plaid-filled circle, then any key
'   again to quit.
'
' CONCEPTS YOU WILL LEARN
'   * PAINT (x, y), tile$, border
'   * In SCREEN 1 every pixel uses 2 bits, so one byte = 4 pixels
'       bits:  76 54 32 10   ->  pixel 1, 2, 3, 4 (left to right)
'       00 = colour 0, 01 = colour 1, 10 = colour 2, 11 = colour 3
'   * Building strings of bytes with CHR$ and &H hex numbers
'   * A tile can be up to 64 rows tall
'
' THINGS TO TRY
'   * Design your own tile on graph paper, then convert to hex
'   * Make a checkerboard: rows alternate &H33 and &HCC
'   * Try COLOR 0, 1 for the cyan/magenta/white palette
' ============================================================

DIM tile$(8), label$(8)

' ---- Build the tiles -------------------------------------------
' Handy byte values (each is 4 pixels of the same colour):
'   &H00 = 0000 0000 = four pixels of colour 0 (background)
'   &H55 = 0101 0101 = four pixels of colour 1
'   &HAA = 1010 1010 = four pixels of colour 2
'   &HFF = 1111 1111 = four pixels of colour 3
tile$(1) = CHR$(&H55): label$(1) = "Solid 1"
tile$(2) = CHR$(&HFF) + CHR$(&H00): label$(2) = "H-stripe"
tile$(3) = CHR$(&HCC): label$(3) = "V-stripe"           ' 11 00 11 00
tile$(4) = CHR$(&HC0) + CHR$(&H30) + CHR$(&H0C) + CHR$(&H03)
label$(4) = "Diagonal"                                   ' one pixel moves right each row
tile$(5) = CHR$(&H3C) + CHR$(&HC3): label$(5) = "Checker"
tile$(6) = CHR$(&H5A) + CHR$(&HA5): label$(6) = "2-colour"
tile$(7) = CHR$(&H80) + CHR$(0) + CHR$(&H08) + CHR$(0): label$(7) = "Dots"
tile$(8) = CHR$(&HFF) + CHR$(&HC3) + CHR$(&HC3) + CHR$(&HFF): label$(8) = "Windows"

SCREEN 1
COLOR 0, 0                       ' black background, palette 0
CLS
PRINT " PAINT with tile strings"

' ---- Draw 8 boxes in a 4 x 2 grid and fill each one -----------
FOR i = 1 TO 8
    col = (i - 1) MOD 4
    row = (i - 1) \ 4
    x1 = 10 + col * 78: y1 = 24 + row * 84
    x2 = x1 + 68: y2 = y1 + 60
    ' The border MUST be one solid colour so PAINT knows where to
    ' stop. We use colour 3 for every border.
    LINE (x1, y1)-(x2, y2), 3, B
    ' PAINT (point inside), tile pattern, border colour
    PAINT (x1 + 5, y1 + 5), tile$(i), 3
    LOCATE (y2 \ 8) + 2, (x1 \ 8) + 1: PRINT label$(i);
NEXT i
LOCATE 25, 8: PRINT "Press a key...";
DO: LOOP WHILE INKEY$ = ""

' ---- A plaid-filled circle --------------------------------------
' Remember: in SCREEN 1 a tile is always ONE byte wide (4 pixels)
' and every CHR$ adds another ROW. Here is a 4 x 4 tile:
'   &H6A = 01 10 10 10 = green, red, red, red
'   &H55 = 01 01 01 01 = green, green, green, green
' Three red rows with a green edge, then a solid green row,
' repeated over and over, looks like a tablecloth.
plaid$ = CHR$(&H6A) + CHR$(&H6A) + CHR$(&H6A) + CHR$(&H55)

CLS
PRINT " A plaid-filled circle"
CIRCLE (160, 105), 80, 3
PAINT (160, 105), plaid$, 3
LOCATE 25, 8: PRINT "Press a key to quit";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END
