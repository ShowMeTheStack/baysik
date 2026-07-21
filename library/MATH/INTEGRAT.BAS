' ============================================================
' TITLE:    Area Under a Curve (Integration)
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     calculus, integration, trapezoid rule, simpson's rule, graphics
' SUMMARY:  Compares rectangle, trapezoid and Simpson's rules for finding areas, with a live picture.
' ------------------------------------------------------------
' WHAT IT DOES
'   The integral of f(x) from a to b is the area under the curve.
'   We can approximate it by chopping [a, b] into n thin strips of
'   width h = (b - a) / n and adding up simple shapes:
'     MIDPOINT  : rectangles as tall as f at the middle of each strip
'     TRAPEZOID : join neighbouring points with straight lines
'                 area = h * (f0/2 + f1 + f2 + ... + f(n-1) + fn/2)
'     SIMPSON   : fit a parabola through every 3 points
'                 area = h/3 * (f0 + 4f1 + 2f2 + 4f3 + ... + 4f(n-1) + fn)
'   The program first draws the trapezoids for a small n, then prints
'   a table showing how fast each rule's error shrinks as n doubles.
'   Trapezoid error drops 4x, Simpson's drops 16x per doubling!
'
' HOW TO USE
'   Choose one of the functions from the menu (1-4), or Q to quit.
'   Press a key to move from the picture to the table.
'
' CONCEPTS YOU WILL LEARN
'   * Riemann sums and the idea of a definite integral
'   * Error order: O(h^2) for trapezoid, O(h^4) for Simpson
'   * SELECT CASE to pick a function, WINDOW for graph scaling
'
' THINGS TO TRY
'   * Add your own function in FUNCTION F and its exact integral
'   * Integrate 4 / (1 + x^2) from 0 to 1 - you get pi!
'   * Try Simpson's 3/8 rule or Gaussian quadrature
' ============================================================

DECLARE FUNCTION F# (x#)
DEFDBL A-Z
DIM SHARED which AS INTEGER
CONST PI = 3.141592653589793#

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "NUMERICAL INTEGRATION": COLOR 7
    PRINT
    PRINT "  1)  x^2            from 0 to 3     (exact 9)"
    PRINT "  2)  SIN(x)         from 0 to pi    (exact 2)"
    PRINT "  3)  4/(1+x^2)      from 0 to 1     (exact pi)"
    PRINT "  4)  EXP(-x^2)      from 0 to 2     (exact 0.882081390762422)"
    PRINT "  Q)  Quit"
    PRINT
    PRINT "Choose: ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    which = VAL(k$)
    IF which >= 1 AND which <= 4 THEN
        SELECT CASE which
            CASE 1: a = 0: b = 3: exact = 9: top = 9
            CASE 2: a = 0: b = PI: exact = 2: top = 1
            CASE 3: a = 0: b = 1: exact = PI: top = 4
            CASE 4: a = 0: b = 2: exact = .882081390762422#: top = 1
        END SELECT

        ' ---- Picture: 6 trapezoids under the curve ----
        SCREEN 12
        WINDOW (a - (b - a) * .1, -top * .15)-(b + (b - a) * .1, top * 1.15)
        LINE (a - (b - a) * .1, 0)-(b + (b - a) * .1, 0), 8   ' x axis
        n = 6: h = (b - a) / n
        FOR i = 0 TO n - 1
            x0 = a + i * h: x1 = x0 + h
            ' Each trapezoid: two vertical sides and a slanted top.
            LINE (x0, 0)-(x0, F(x0)), 2
            LINE (x1, 0)-(x1, F(x1)), 2
            LINE (x0, F(x0))-(x1, F(x1)), 2
            LINE (x0, 0)-(x1, 0), 2
            ' PAINT floods from an inside point until it hits colour 2.
            PAINT ((x0 + x1) / 2, (F(x0) + F(x1)) / 4), 2, 2
            LINE (x0, F(x0))-(x1, F(x1)), 10      ' bright slanted top
            LINE (x0, 0)-(x0, F(x0)), 10: LINE (x1, 0)-(x1, F(x1)), 10
        NEXT i
        ' The real curve, drawn with many tiny line segments.
        PSET (a, F(a)), 14
        FOR i = 1 TO 200
            x = a + (b - a) * i / 200
            LINE -(x, F(x)), 14
        NEXT i
        LOCATE 1, 1: COLOR 15
        PRINT "Yellow: the curve.  Green: 6 trapezoids approximating the area."
        LOCATE 30, 1: PRINT "Press a key for the accuracy table...";
        k$ = INPUT$(1)

        ' ---- Table: errors as n doubles ----
        SCREEN 0: WIDTH 80: CLS
        COLOR 14: PRINT "Errors (approximation - exact) as the strips get thinner": COLOR 7
        PRINT
        PRINT "    n        Midpoint        Trapezoid          Simpson"
        n = 2
        FOR row = 1 TO 10
            h = (b - a) / n
            mid = 0: trap = (F(a) + F(b)) / 2: simp = F(a) + F(b)
            FOR i = 1 TO n
                mid = mid + F(a + (i - .5) * h)
                IF i < n THEN
                    fx = F(a + i * h)
                    trap = trap + fx
                    ' Simpson weights alternate 4, 2, 4, 2 ... 4
                    IF i MOD 2 = 1 THEN simp = simp + 4 * fx ELSE simp = simp + 2 * fx
                END IF
            NEXT i
            mid = mid * h: trap = trap * h: simp = simp * h / 3
            PRINT USING "#####   "; n;
            PRINT USING "  ##.#####^^^^   "; mid - exact; trap - exact; simp - exact
            n = n * 2
        NEXT row
        PRINT
        PRINT "Simpson with n ="; n / 2; "gives"; simp; " exact ="; exact
        PRINT "Each doubling: trapezoid error / 4, Simpson error / 16."
        PRINT "(Simpson is perfectly exact for x^2 and x^3: parabolas fit them exactly.)"
        PRINT : PRINT "Press a key for the menu..."
        k$ = INPUT$(1)
    END IF
LOOP
SCREEN 0: WIDTH 80: CLS
END

' The function being integrated, chosen by the shared variable "which".
FUNCTION F# (x#)
    SELECT CASE which
        CASE 1: F# = x# * x#
        CASE 2: F# = SIN(x#)
        CASE 3: F# = 4 / (1 + x# * x#)
        CASE ELSE: F# = EXP(-x# * x#)
    END SELECT
END FUNCTION
