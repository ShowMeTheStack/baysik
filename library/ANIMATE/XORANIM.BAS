' ============================================================
' TITLE:    XOR Sprite Animation
' CATEGORY: Animation & Sprites
' LEVEL:    Beginner
' TAGS:     animation, sprites, GET, PUT, XOR
' SUMMARY:  A little UFO glides over a striped sky without ever erasing the background - thanks to the magic of XOR.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a UFO once, copies it into an array with GET, then
'   flies it around a figure-eight path over a busy background.
'   Each frame the UFO is PUT on the screen with XOR, shown for
'   a moment, then PUT again with XOR in the same spot - which
'   makes it vanish and restores the background perfectly.
'
' HOW TO USE
'   Just watch.  Press P to switch to PSET mode and see what
'   happens WITHOUT the XOR trick (a smeared trail!).  Press X
'   to go back to XOR mode.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * GET (x1,y1)-(x2,y2), array  - capture a rectangle of pixels
'   * PUT (x,y), array, XOR       - draw it so it can be undone
'   * Why A XOR B XOR B = A (the "draw twice to erase" trick)
'   * Moving along a curve with SIN and COS
'
' THINGS TO TRY
'   * Change the path: try x = 150 + 120 * COS(t) only
'   * Draw your own sprite instead of the UFO
'   * Notice the UFO's colors change over the stripes - why?
' ============================================================
DEFINT A-Z

SCREEN 13           ' 320x200, 256 colors - one byte per pixel

' ---- 1. Draw the sprite in the top-left corner ---------------
' We draw on a black screen so everything that is not the UFO
' is color 0.  With XOR, color 0 changes nothing (N XOR 0 = N),
' so the black corners of the box will be "see-through".
CIRCLE (15, 10), 14, 7, , , .35          ' grey saucer body
PAINT (15, 10), 7, 7
CIRCLE (15, 6), 6, 11, 0, 3.14159        ' glass dome (top half only)
LINE (9, 6)-(21, 6), 11                  ' close the arc so PAINT can't leak out
PAINT (15, 4), 11, 11
PSET (6, 11), 14: PSET (15, 12), 14: PSET (24, 11), 14   ' lights

' GET needs an array big enough for the picture.
' In SCREEN 13 it needs 4 bytes + width*height bytes.
' Our box is 31 x 18 = 558 bytes; an INTEGER is 2 bytes,
' so 300 integers is plenty.
DIM ufo(300)
GET (0, 0)-(30, 17), ufo

' ---- 2. Draw a busy background ------------------------------
CLS
FOR y = 0 TO 199 STEP 10
    LINE (0, y)-(319, y + 9), 32 + (y \ 10), BF    ' colorful stripes
NEXT
FOR i = 1 TO 40                               ' some "stars"
    PSET (RND * 319, RND * 199), 15
NEXT
COLOR 15
LOCATE 1, 1: PRINT "XOR mode  (P=PSET  X=XOR  Esc=quit)"

' ---- 3. Animate ---------------------------------------------
mode = 1            ' 1 = XOR, 2 = PSET
t! = 0
DO
    ' Position along a figure-eight (a Lissajous curve).
    ' COS(t) swings left/right, SIN(2t) swings up/down twice as
    ' fast, which makes the "8" shape.
    x = 145 + 130 * COS(t!)
    y = 95 + 70 * SIN(2 * t!)

    IF mode = 1 THEN
        PUT (x, y), ufo, XOR        ' draw it...
        WAIT &H3DA, 8               ' ...wait for the screen refresh
        FOR d = 1 TO 2: WAIT &H3DA, 8, 8: WAIT &H3DA, 8: NEXT
        PUT (x, y), ufo, XOR        ' ...and XOR again = erased!
    ELSE
        ' PSET copies the box exactly, black corners and all,
        ' and nothing ever cleans up the old copies.
        PUT (x, y), ufo, PSET
        FOR d = 1 TO 3: WAIT &H3DA, 8, 8: WAIT &H3DA, 8: NEXT
    END IF

    t! = t! + .03

    k$ = UCASE$(INKEY$)
    IF k$ = "P" THEN mode = 2: LOCATE 1, 1: PRINT "PSET"
    IF k$ = "X" THEN mode = 1: LOCATE 1, 1: PRINT "XOR "
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
PRINT "Bye!"
