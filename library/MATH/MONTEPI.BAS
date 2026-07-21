' ============================================================
' TITLE:    Monte Carlo Pi
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     pi, probability, random numbers, simulation, graphics
' SUMMARY:  Estimates pi by throwing random darts at a square with a circle inside it.
' ------------------------------------------------------------
' WHAT IT DOES
'   Imagine a square dartboard 2 units wide with a circle of radius 1
'   drawn inside it.  Throw darts completely at random.
'      area of circle / area of square = (pi * 1^2) / (2 * 2) = pi / 4
'   So the fraction of darts landing inside the circle should be close
'   to pi/4, which means   pi  ~  4 * (darts inside) / (darts thrown).
'   Methods that use randomness like this are called "Monte Carlo"
'   methods, after the famous casino.
'
' HOW TO USE
'   Watch the darts fly.  Green = inside the circle, red = outside.
'   The estimate updates on the right.  Press Esc or Q to stop.
'
' CONCEPTS YOU WILL LEARN
'   * RND and RANDOMIZE TIMER for random numbers
'   * Pythagoras: a point (x, y) is inside the circle if x^2 + y^2 <= 1
'   * Why random estimates improve slowly (error ~ 1 / SQR(darts))
'
' THINGS TO TRY
'   * Count how many darts it takes to get 3.14 reliably
'   * Use a quarter circle only (x and y from 0 to 1) - same answer
'   * Estimate the area of another shape, e.g. inside y = x^2
' ============================================================

DEFDBL A-Z
RANDOMIZE TIMER
SCREEN 12
CLS

' Board: centre (220, 240), 200 pixels = 1 unit.
cx = 220: cy = 240: r = 200
LINE (cx - r, cy - r)-(cx + r, cy + r), 15, B
CIRCLE (cx, cy), r, 15

COLOR 14
LOCATE 2, 56: PRINT "MONTE CARLO PI"
COLOR 7
LOCATE 4, 56: PRINT "pi ~ 4 x inside / total"
LOCATE 27, 56: PRINT "Esc/Q = stop"

inside = 0: total = 0
DO
    ' Throw a batch of 50 darts between screen updates (faster).
    FOR i = 1 TO 50
        x = RND * 2 - 1                 ' random number from -1 to 1
        y = RND * 2 - 1
        total = total + 1
        IF x * x + y * y <= 1 THEN      ' distance from centre <= 1 ?
            inside = inside + 1
            PSET (cx + x * r, cy + y * r), 10
        ELSE
            PSET (cx + x * r, cy + y * r), 12
        END IF
    NEXT i

    est = 4 * inside / total
    LOCATE 7, 56: PRINT USING "Darts:  #########"; total
    LOCATE 8, 56: PRINT USING "Inside: #########"; inside
    LOCATE 10, 56: COLOR 15: PRINT USING "pi ~ #.######"; est: COLOR 7
    LOCATE 11, 56: PRINT USING "error  #.######"; ABS(est - 3.141592653589793#)
    ' Typical size of the random error: 4 * SQR(p(1-p)/N), p = pi/4.
    LOCATE 13, 56: PRINT "typical error"; : PRINT USING " #.######"; 1.64 / SQR(total)

    k$ = UCASE$(INKEY$)
LOOP UNTIL k$ = CHR$(27) OR k$ = "Q" OR total >= 1000000

LOCATE 15, 56: PRINT "Finished."
LOCATE 16, 56: PRINT "Press any key."
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
