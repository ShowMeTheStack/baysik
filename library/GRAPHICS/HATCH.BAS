' ============================================================
' TITLE:    Hatching Pattern Catalogue
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     hatching, paint, tiles, monochrome, pie chart, screen 2
' SUMMARY:  Shows twelve 8x8 hatch patterns for black-and-white graphics, then uses them to shade a pie chart with no colour at all.
' ------------------------------------------------------------
' WHAT IT DOES
'   Before colour printers, charts and technical drawings used
'   HATCHING - patterns of lines and dots - to tell areas apart.
'   In SCREEN 2 (640x200, black and white) every pixel is ONE bit,
'   so a single byte describes 8 pixels in a row, and a tile of 8
'   bytes is an 8 x 8 pattern. Part 1 shows a catalogue of twelve
'   patterns with their hex codes; Part 2 shades a pie chart
'   with them.
'
' HOW TO USE
'   Press a key to go from the catalogue to the pie chart, and
'   again to quit.
'
' CONCEPTS YOU WILL LEARN
'   * 1-bit-per-pixel tiles: bit 7 = leftmost pixel
'   * Building pattern strings from hex DATA with CHR$(VAL("&H"..))
'   * PAINT (x, y), tile$, border
'   * Pie slices with negative CIRCLE angles
'
' THINGS TO TRY
'   * Design a brick or "basket weave" tile on squared paper
'   * Add a 13th pattern: a solid black "gap" (&H00) is allowed
'     as long as the whole tile is not the background colour
'   * Draw a bar chart shaded with these hatches
' ============================================================

CONST PI = 3.14159265#
CONST NPAT = 12
DIM pat$(NPAT), nm$(NPAT), hx$(NPAT)

' ---- Read the patterns ----------------------------------------
' Each pattern is a name followed by 8 hex bytes (rows 0..7).
FOR p = 1 TO NPAT
    READ nm$(p)
    pat$(p) = "": hx$(p) = ""
    FOR row = 1 TO 8
        READ h$
        pat$(p) = pat$(p) + CHR$(VAL("&H" + h$))
        IF row <= 2 THEN hx$(p) = hx$(p) + h$ + " "
    NEXT row
NEXT p

SCREEN 2
CLS

' ---- Part 1: the catalogue (4 across, 3 down) -------------------
PRINT "  Hatch patterns for SCREEN 2  (8 x 8 tiles, first two rows shown in hex)"
FOR p = 1 TO NPAT
    col = (p - 1) MOD 4: row = (p - 1) \ 4
    x1 = 20 + col * 155: y1 = 16 + row * 60
    LINE (x1, y1)-(x1 + 120, y1 + 36), 1, B
    PAINT (x1 + 2, y1 + 2), pat$(p), 1
    LOCATE (y1 + 36) \ 8 + 2, x1 \ 8 + 1
    PRINT nm$(p); " "; hx$(p);
NEXT p
LOCATE 25, 30: PRINT "Press a key...";
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END

' ---- Part 2: a hatched pie chart -----------------------------------
CLS
PRINT "  Energy sources (monochrome pie chart)"
DIM v(6), lab$(6)
total = 0
FOR i = 1 TO 6: READ lab$(i), v(i): total = total + v(i): NEXT i

cx = 200: cy = 105: r = 160
a1 = .0001                              ' never use exactly 0 (see PIECHART)
FOR i = 1 TO 6
    a2 = a1 + v(i) / total * 2 * PI
    IF a2 > 2 * PI THEN a2 = 2 * PI
    CIRCLE (cx, cy), r, 1, -a1, -a2
    ' A point inside the slice. SCREEN 2 squashes circles a lot
    ' (aspect about 0.42), so we squash the y offset to match.
    m = (a1 + a2) / 2
    PAINT (cx + COS(m) * r * .55, cy - SIN(m) * r * .55 * .42), pat$(i * 2 - 1), 1
    a1 = a2
    ' Legend box with the same pattern
    ly = 30 + (i - 1) * 24
    LINE (420, ly)-(460, ly + 14), 1, B
    PAINT (422, ly + 2), pat$(i * 2 - 1), 1
    LOCATE ly \ 8 + 2, 60: PRINT USING "\          \ ##%"; lab$(i); v(i) / total * 100
NEXT i
LOCATE 25, 30: PRINT "Press a key to quit";
DO: LOOP WHILE INKEY$ = ""
SCREEN 0: WIDTH 80
END

' ---- Pattern data: name, then 8 rows in hex ----------------------
DATA "Horizontal", FF,00,00,00,FF,00,00,00
DATA "Vertical  ", 88,88,88,88,88,88,88,88
DATA "Diagonal /", 01,02,04,08,10,20,40,80
DATA "Diagonal \", 80,40,20,10,08,04,02,01
DATA "Cross     ", FF,88,88,88,FF,88,88,88
DATA "Diag cross", 81,42,24,18,18,24,42,81
DATA "Dots      ", 80,00,08,00,80,00,08,00
DATA "Dense dots", AA,55,AA,55,AA,55,AA,55
DATA "Bricks    ", FF,80,80,80,FF,08,08,08
DATA "Zigzag    ", 81,42,24,18,81,42,24,18
DATA "Scales    ", 18,24,42,81,00,00,00,00
DATA "Thick /   ", 03,06,0C,18,30,60,C0,81
' ---- Pie data -------------------------------------------------------
DATA "Solar", 18, "Wind", 24, "Hydro", 15, "Gas", 22, "Nuclear", 12, "Other", 9
