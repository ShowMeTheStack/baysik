' ============================================================
' TITLE:    Circles, Arcs and Ellipses
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     circle, arc, ellipse, aspect, screen 1, cga
' SUMMARY:  Explore CIRCLE's aspect ratio and arc angles in 4-colour CGA, ending with a smiling cartoon face.
' ------------------------------------------------------------
' WHAT IT DOES
'   Works in classic 320x200 CGA mode (SCREEN 1), which has only
'   four colours at once. It shows three stages, one per key
'   press:
'     1. A row of ellipses made by changing the ASPECT number
'     2. Arcs: pieces of circles chosen by start/end angles
'     3. A cartoon face built only from circles and arcs
'
' HOW TO USE
'   Press any key to go to the next stage. Esc quits early.
'
' CONCEPTS YOU WILL LEARN
'   * CIRCLE (x, y), radius, colour, start, end, aspect
'   * Aspect < 1 makes a wide ellipse, aspect > 1 a tall one
'   * Angles are in radians: 0 = right, PI/2 = up, PI = left
'   * Leaving arguments empty with commas: CIRCLE (x,y),r,c,,,2
'   * The CGA palettes: COLOR background, palette
'
' THINGS TO TRY
'   * Change COLOR 1, 0 to COLOR 1, 1 (the other CGA palette)
'   * Give the face ears, or make it frown by flipping the mouth arc
'   * Draw an "egg" from two half-ellipses with different aspects
' ============================================================

CONST PI = 3.14159265#

SCREEN 1             ' 320 x 200, 4 colours
COLOR 1, 0           ' background = blue (1), palette 0 (green/red/brown)
'                      in palette 0: colour 1=green, 2=red, 3=brown/yellow

' ---- Stage 1: the aspect ratio --------------------------------
' The 6th argument of CIRCLE is the aspect: the ratio of the
' vertical radius to the horizontal one. When aspect > 1 the
' radius you give becomes the VERTICAL radius instead.
CLS
PRINT "Stage 1: aspect ratio"
FOR i = 0 TO 6
    asp = .25 * (i + 1)          ' .25, .5, .75 ... 1.75
    x = 25 + i * 45
    CIRCLE (x, 100), 20, (i MOD 3) + 1, , , asp
    LOCATE 18, (x \ 8) - 1: PRINT USING "#.##"; asp
NEXT i
LOCATE 22, 1: PRINT "Wide <-----------------> Tall"
GOSUB WaitKey

' ---- Stage 2: arcs ---------------------------------------------
' CIRCLE (x,y), r, colour, START, END draws only the part of the
' circle between the two angles, going counter-clockwise.
CLS
PRINT "Stage 2: arcs (start to end)"
' A rainbow: concentric half circles from angle 0 to PI.
FOR r = 30 TO 70 STEP 4
    CIRCLE (90, 150), r, (r \ 4) MOD 3 + 1, 0, PI
NEXT r
' "Pac-Man": almost a whole circle, with a gap for the mouth.
' Negative angles also draw the radius lines, closing the shape.
CIRCLE (240, 110), 40, 3, -PI / 6, -(2 * PI - PI / 6)
PAINT (225, 110), 3, 3
CIRCLE (245, 90), 4, 0          ' the eye (drawn in background colour)
PAINT (245, 90), 0, 0
' Food dots
FOR x = 280 TO 310 STEP 15
    CIRCLE (x, 110), 3, 2
    PAINT (x, 110), 2, 2
NEXT x
GOSUB WaitKey

' ---- Stage 3: a face --------------------------------------------
CLS
PRINT "Stage 3: a face from circles"
fx = 160: fy = 110
CIRCLE (fx, fy), 70, 3                          ' head
PAINT (fx, fy), 3, 3                            ' fill it
' Eyes: tall ellipses (aspect 1.6), filled green with black pupils
FOR side = -1 TO 1 STEP 2
    ex = fx + side * 25
    CIRCLE (ex, fy - 18), 12, 1, , , 1.6
    PAINT (ex, fy - 18), 1, 1
    CIRCLE (ex + 3, fy - 15), 4, 0
    PAINT (ex + 3, fy - 15), 0, 0
    ' Eyebrows: small arcs over the top of each eye
    CIRCLE (ex, fy - 18), 22, 2, PI / 4, 3 * PI / 4, 1.2
NEXT side
' Nose: a small red circle
CIRCLE (fx, fy + 5), 6, 2
PAINT (fx, fy + 5), 2, 2
' Smile: the bottom part of a circle - from 200 to 340 degrees.
' Degrees -> radians: multiply by PI / 180.
CIRCLE (fx, fy + 5), 38, 2, 200 * PI / 180, 340 * PI / 180
CIRCLE (fx, fy + 5), 37, 2, 200 * PI / 180, 340 * PI / 180
LOCATE 25, 10: PRINT "Press any key to end";
GOSUB WaitKey
SCREEN 0: WIDTH 80
END

' ---- Subroutine: wait for a key; Esc ends the program ----------
WaitKey:
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
RETURN
