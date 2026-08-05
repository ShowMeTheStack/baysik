' ============================================================
' TITLE:    Spirograph
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     spirograph, hypotrochoid, trigonometry, gcd, screen 12
' SUMMARY:  Simulates the classic toy: a small gear rolling inside a big ring traces beautiful looping curves.
' ------------------------------------------------------------
' WHAT IT DOES
'   A gear of radius r rolls around the INSIDE of a fixed ring of
'   radius R. A pen sits in a hole at distance d from the small
'   gear's centre. The pen's path is called a hypotrochoid:
'     x = (R - r) * cos(t) + d * cos((R - r) / r * t)
'     y = (R - r) * sin(t) - d * sin((R - r) / r * t)
'   The program picks random whole-number gear sizes, works out
'   exactly how many turns are needed to close the curve, and
'   draws it gradually in a colourful layered style.
'
' HOW TO USE
'   Space  draw a new random pattern ON TOP (layers build up)
'   C      clear the screen and draw a new one
'   Q/Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * Parametric equations: x and y both depend on a third value t
'   * Why the curve closes after r / GCD(R, r) turns
'   * Euclid's GCD algorithm in a FUNCTION
'   * Drawing continuous curves with LINE -(x, y)
'
' THINGS TO TRY
'   * Make the gear roll OUTSIDE (epitrochoid): use R + r and
'     change the minus in the y formula to plus
'   * Let the user type R, r and d with INPUT
'   * Change colour as t grows to get rainbow curves
' ============================================================

DECLARE FUNCTION GCD% (a%, b%)
CONST PI = 3.14159265#

SCREEN 12
RANDOMIZE TIMER
CLS
layer = 0

DO
    ' ---- Pick random gear sizes -------------------------------------
    BigR% = 200                          ' the fixed ring
    ' A multiple of 10 between 30 and 170. Sharing the factor 10
    ' with 200 keeps the number of turns small (at most 17).
    smallR% = (INT(RND * 15) + 3) * 10
    ' r = R/2 just draws a straight line or an ellipse - skip it.
    IF smallR% = 100 THEN smallR% = 90
    d = smallR% * (.4 + RND * .8)       ' pen 40%..120% of the gear radius
    c = (layer MOD 14) + 1
    layer = layer + 1

    ' The pen comes back to its start after the small gear has gone
    ' round the ring  smallR / GCD(BigR, smallR)  times.
    turns% = smallR% \ GCD%(BigR%, smallR%)

    COLOR 15
    LOCATE 1, 1: PRINT USING "R=### r=### d=###.# turns=###  "; BigR%; smallR%; d; turns%
    LOCATE 30, 1: PRINT "Space=new layer  C=clear  Q=quit";

    k = (BigR% - smallR%) / smallR%      ' how fast the small gear spins
    cx = 320: cy = 248
    ' Start position (t = 0)
    PSET (cx + (BigR% - smallR%) + d, cy), c
    tmax = 2 * PI * turns%
    stp = .03
    k$ = ""
    FOR t = stp TO tmax + stp / 2 STEP stp
        x = (BigR% - smallR%) * COS(t) + d * COS(k * t)
        y = (BigR% - smallR%) * SIN(t) - d * SIN(k * t)
        LINE -(cx + x, cy + y), c
        ' Check the keyboard as we go so a key stops the drawing.
        k$ = UCASE$(INKEY$)
        IF k$ <> "" THEN EXIT FOR
    NEXT t

    ' ---- Wait for a command (unless one was pressed already) -------
    DO WHILE k$ = ""
        k$ = UCASE$(INKEY$)
    LOOP
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    IF k$ = "C" THEN CLS: layer = 0
LOOP

SCREEN 0: WIDTH 80
END

' Greatest common divisor by Euclid's method:
' GCD(a, b) = GCD(b, a MOD b), and GCD(a, 0) = a.
FUNCTION GCD% (a%, b%)
    x% = a%: y% = b%
    DO WHILE y% > 0
        t% = x% MOD y%
        x% = y%: y% = t%
    LOOP
    GCD% = x%
END FUNCTION
