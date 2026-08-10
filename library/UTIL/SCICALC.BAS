' ============================================================
' TITLE:    Scientific Calculator Menu
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     math functions, menu, trigonometry, logarithms, select case
' SUMMARY:  A menu of scientific functions - trig in degrees, logs, powers, roots and factorials.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shows a numbered menu of scientific functions.  Pick one,
'   type the number(s) it needs, and the answer is printed.
'   It shows how to use BASIC's built-in maths functions (SIN,
'   COS, TAN, ATN, LOG, EXP, SQR) and how to build the ones
'   BASIC does not have (degrees, LOG10, inverse sine, n!).
'
' HOW TO USE
'   Press a key 1-9 or A-C to choose a function, then answer the
'   prompts.  Press Q or Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * BASIC trig works in RADIANS; convert with PI / 180
'   * LOG is the natural log; LOG10(x) = LOG(x) / LOG(10)
'   * ATN is the only inverse trig function - the others are
'     built from it
'   * Validating input before calling a function (domain errors)
'
' THINGS TO TRY
'   * Add hyperbolic functions: SINH(x) = (EXP(x) - EXP(-x)) / 2
'   * Add a "nCr" combinations option using the factorial.
'   * Add a switch between DEGREES and RADIANS mode.
' ============================================================

' PI is not built in to QBasic.  ATN(1) is 45 degrees = PI/4.
CONST PI = 3.141592653589793#
DEG2RAD# = PI / 180

DO
    CLS
    COLOR 15, 4: PRINT SPACE$(80);: LOCATE 1, 28: PRINT "SCIENTIFIC CALCULATOR": COLOR 7, 0
    PRINT
    PRINT "   1. sin(x)   (degrees)        7. square root"
    PRINT "   2. cos(x)   (degrees)        8. x ^ y"
    PRINT "   3. tan(x)   (degrees)        9. n!  (factorial)"
    PRINT "   4. arcsin / arccos / arctan  A. ln(x) and log10(x)"
    PRINT "   5. degrees <-> radians       B. e ^ x"
    PRINT "   6. hypotenuse (a, b)         C. 1 / x"
    PRINT
    PRINT "   Q / Esc. Quit"
    PRINT
    PRINT "   Choose: ";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    PRINT k$
    PRINT
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO

    SELECT CASE k$
        CASE "1", "2", "3"
            INPUT "   Angle in degrees: ", x#
            r# = x# * DEG2RAD#           ' convert to radians first!
            IF k$ = "1" THEN PRINT "   sin ="; SIN(r#)
            IF k$ = "2" THEN PRINT "   cos ="; COS(r#)
            IF k$ = "3" THEN
                ' tan is undefined at 90, 270, ... where cos is 0.
                IF ABS(COS(r#)) < 1E-12 THEN PRINT "   tan is undefined here" ELSE PRINT "   tan ="; TAN(r#)
            END IF
        CASE "4"
            INPUT "   Value (-1 to 1 for asin/acos): ", x#
            ' arctan works for any number:
            PRINT "   arctan ="; ATN(x#) / DEG2RAD#; "degrees"
            IF ABS(x#) <= 1 THEN
                ' arcsin(x) = atan( x / sqrt(1 - x^2) ), with care at +-1
                IF ABS(x#) = 1 THEN
                    as# = SGN(x#) * 90
                ELSE
                    as# = ATN(x# / SQR(1 - x# * x#)) / DEG2RAD#
                END IF
                PRINT "   arcsin ="; as#; "degrees"
                ' arccos is just 90 degrees minus arcsin.
                PRINT "   arccos ="; 90 - as#; "degrees"
            ELSE
                PRINT "   (arcsin/arccos need -1 <= x <= 1)"
            END IF
        CASE "5"
            INPUT "   Degrees: ", x#
            PRINT "   ="; x# * DEG2RAD#; "radians"
            PRINT "   ("; x#; "radians ="; x# / DEG2RAD#; "degrees )"
        CASE "6"
            INPUT "   Side a: ", a#
            INPUT "   Side b: ", b#
            ' Pythagoras: c = sqrt(a^2 + b^2)
            PRINT "   Hypotenuse ="; SQR(a# * a# + b# * b#)
        CASE "7"
            INPUT "   x: ", x#
            IF x# < 0 THEN PRINT "   No real root of a negative number" ELSE PRINT "   sqrt ="; SQR(x#)
        CASE "8"
            INPUT "   x: ", x#
            INPUT "   y: ", y#
            IF x# < 0 AND y# <> INT(y#) THEN
                PRINT "   Not a real number"
            ELSEIF x# = 0 AND y# < 0 THEN
                PRINT "   0 to a negative power is undefined"
            ELSE
                PRINT "   x^y ="; x# ^ y#
            END IF
        CASE "9"
            INPUT "   n (0-170): ", n
            IF n < 0 OR n > 170 OR n <> INT(n) THEN
                PRINT "   Need a whole number from 0 to 170"
            ELSE
                ' n! = 1 * 2 * 3 * ... * n   (and 0! is 1)
                f# = 1
                FOR i = 2 TO n: f# = f# * i: NEXT i
                PRINT "  "; n; "! ="; f#
            END IF
        CASE "A"
            INPUT "   x (> 0): ", x#
            IF x# <= 0 THEN
                PRINT "   Logs need a positive number"
            ELSE
                PRINT "   ln(x)    ="; LOG(x#)
                PRINT "   log10(x) ="; LOG(x#) / LOG(10#)   ' change of base rule
            END IF
        CASE "B"
            INPUT "   x: ", x#
            IF x# > 709 THEN PRINT "   Too big (overflow)" ELSE PRINT "   e^x ="; EXP(x#)
        CASE "C"
            INPUT "   x: ", x#
            IF x# = 0 THEN PRINT "   1/0 is undefined" ELSE PRINT "   1/x ="; 1 / x#
        CASE ELSE
            PRINT "   Not a menu choice."
    END SELECT

    PRINT
    PRINT "   Press any key for the menu..."
    DO: LOOP WHILE INKEY$ = ""
LOOP
CLS
PRINT "Calculator closed."
END
