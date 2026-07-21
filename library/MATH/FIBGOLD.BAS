' ============================================================
' TITLE:    Fibonacci & the Golden Ratio
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     fibonacci, golden ratio, sequences, graphics, spiral
' SUMMARY:  Watch Fibonacci ratios close in on 1.618... then see the golden spiral drawn from squares.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Fibonacci sequence starts 1, 1 and each new term is the sum of
'   the two before it: 1, 1, 2, 3, 5, 8, 13, 21 ...
'   Divide each term by the one before (8/5, 13/8, 21/13 ...) and the
'   answers zig-zag closer and closer to the GOLDEN RATIO
'        phi = (1 + SQR(5)) / 2 = 1.6180339887...
'   Part 2 draws squares whose sides are Fibonacci numbers, packed
'   together, with a quarter circle in each: the famous golden spiral
'   seen in sunflowers and nautilus shells.
'
' HOW TO USE
'   Read the table, press a key to see the spiral, press a key to exit.
'
' CONCEPTS YOU WILL LEARN
'   * Recurrence relations (each term built from earlier ones)
'   * Limits and convergence: the error shrinks every step
'   * WINDOW to use "math" coordinates (y goes up) in graphics
'   * CIRCLE with start/end angles to draw arcs
'
' THINGS TO TRY
'   * Start the sequence with other numbers (2, 1 = Lucas numbers): same limit!
'   * Print phi^n / SQR(5) and compare it with the n-th Fibonacci number
'   * Change the colours of the squares or draw more of them
' ============================================================

DEFDBL A-Z
CONST PI = 3.141592653589793#

CLS
COLOR 14: PRINT "FIBONACCI NUMBERS AND THE GOLDEN RATIO": COLOR 7
phi = (1 + SQR(5)) / 2
PRINT "phi = (1 + SQR(5)) / 2 ="; phi
PRINT
PRINT " n        F(n)    F(n)/F(n-1)          error"
PRINT " --  ----------   -------------  -------------"

a = 1: b = 1                    ' a = F(n-1), b = F(n)
FOR n = 2 TO 20
    ratio = b / a
    ' The error alternates sign: ratios are too low, too high, too low...
    PRINT USING " ##  ##########   #.###########  "; n; b; ratio;
    PRINT USING "##.#^^^^"; ratio - phi
    c = a + b                   ' the Fibonacci rule
    a = b
    b = c
NEXT n
PRINT
PRINT "Notice: phi * phi = phi + 1  ->"; phi * phi; "="; phi + 1
PRINT "Press any key for the golden spiral..."
k$ = INPUT$(1)

' ------------------------------------------------------------
' THE GOLDEN SPIRAL
' Each quarter-circle arc has a Fibonacci radius.  When one arc ends,
' the next (bigger) arc starts at the same point heading the same way,
' so its centre lies back along the radius we just finished on.
' ------------------------------------------------------------
CONST STEPS = 11
DIM f(STEPS + 1)
f(1) = 1: f(2) = 1
FOR i = 3 TO STEPS + 1: f(i) = f(i - 1) + f(i - 2): NEXT i

SCREEN 12
' A WINDOW without SCREEN keyword makes y increase UPWARDS, like in math.
' Same scale on both axes (640x480 pixels) keeps circles round.
sc = 2.8                         ' pixels per unit
WINDOW (-320 / sc, -240 / sc)-(320 / sc, 240 / sc)

cx = 0: cy = 0                   ' centre of the current arc
ang = 0                          ' arc start angle in degrees (0 = east)
' Shift everything so the picture sits in the middle of the screen.
ox = 19.5: oy = 31.5          ' found by trial: centre of the drawing
FOR i = 1 TO STEPS
    r = f(i)
    a1 = ang * PI / 180: a2 = (ang + 90) * PI / 180
    ' Square spanned by the centre and the two arc end directions.
    x1 = cx + ox: y1 = cy + oy
    x2 = x1 + r * (COS(a1) + COS(a2))
    y2 = y1 + r * (SIN(a1) + SIN(a2))
    LINE (x1, y1)-(x2, y2), 8, B
    CIRCLE (cx + ox, cy + oy), r, 9 + i MOD 6, a1, a2
    ' End point of this arc:
    ex = cx + r * COS(a2): ey = cy + r * SIN(a2)
    ' Next centre: step back from the end point towards this centre by
    ' the NEXT radius.  Then the next arc continues smoothly.
    IF i < STEPS THEN
        rn = f(i + 1)
        cx = ex - rn * COS(a2): cy = ey - rn * SIN(a2)
    END IF
    ang = (ang + 90) MOD 360
    t = TIMER: DO WHILE TIMER - t < .15 AND TIMER >= t: LOOP   ' small pause
NEXT i

LOCATE 1, 1: COLOR 14: PRINT "Golden spiral: arcs of radius 1,1,2,3,5,8,13...";
LOCATE 30, 1: COLOR 7: PRINT "Press any key to exit";
k$ = INPUT$(1)
SCREEN 0: WIDTH 80
