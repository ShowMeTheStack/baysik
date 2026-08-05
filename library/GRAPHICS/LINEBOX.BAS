' ============================================================
' TITLE:    LINE Boxes and Styles
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     line, box, styles, screen 12, colors
' SUMMARY:  A tour of the LINE statement: plain lines, outlined boxes, filled boxes and dashed line styles.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a sampler sheet in 640x480 16-color VGA (SCREEN 12)
'   showing everything the LINE statement can do: ordinary
'   lines, the B (box) and BF (box filled) options, relative
'   coordinates with STEP, and 16-bit dash "styles".
'
' HOW TO USE
'   Just run it and look. Press any key to finish.
'
' CONCEPTS YOU WILL LEARN
'   * LINE (x1,y1)-(x2,y2), color
'   * LINE ... , B   and   LINE ... , BF
'   * The STEP keyword for coordinates relative to the last point
'   * Line styles: a 16-bit pattern such as &HF0F0
'   * Using FOR loops to make patterns from simple lines
'
' THINGS TO TRY
'   * Invent your own style numbers (try &HAAAA or &H8888)
'   * Change the step size in the "fan" loop
'   * Nest more boxes inside one another
' ============================================================

SCREEN 12            ' 640 x 480 pixels, 16 colors
CLS

' ---- Section 1: a fan of plain lines --------------------------
' Every line starts at the same corner and ends somewhere along
' the bottom edge of the panel. The color changes each time.
LOCATE 1, 2: PRINT "Plain lines"
FOR x = 10 TO 200 STEP 10
    c = (x \ 10) MOD 15 + 1          ' colors 1..15 (skip black)
    LINE (10, 30)-(x, 200), c
NEXT x

' ---- Section 2: outlined boxes (option B) ---------------------
' With ", B" LINE treats the two points as opposite corners of a
' rectangle and draws only the outline.
LOCATE 1, 30: PRINT "Boxes (B)"
FOR i = 0 TO 7
    LINE (230 + i * 8, 30 + i * 8)-(420 - i * 8, 200 - i * 8), i + 8, B
NEXT i

' ---- Section 3: filled boxes (option BF) ----------------------
' ", BF" fills the rectangle solidly. Here we build a staircase
' of colored blocks - like a little bar chart.
LOCATE 1, 57: PRINT "Filled boxes (BF)"
FOR i = 0 TO 7
    LINE (450 + i * 22, 200 - i * 20)-(468 + i * 22, 200), i + 1, BF
NEXT i

' ---- Section 4: line styles -----------------------------------
' The last argument is a 16-bit "style" mask. Each 1 bit draws a
' pixel and each 0 bit skips one; the pattern then repeats.
'   &HFFFF = 1111111111111111 = solid
'   &HF0F0 = 1111000011110000 = dashes
'   &HAAAA = 1010101010101010 = dotted
'   &HFF18 = 1111111100011000 = dash-dot
LOCATE 15, 2: PRINT "Line styles"
RESTORE StyleData
FOR i = 0 TO 5
    READ s&, nm$
    y = (15 + i) * 16 + 8          ' middle of text row 16+i
    LINE (120, y)-(400, y), 14, , s&
    LOCATE 16 + i, 2: PRINT nm$
NEXT i

' Styles also work on boxes - a dashed frame around section 4.
LINE (5, 225)-(410, 360), 7, B, &HCCCC

' ---- Section 5: STEP (relative coordinates) -------------------
' STEP(dx,dy) means "this far from the last point drawn". A short
' list of moves draws a staircase without computing absolute
' positions yourself.
LOCATE 15, 57: PRINT "STEP moves"
PSET (450, 380), 10                  ' set the starting point
FOR i = 1 TO 8
    LINE -STEP(20, 0), 10            ' right 20
    LINE -STEP(0, -20), 10           ' up 20
NEXT i

' A box drawn with STEP: the second corner is relative to the first.
LINE (460, 400)-STEP(140, 50), 12, B

' ---- Section 6: a bonus pattern -------------------------------
' Connecting points on two edges makes a curve out of straight
' lines (the "string art" trick).
FOR i = 0 TO 20
    LINE (20 + i * 18, 470)-(20, 380 + i * 4.5), 11
NEXT i

LOCATE 29, 50: PRINT "Press any key...";
SLEEP
SCREEN 0: WIDTH 80
END

StyleData:
DATA &HFFFF, "Solid"
DATA &HF0F0, "Dashes"
DATA &HAAAA, "Dots"
DATA &HFF18, "Dash-dot"
DATA &HFFC0, "Long dash"
DATA &H8888, "Sparse"
