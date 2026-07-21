' ============================================================
' TITLE:    Quadratic Equation Solver
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     algebra, quadratic formula, discriminant, complex roots
' SUMMARY:  Solves ax^2 + bx + c = 0, explains the discriminant and finds the vertex of the parabola.
' ------------------------------------------------------------
' WHAT IT DOES
'   A quadratic equation has the form  a*x^2 + b*x + c = 0.
'   The famous quadratic formula gives its solutions ("roots"):
'
'              -b  +/-  SQR(b^2 - 4ac)
'        x  =  -----------------------
'                       2a
'
'   The part under the square root, D = b^2 - 4ac, is called the
'   DISCRIMINANT.  It decides what kind of answers you get:
'     D > 0  two different real roots (the parabola crosses the x axis twice)
'     D = 0  one repeated root (it just touches the axis)
'     D < 0  no real roots - two complex roots  p +/- qi
'   The program also shows the vertex (turning point) and a check.
'
' HOW TO USE
'   Enter a, b and c.  Enter a = 0 to quit.
'   Try: 1, -3, 2   then 1, 2, 1   then 1, 2, 5
'
' CONCEPTS YOU WILL LEARN
'   * The quadratic formula and the discriminant
'   * Complex numbers appear naturally from SQR of a negative
'   * A numerically safer formula that avoids "catastrophic cancellation"
'
' THINGS TO TRY
'   * Solve 1, -1, -1 - one root is the golden ratio!
'   * Compare the naive formula with the safe one for a=1, b=1E8, c=1
'   * Add factorised form output: a(x - r1)(x - r2)
' ============================================================

DEFDBL A-Z

CLS
COLOR 14: PRINT "QUADRATIC EQUATION SOLVER:  a*x^2 + b*x + c = 0": COLOR 7
PRINT

DO
    INPUT "a (0 = quit)"; a
    IF a = 0 THEN EXIT DO
    INPUT "b"; b
    INPUT "c"; c
    PRINT
    PRINT "Equation: "; a; "x^2 +"; b; "x +"; c; "= 0"

    d = b * b - 4 * a * c
    PRINT "Discriminant D = b^2 - 4ac ="; d

    ' The vertex is halfway between the roots, at x = -b / (2a).
    vx = -b / (2 * a)
    vy = a * vx * vx + b * vx + c
    PRINT "Vertex (turning point) at x ="; vx; ", y ="; vy;
    IF a > 0 THEN PRINT " (a minimum, parabola opens up)" ELSE PRINT " (a maximum, opens down)"

    COLOR 11
    IF d > 0 THEN
        ' Safe formula: compute the root where -b and the square root
        ' have the SAME sign (so they add, never cancel), then get the
        ' other one from  r1 * r2 = c / a  (Vieta's formula).
        IF b >= 0 THEN q = -(b + SQR(d)) / 2 ELSE q = -(b - SQR(d)) / 2
        r1 = q / a
        IF q <> 0 THEN r2 = c / q ELSE r2 = -r1
        PRINT "D > 0: two real roots"
        PRINT "   x1 ="; r1
        PRINT "   x2 ="; r2
        COLOR 7
        PRINT "Check: sum of roots ="; r1 + r2; " (should be -b/a ="; -b / a; ")"
        PRINT "       product      ="; r1 * r2; " (should be  c/a ="; c / a; ")"
    ELSEIF d = 0 THEN
        PRINT "D = 0: one repeated root"
        PRINT "   x ="; vx
    ELSE
        ' SQR(d) is impossible for negative d using real numbers, so we
        ' write SQR(d) = SQR(-d) * i, where i is the square root of -1.
        re = -b / (2 * a)
        im = SQR(-d) / (2 * ABS(a))
        PRINT "D < 0: no real roots, two complex roots"
        PRINT "   x1 ="; re; "+"; im; "i"
        PRINT "   x2 ="; re; "-"; im; "i"
    END IF
    COLOR 7
    PRINT
LOOP
PRINT "Bye!"
