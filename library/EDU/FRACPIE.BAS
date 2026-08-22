' ============================================================
' TITLE:    Fraction Pies
' CATEGORY: Education & Quizzes
' LEVEL:    Intermediate
' TAGS:     fractions, graphics, circle, paint, gcd
' SUMMARY:  Type two fractions and see them as coloured pie slices and bars - which is bigger?
' ------------------------------------------------------------
' WHAT IT DOES
'   A fraction like 3/4 means "cut something into 4 equal pieces and
'   take 3".  This program draws exactly that: a pie cut into equal
'   slices with some of them coloured in, plus a fraction bar
'   underneath.  You enter two fractions and it shows them side by
'   side, tells you which is bigger (or that they are equal!), and
'   simplifies them using the greatest common divisor.
'
' HOW TO USE
'   Type a fraction such as 2/3 and press Enter, then a second one.
'   Bottom numbers can be 1 to 16.  Press Enter on an empty line
'   (or type Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * SCREEN 12 graphics with CIRCLE, LINE and PAINT
'   * Angles in radians: a full turn is 2 * pi
'   * Euclid's algorithm for the greatest common divisor (GCD)
'   * Comparing fractions by cross-multiplying
'
' THINGS TO TRY
'   * Try 1/2 and 2/4, or 2/3 and 4/6 - what do you notice?
'   * Allow "improper" fractions like 5/4 by drawing two pies
'   * Add a third pie that shows the SUM of the two fractions
' ============================================================

DECLARE SUB DrawPie (cx!, cy!, num!, den!, col!)
DECLARE SUB DrawBar (x!, y!, num!, den!, col!)
DECLARE FUNCTION GCD! (a!, b!)
DECLARE FUNCTION FracText$ (n!, d!)
DECLARE FUNCTION ReadFraction! (prompt$, n!, d!)

CONST PI = 3.14159265#

SCREEN 12
DO
    CLS
    COLOR 14
    LOCATE 1, 30: PRINT "FRACTION PIES"
    COLOR 7
    ' Read two fractions; ReadFraction returns 0 if the user quits
    IF ReadFraction("First fraction  (e.g. 3/4): ", n1, d1) = 0 THEN EXIT DO
    IF ReadFraction("Second fraction (e.g. 2/3): ", n2, d2) = 0 THEN EXIT DO

    ' Wipe the input lines and draw both pies
    LINE (0, 48)-(639, 479), 0, BF
    DrawPie 160, 180, n1, d1, 12
    DrawPie 480, 180, n2, d2, 9
    DrawBar 60, 320, n1, d1, 12
    DrawBar 380, 320, n2, d2, 9

    ' Labels under each picture
    g1 = GCD(n1, d1): g2 = GCD(n2, d2)
    LOCATE 23, 14: COLOR 12: PRINT FracText$(n1, d1);
    IF g1 > 1 THEN PRINT " = "; FracText$(n1 / g1, d1 / g1); " (simplified)";
    LOCATE 24, 14: PRINT USING "= #.###"; n1 / d1;
    LOCATE 23, 54: COLOR 9: PRINT FracText$(n2, d2);
    IF g2 > 1 THEN PRINT " = "; FracText$(n2 / g2, d2 / g2); " (simplified)";
    LOCATE 24, 54: PRINT USING "= #.###"; n2 / d2;

    ' Compare by cross-multiplying: a/b > c/d  exactly when  a*d > c*b.
    ' This avoids decimals completely, so it is always exact.
    LOCATE 26, 10: COLOR 14
    lhs = n1 * d2: rhs = n2 * d1
    IF lhs > rhs THEN
        PRINT "The RED fraction is bigger, because"; n1; "x"; d2; ">"; n2; "x"; d1
    ELSEIF lhs < rhs THEN
        PRINT "The BLUE fraction is bigger, because"; n2; "x"; d1; ">"; n1; "x"; d2
    ELSE
        PRINT "They are EQUAL! Same amount of pie, different slices."
    END IF
    LOCATE 28, 25: COLOR 7: PRINT "Press any key to try again";
    DO: LOOP WHILE INKEY$ = ""
LOOP
SCREEN 0
PRINT "Fractions are just sharing fairly. Bye!"
END

' ------------------------------------------------------------
' DrawBar: a rectangle split into den equal boxes, num filled.
' ------------------------------------------------------------
SUB DrawBar (x, y, num, den, col)
    w = 200 / den                    ' width of one box
    FOR i = 0 TO den - 1
        x1 = x + i * w
        IF i < num THEN LINE (x1, y)-(x1 + w, y + 30), col, BF
        LINE (x1, y)-(x1 + w, y + 30), 15, B     ' white outline
    NEXT i
END SUB

' ------------------------------------------------------------
' DrawPie: a circle of radius 100 cut into den slices.
' Slice i runs from angle i*step to (i+1)*step.  We draw each
' cutting line from the centre, then PAINT the first num slices
' by pouring colour into a point in the middle of each slice.
' ------------------------------------------------------------
SUB DrawPie (cx, cy, num, den, col)
    r = 100
    CIRCLE (cx, cy), r, 15
    stp = 2 * PI / den
    IF den > 1 THEN
        FOR i = 0 TO den - 1
            a = i * stp
            ' The screen's y axis points DOWN, so we subtract the sine
            ' to make angles go anticlockwise like in maths class.
            LINE (cx, cy)-(cx + r * COS(a), cy - r * SIN(a)), 15
        NEXT i
    END IF
    FOR i = 0 TO num - 1
        midA = (i + .5) * stp          ' angle through the slice's middle
        px = cx + r * .6 * COS(midA)
        py = cy - r * .6 * SIN(midA)
        PAINT (px, py), col, 15       ' fill until we hit white lines
    NEXT i
END SUB

' FracText$: turns 3 and 4 into the neat text "3/4" (no spaces).
' STR$ puts a space in front of positive numbers, LTRIM$ removes it.
FUNCTION FracText$ (n, d)
    FracText$ = LTRIM$(STR$(n)) + "/" + LTRIM$(STR$(d))
END FUNCTION

' Euclid: gcd(a, b) = gcd(b, a MOD b), and gcd(a, 0) = a.
FUNCTION GCD (a, b)
    x = a: y = b
    DO WHILE y <> 0
        t = x MOD y: x = y: y = t
    LOOP
    GCD = x
END FUNCTION

' ------------------------------------------------------------
' ReadFraction: keeps asking until it gets a valid fraction.
' Returns 1 on success, 0 if the user wants to quit.
' ------------------------------------------------------------
FUNCTION ReadFraction (prompt$, n, d)
    DO
        LOCATE 3, 2: PRINT SPACE$(70);
        LOCATE 3, 2: PRINT prompt$;
        LINE INPUT f$
        f$ = UCASE$(LTRIM$(RTRIM$(f$)))
        IF f$ = "" OR f$ = "Q" THEN ReadFraction = 0: EXIT FUNCTION
        slash = INSTR(f$, "/")
        IF slash > 0 THEN
            n = VAL(LEFT$(f$, slash - 1))
            d = VAL(MID$(f$, slash + 1))
        ELSE
            n = VAL(f$): d = 1            ' a whole number like 1 = 1/1
        END IF
        n = INT(n): d = INT(d)
        IF d >= 1 AND d <= 16 AND n >= 0 AND n <= d THEN
            ReadFraction = 1: EXIT FUNCTION
        END IF
        LOCATE 4, 2: COLOR 12
        PRINT "Use a top number from 0 up to the bottom, bottom 1-16.";
        COLOR 7
    LOOP
END FUNCTION
