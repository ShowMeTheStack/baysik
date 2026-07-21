' ============================================================
' TITLE:    Complex Number Calculator
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     complex numbers, polar form, argand diagram, TYPE, graphics
' SUMMARY:  Does arithmetic with complex numbers using a TYPE, shows polar form, and draws powers spiralling on the Argand plane.
' ------------------------------------------------------------
' WHAT IT DOES
'   A complex number z = a + bi has a real part a and an imaginary
'   part b, where i is the number with i * i = -1.  Rules:
'     (a+bi) + (c+di) = (a+c) + (b+d)i
'     (a+bi) * (c+di) = (ac - bd) + (ad + bc)i     (because i*i = -1)
'     (a+bi) / (c+di) = multiply top and bottom by (c-di), the CONJUGATE
'   Every complex number is also a point on a plane (the Argand
'   diagram) at distance r = |z| from 0 and angle theta.  This is its
'   POLAR form:  z = r(COS theta + i SIN theta).
'   Multiplying complex numbers MULTIPLIES their lengths and ADDS their
'   angles - so the powers z, z^2, z^3 ... spiral around the origin.
'
' HOW TO USE
'   Enter two complex numbers as real and imaginary parts.  You will
'   see sum, difference, product, quotient and polar forms.  Press P
'   to plot the powers of the first number, any other key to enter new
'   numbers, Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * User-defined TYPEs (a record with .re and .im fields)
'   * SUBs that take and return TYPE variables
'   * ATN-based angle calculation that works in all four quadrants
'   * Rotation by multiplying by a complex number of length 1
'
' THINGS TO TRY
'   * Plot powers of 0.9 + 0.3i (spiral in) and 1.02 + 0.2i (out)
'   * Multiply by i (0 + 1i): it rotates a point by exactly 90 degrees
'   * Find the 5 fifth-roots of 1: COS(2*PI*k/5) + i SIN(2*PI*k/5)
' ============================================================

TYPE Complex
    re AS DOUBLE
    im AS DOUBLE
END TYPE

DECLARE SUB CAdd (a AS Complex, b AS Complex, r AS Complex)
DECLARE SUB CSubt (a AS Complex, b AS Complex, r AS Complex)
DECLARE SUB CMul (a AS Complex, b AS Complex, r AS Complex)
DECLARE SUB CDiv (a AS Complex, b AS Complex, r AS Complex, ok AS INTEGER)
DECLARE FUNCTION CStr$ (z AS Complex)
DECLARE FUNCTION CAbs# (z AS Complex)
DECLARE FUNCTION CArg# (z AS Complex)

DIM SHARED PI AS DOUBLE
PI = 4 * ATN(1#)
DIM z1 AS Complex, z2 AS Complex, r AS Complex, p AS Complex
DIM ok AS INTEGER

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "COMPLEX NUMBER CALCULATOR": COLOR 7
    PRINT "Enter numbers as  real, imaginary   e.g.  3, 4  means 3 + 4i"
    PRINT
    INPUT "z1 = ", z1.re, z1.im
    INPUT "z2 = ", z2.re, z2.im
    PRINT
    COLOR 11
    PRINT "z1      = "; CStr$(z1)
    PRINT "z2      = "; CStr$(z2)
    COLOR 7
    CAdd z1, z2, r: PRINT "z1 + z2 = "; CStr$(r)
    CSubt z1, z2, r: PRINT "z1 - z2 = "; CStr$(r)
    CMul z1, z2, r: PRINT "z1 * z2 = "; CStr$(r)
    CDiv z1, z2, r, ok
    IF ok THEN PRINT "z1 / z2 = "; CStr$(r) ELSE PRINT "z1 / z2 = undefined (z2 is 0)"
    PRINT
    COLOR 11: PRINT "Polar form   (r = length, theta = angle)": COLOR 7
    PRINT USING "z1: r = ###.#### theta = ####.## degrees"; CAbs#(z1); CArg#(z1) * 180 / PI
    PRINT USING "z2: r = ###.#### theta = ####.## degrees"; CAbs#(z2); CArg#(z2) * 180 / PI
    CMul z1, z2, r
    PRINT USING "z1*z2: r = ###.#### theta = ####.## degrees"; CAbs#(r); CArg#(r) * 180 / PI
    PRINT "  (lengths multiplied, angles added - give or take 360)"
    PRINT
    PRINT "P = plot powers of z1    Q = quit    any other key = new numbers"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "P" THEN
        ' --- Argand diagram: 1 unit = sc pixels, origin in the middle.
        SCREEN 12: CLS
        sc = 200
        IF CAbs#(z1) > 1.05 THEN sc = 60
        LINE (0, 240)-(639, 240), 8: LINE (320, 0)-(320, 479), 8
        CIRCLE (320, 240), sc, 8             ' the unit circle |z| = 1
        p.re = 1: p.im = 0                   ' z^0 = 1
        PSET (320 + sc, 240), 15
        FOR n = 1 TO 60
            CMul p, z1, p                    ' p = p * z1  -> next power
            IF CAbs#(p) > 6 THEN EXIT FOR    ' flew off the screen
            x = 320 + p.re * sc: y = 240 - p.im * sc
            LINE -(x, y), 9 + n MOD 6
            CIRCLE (x, y), 2, 15
        NEXT n
        LOCATE 1, 1: PRINT "Powers of z1 = "; CStr$(z1)
        LOCATE 2, 1: PRINT "Each step: length x"; CSNG(CAbs#(z1)); ", turn"; CSNG(CArg#(z1) * 180 / PI); "degrees"
        LOCATE 30, 1: PRINT "Grey circle: |z| = 1.   Press a key...";
        k$ = INPUT$(1)
    END IF
LOOP
SCREEN 0: WIDTH 80
END

SUB CAdd (a AS Complex, b AS Complex, r AS Complex)
    r.re = a.re + b.re
    r.im = a.im + b.im
END SUB

' The argument (angle) of z.  ATN only gives -90..90 degrees, so we
' fix up the left half of the plane by adding or subtracting PI.
FUNCTION CArg# (z AS Complex)
    IF z.re > 0 THEN
        CArg# = ATN(z.im / z.re)
    ELSEIF z.re < 0 THEN
        IF z.im >= 0 THEN CArg# = ATN(z.im / z.re) + PI ELSE CArg# = ATN(z.im / z.re) - PI
    ELSE
        ' On the imaginary axis: straight up, straight down, or z = 0.
        IF z.im > 0 THEN CArg# = PI / 2
        IF z.im < 0 THEN CArg# = -PI / 2
        IF z.im = 0 THEN CArg# = 0
    END IF
END FUNCTION

' Length (modulus) by Pythagoras: |a + bi| = SQR(a^2 + b^2)
FUNCTION CAbs# (z AS Complex)
    CAbs# = SQR(z.re * z.re + z.im * z.im)
END FUNCTION

' Division: multiply top and bottom by the conjugate of b (c - di).
' The bottom becomes c^2 + d^2, an ordinary real number.
SUB CDiv (a AS Complex, b AS Complex, r AS Complex, ok AS INTEGER)
    d# = b.re * b.re + b.im * b.im
    IF d# = 0 THEN ok = 0: EXIT SUB
    t# = (a.re * b.re + a.im * b.im) / d#
    r.im = (a.im * b.re - a.re * b.im) / d#
    r.re = t#
    ok = -1
END SUB

' Multiplication.  We use temporaries so that CMul p, z, p (result
' written over an input) still works.
SUB CMul (a AS Complex, b AS Complex, r AS Complex)
    t# = a.re * b.re - a.im * b.im
    r.im = a.re * b.im + a.im * b.re
    r.re = t#
END SUB

' Formats a complex number nicely, e.g. "3 - 2i".
FUNCTION CStr$ (z AS Complex)
    re$ = LTRIM$(STR$(CSNG(z.re)))
    im$ = LTRIM$(STR$(CSNG(ABS(z.im))))
    IF z.im < 0 THEN sg$ = " - " ELSE sg$ = " + "
    CStr$ = re$ + sg$ + im$ + "i"
END FUNCTION

SUB CSubt (a AS Complex, b AS Complex, r AS Complex)
    r.re = a.re - b.re
    r.im = a.im - b.im
END SUB
