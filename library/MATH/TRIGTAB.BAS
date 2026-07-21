' ============================================================
' TITLE:    Trig Tables & the Unit Circle
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     trigonometry, sin, cos, tan, radians, unit circle, animation
' SUMMARY:  Prints a classic sine/cosine/tangent table, then animates the unit circle tracing out the sine wave.
' ------------------------------------------------------------
' WHAT IT DOES
'   For an angle A in a right triangle with hypotenuse 1:
'      SIN(A) = the height (opposite side)
'      COS(A) = the width  (adjacent side)
'      TAN(A) = height / width = SIN(A) / COS(A)
'   Before calculators, people looked these up in printed tables.
'   Part 1 prints such a table for 0 to 90 degrees.
'   Part 2 shows WHY sine makes a wave: a point goes round a circle of
'   radius 1; its height, plotted against the angle, traces the sine
'   curve, and its width traces the cosine curve.
'
' HOW TO USE
'   Press a key after the table.  The animation runs until you press
'   any key.
'
' CONCEPTS YOU WILL LEARN
'   * Degrees vs radians: BASIC's SIN/COS/TAN want RADIANS
'     radians = degrees * PI / 180   (a full turn is 2*PI radians)
'   * ATN (arctangent) gives PI:  PI = 4 * ATN(1)
'   * Identities you can check: SIN^2 + COS^2 = 1
'   * Simple animation by erasing and redrawing
'
' THINGS TO TRY
'   * Add a column for SIN^2 + COS^2 - it should always be 1
'   * Draw TAN on the animation too (watch it shoot off at 90 degrees)
'   * Change the circle to an ellipse and see what the waves do
' ============================================================

DEFDBL A-Z
PI = 4 * ATN(1#)                    ' ATN(1) = 45 degrees = PI/4 radians.
' The # in 1# asks for DOUBLE precision; plain ATN(1) is only good to 7 digits.

CLS
COLOR 14: PRINT "TRIGONOMETRY TABLE      (PI = 4 * ATN(1) ="; PI; ")": COLOR 7
PRINT " deg   radians     SIN       COS        TAN"
PRINT " ---   -------   -------   -------   ---------"
FOR d = 0 TO 90 STEP 5
    r = d * PI / 180                ' convert degrees to radians
    ' Highlight the "special" angles whose values have exact forms.
    IF d MOD 30 = 0 OR d = 45 THEN COLOR 15 ELSE COLOR 7
    PRINT USING " ##   #.#####   #.#####   #.#####   "; d; r; SIN(r); COS(r);
    IF d = 90 THEN
        PRINT "infinite"            ' COS(90) = 0, and you cannot divide by 0
    ELSE
        PRINT USING "####.####"; TAN(r)
    END IF
NEXT d
COLOR 11
PRINT "Exact: SIN 30 = 1/2   SIN 45 = SQR(2)/2   SIN 60 = SQR(3)/2 ="; SQR(3) / 2
COLOR 7
PRINT "Press a key for the unit circle animation...";
k$ = INPUT$(1)

' ------------------------------------------------------------
' Animation.  Circle centre (110, 240), radius rc pixels.  (Not "r":
' BASIC names ignore case, so R would clash with r used above.)  The waves
' start at x = 240; one full turn (360 degrees) spans 380 pixels.
' ------------------------------------------------------------
SCREEN 12: CLS
cx = 110: cy = 240: rc = 90
wx = 240
CIRCLE (cx, cy), rc, 8
LINE (cx - rc - 10, cy)-(wx + 380, cy), 8          ' horizontal axis
LINE (cx, cy - rc - 10)-(cx, cy + rc + 10), 8
FOR x = wx TO wx + 380 STEP 95                     ' marks every 90 degrees
    LINE (x, cy - 4)-(x, cy + 4), 8
NEXT x
COLOR 14: LOCATE 2, 2: PRINT "yellow: SIN = height of the point";
COLOR 11: LOCATE 3, 2: PRINT "cyan:   COS = width of the point";
COLOR 7: LOCATE 29, 2: PRINT "Any key = quit";
' Degree labels under the tick marks (8 pixels per text column).
LOCATE 17, 31: PRINT "0";: LOCATE 17, 42: PRINT "90";: LOCATE 17, 54: PRINT "180";
LOCATE 17, 66: PRINT "270";: LOCATE 17, 77: PRINT "360";

oldpx = -1
DO
    FOR d = 0 TO 359 STEP 3
        a = d * PI / 180
        px = cx + rc * COS(a)
        py = cy - rc * SIN(a)            ' minus: screen y grows downward
        ' erase the old radius / height lines by drawing them in black
        IF oldpx >= 0 THEN
            LINE (cx, cy)-(oldpx, oldpy), 0
            LINE (oldpx, cy)-(oldpx, oldpy), 0
            LINE (oldpx, oldpy)-(wx - 5, oldpy), 0
            CIRCLE (cx, cy), rc, 8      ' repair the circle and axes
            LINE (cx - rc - 10, cy)-(wx - 1, cy), 8
            LINE (cx, cy - rc - 10)-(cx, cy + rc + 10), 8
        END IF
        x = wx + d * 380 / 360
        LINE (cx, cy)-(px, py), 15                 ' the radius (length 1)
        LINE (px, cy)-(px, py), 14                 ' height = SIN
        LINE (px, py)-(wx - 5, py), 6, , &HCCCC     ' dotted guide towards the wave
        ys = cy - rc * SIN(a): yc = cy - rc * COS(a)
        IF d = 0 THEN PSET (x, ys), 14: PSET (x, yc), 11: lx = x: ls = ys: lc = yc
        LINE (lx, ls)-(x, ys), 14                  ' sine wave
        LINE (lx, lc)-(x, yc), 11                  ' cosine wave
        lx = x: ls = ys: lc = yc
        oldpx = px: oldpy = py
        LOCATE 5, 2: COLOR 15
        PRINT USING "angle ###  sin ##.###  cos ##.###"; d; SIN(a); COS(a);
        t = TIMER: DO WHILE TIMER - t < .02 AND TIMER >= t: LOOP
        IF INKEY$ <> "" THEN EXIT DO
    NEXT d
LOOP
SCREEN 0: WIDTH 80
