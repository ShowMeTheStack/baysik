' ============================================================
' TITLE:    Pie Chart Maker
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     circle, pie chart, paint, data, screen 9
' SUMMARY:  Turns a table of numbers into a labelled, colour-filled pie chart using CIRCLE wedges and PAINT.
' ------------------------------------------------------------
' WHAT IT DOES
'   Reads a small table of "favourite fruit" votes from DATA
'   statements, works out what fraction of the whole each one
'   is, and draws a pie chart in EGA 640x350 (SCREEN 9). Each
'   slice is filled with its own colour and a legend shows the
'   names and percentages.
'
' HOW TO USE
'   Run it. Press any key to exit. Edit the DATA lines at the
'   bottom to chart your own numbers.
'
' CONCEPTS YOU WILL LEARN
'   * CIRCLE with start and end angles (arcs)
'   * NEGATIVE angles: CIRCLE draws a radius line to the centre,
'     which is how pie wedges are made
'   * Radians: a full turn is 2 * PI
'   * PAINT (flood fill) from a point inside each wedge
'   * Aspect ratio: why circles need "squashing" on EGA screens
'
' THINGS TO TRY
'   * Add more DATA rows (up to 12 slices)
'   * "Explode" a slice by moving its centre outward a little
'   * Draw a second, smaller pie for a different data set
' ============================================================

CONST PI = 3.14159265#
CONST MAXSLICE = 12

DIM nm$(MAXSLICE), v(MAXSLICE)

' ---- Read the data -------------------------------------------
' The first DATA item tells us how many rows follow.
READ title$, n
total = 0
FOR i = 1 TO n
    READ nm$(i), v(i)
    total = total + v(i)
NEXT i

SCREEN 9                     ' 640x350, 16 colours
CLS
COLOR 15
LOCATE 2, 40 - LEN(title$) \ 2: PRINT title$

' Centre and radius of the pie.
cx = 220: cy = 185: r = 140

' On SCREEN 9 the pixels are taller than they are wide, so
' CIRCLE automatically squashes the shape (aspect ~0.73) to look
' round on a real monitor. We must use the same factor when we
' compute where to PAINT, otherwise we would aim outside a slice.
asp = (350 / 640) * (4 / 3)

' ---- Draw the slices -----------------------------------------
' Angles in CIRCLE are measured in radians, counter-clockwise,
' starting from the 3 o'clock position.
a1 = .0001                   ' start just above 0 (see note below)
FOR i = 1 TO n
    frac = v(i) / total
    a2 = a1 + frac * 2 * PI
    IF a2 > 2 * PI THEN a2 = 2 * PI
    c = (i MOD 14) + 1        ' colours 1..14

    ' NOTE: a minus sign on an angle tells CIRCLE "also draw the
    ' radius from the centre to this end of the arc". -0 is the
    ' same as 0, so we never start at exactly 0 - that is why a1
    ' began at a tiny positive number.
    CIRCLE (cx, cy), r, 15, -a1, -a2

    ' Flood-fill the wedge: pick a point halfway out along the
    ' middle angle of the slice. Y goes DOWN the screen, so we
    ' subtract the sine part.
    mid = (a1 + a2) / 2
    px = cx + COS(mid) * r * .6
    py = cy - SIN(mid) * r * .6 * asp
    PAINT (px, py), c, 15

    ' Legend entry: a small filled box plus text.
    ly = 56 + (i - 1) * 28          ' 28 pixels = two text rows
    LINE (420, ly + 1)-(436, ly + 12), c, BF
    LINE (420, ly + 1)-(436, ly + 12), 15, B
    LOCATE ly \ 14 + 1, 57
    PRINT USING "\         \ ###  ##.#%"; nm$(i); v(i); frac * 100

    a1 = a2
NEXT i

LOCATE 24, 52: PRINT USING "Total votes: ####"; total
LOCATE 25, 2: PRINT "Press any key...";
SLEEP
SCREEN 0: WIDTH 80
END

' ---- The data -------------------------------------------------
' Title, number of rows, then name/value pairs.
DATA "Favourite Fruit Survey", 6
DATA "Apples", 34
DATA "Bananas", 21
DATA "Cherries", 12
DATA "Grapes", 18
DATA "Mangoes", 27
DATA "Oranges", 15
