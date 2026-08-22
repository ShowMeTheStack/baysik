' ============================================================
' TITLE:    Shapes and Angles
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     geometry, angles, polygons, trigonometry, graphics
' SUMMARY:  Draw regular polygons, turn an angle with the arrow keys, and guess angles by eye.
' ------------------------------------------------------------
' WHAT IT DOES
'   1) Polygon maker: choose a number of sides and see the regular
'      shape drawn, with its interior angle, exterior angle and the
'      sum of all its angles.
'   2) Angle explorer: turn a line with the arrow keys and watch the
'      angle grow.  The program names it - acute, right, obtuse,
'      straight or reflex - and draws the arc.
'   3) Estimate it: an angle is drawn; guess how many degrees.  Get
'      within 10 degrees to score!
'
' HOW TO USE
'   Pick 1-3 on the menu, Q to quit.  In the explorer use the Left and
'   Right arrows to turn 1 degree at a time, + and - for 15 degree
'   steps, and Esc to go back.
'
' CONCEPTS YOU WILL LEARN
'   * Degrees vs radians: radians = degrees * pi / 180
'   * Interior angle of a regular n-gon = (n - 2) * 180 / n
'   * Drawing arcs with CIRCLE's start and end angles
'   * Reading arrow keys: INKEY$ gives CHR$(0) + a code
'
' THINGS TO TRY
'   * Draw star polygons by joining every 2nd or 3rd corner
'   * Show both the angle and its "partner" (360 - angle)
'   * Make the estimate game harder: within 5 degrees
' ============================================================

DECLARE SUB DrawAngle (deg!)
DECLARE FUNCTION AngleName$ (deg!)
CONST PI = 3.14159265#
CONST CX = 320, CY = 260
RANDOMIZE TIMER
SCREEN 12

DO
    CLS
    COLOR 14: LOCATE 3, 30: PRINT "SHAPES AND ANGLES"
    COLOR 15
    LOCATE 7, 25: PRINT "1) Polygon maker"
    LOCATE 8, 25: PRINT "2) Angle explorer"
    LOCATE 9, 25: PRINT "3) Estimate the angle"
    LOCATE 10, 25: PRINT "Q) Quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "1": GOSUB Polygons
        CASE "2": GOSUB Explorer
        CASE "3": GOSUB Estimate
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0
END

' ------------------------------------------------------------
Polygons:
    DO
        CLS
        COLOR 15: LOCATE 2, 3: INPUT "How many sides (3-12, 0 = back)"; n
        IF n < 3 OR n > 12 THEN RETURN
        n = INT(n)
        r = 150
        ' The corners sit evenly round a circle, 360/n degrees apart.
        ' Starting at -90 degrees puts the first corner at the top.
        FOR i = 0 TO n
            a = (-90 + i * 360 / n) * PI / 180
            x = CX + r * COS(a): y = CY + r * SIN(a)
            IF i = 0 THEN PSET (x, y), 14 ELSE LINE -(x, y), 14
        NEXT i
        PAINT (CX, CY), 1, 14
        CIRCLE (CX, CY), r, 8                    ' the circle they sit on
        RESTORE ShapeNames
        FOR i = 3 TO n: READ nm$: NEXT i
        inner = (n - 2) * 180 / n
        COLOR 11
        LOCATE 4, 3: PRINT "A regular "; nm$; " has"; n; "equal sides."
        LOCATE 5, 3: PRINT USING "Each inside angle  = (## - 2) x 180 / ## = ###.# degrees"; n; n; inner
        LOCATE 6, 3: PRINT USING "Each outside angle = 360 / ## = ##.# degrees"; n; 360 / n
        LOCATE 7, 3: PRINT USING "All inside angles add up to #,### degrees"; (n - 2) * 180
        COLOR 7: LOCATE 29, 3: PRINT "Inside + outside angle always = 180.  Press a key...";
        DO: LOOP WHILE INKEY$ = ""
    LOOP

ShapeNames:
DATA triangle, square, pentagon, hexagon, heptagon, octagon
DATA nonagon, decagon, hendecagon, dodecagon

' ------------------------------------------------------------
Explorer:
    deg = 45
    DO
        CLS
        DrawAngle deg
        COLOR 15: LOCATE 2, 3: PRINT "Left/Right = 1 degree,  - / + = 15 degrees,  Esc = back"
        COLOR 14: LOCATE 26, 30: PRINT USING "### degrees"; deg
        COLOR 11: LOCATE 27, 30: PRINT AngleName$(deg)
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
        SELECT CASE k$
            CASE CHR$(0) + "M": deg = deg - 1      ' right arrow: clockwise
            CASE CHR$(0) + "K": deg = deg + 1      ' left arrow: anticlockwise
            CASE "+", "=": deg = deg + 15
            CASE "-", "_": deg = deg - 15
            CASE CHR$(27), "q", "Q": RETURN
        END SELECT
        ' keep the angle between 0 and 359
        IF deg < 0 THEN deg = deg + 360
        IF deg >= 360 THEN deg = deg - 360
    LOOP

' ------------------------------------------------------------
Estimate:
    score = 0
    FOR round = 1 TO 5
        CLS
        deg = INT(RND * 34 + 1) * 10 + INT(RND * 10)   ' 10 .. 349
        DrawAngle deg
        COLOR 15: LOCATE 2, 3: PRINT "Round"; round; "of 5.  Score:"; score
        LOCATE 27, 20: INPUT "How many degrees do you think"; g
        diff = ABS(g - deg)
        LOCATE 28, 20
        IF diff <= 10 THEN
            COLOR 10: PRINT "Great eye! It was"; deg; "degrees.": score = score + 1
        ELSE
            COLOR 12: PRINT "It was"; deg; "degrees - you were"; diff; "away."
        END IF
        COLOR 7: LOCATE 29, 20: PRINT "Press a key...";
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        IF k$ = CHR$(27) THEN EXIT FOR
    NEXT round
    CLS: COLOR 14: LOCATE 12, 25: PRINT "You scored"; score; "out of 5!"
    LOCATE 14, 25: PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
    RETURN

' ------------------------------------------------------------
' DrawAngle: a fixed arm pointing right, a turning arm at deg
' degrees (measured anticlockwise, like a protractor), and an arc.
' ------------------------------------------------------------
SUB DrawAngle (deg)
    r = 180
    a = deg * PI / 180
    LINE (CX, CY)-(CX + r, CY), 15                       ' fixed arm
    LINE (CX, CY)-(CX + r * COS(a), CY - r * SIN(a)), 14 ' turning arm
    ' CIRCLE draws arcs anticlockwise from start to end (in radians).
    IF deg > 0 THEN
        IF deg = 90 THEN
            ' a right angle is marked with a little square, not an arc
            LINE (CX, CY - 20)-(CX + 20, CY), 10, B
        ELSE
            CIRCLE (CX, CY), 40, 10, 0, a
        END IF
    END IF
    ' protractor-style tick marks every 30 degrees
    FOR t = 0 TO 330 STEP 30
        ta = t * PI / 180
        LINE (CX + 190 * COS(ta), CY - 190 * SIN(ta))-(CX + 200 * COS(ta), CY - 200 * SIN(ta)), 8
    NEXT t
END SUB

FUNCTION AngleName$ (deg)
    SELECT CASE deg
        CASE 0: AngleName$ = "zero angle"
        CASE IS < 90: AngleName$ = "ACUTE  (less than 90)"
        CASE 90: AngleName$ = "RIGHT ANGLE  (exactly 90)"
        CASE IS < 180: AngleName$ = "OBTUSE  (between 90 and 180)"
        CASE 180: AngleName$ = "STRAIGHT  (exactly 180)"
        CASE ELSE: AngleName$ = "REFLEX  (more than 180)"
    END SELECT
END FUNCTION
