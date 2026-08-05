' ============================================================
' TITLE:    String Art and Times-Table Circles
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     string art, lines, envelopes, cardioid, mod, screen 8
' SUMMARY:  Straight lines that make curves: corner "string art" envelopes and the famous times-table circle cardioid.
' ------------------------------------------------------------
' WHAT IT DOES
'   Part 1 copies the craft of stretching thread between nails:
'   in each corner, nail 1 on one edge joins nail N on the other,
'   nail 2 joins nail N-1, and so on. Only straight lines are
'   drawn, but a smooth curve appears.
'   Part 2 puts 120 nails around a circle and joins nail i to
'   nail (i * m) MOD 120. With m = 2 you get a heart-shaped
'   cardioid; other values of m make other flowers. Each key
'   press moves on to the next multiplier.
'
' HOW TO USE
'   Press any key after Part 1. In Part 2 press any key for the
'   next multiplier; Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Envelopes: curves built from many straight lines
'   * Placing points on a circle with COS and SIN
'   * MOD to "wrap around" a circle of numbered points
'   * Arrays to remember point positions
'
' THINGS TO TRY
'   * Use fractional multipliers like 2.5
'   * Change the nail count from 120 to 200
'   * Colour each line by its starting nail (rainbow effect)
' ============================================================

CONST PI = 3.14159265#
CONST NAILS = 120
DIM nx(NAILS - 1), ny(NAILS - 1)

SCREEN 8             ' 640 x 200, 16 colours
CLS

' ---- Part 1: string art in four corners ---------------------------
' The screen is 640 wide but only 200 high, so we step x by 16
' and y by 5 to get 40 "nails" along each edge.
FOR i = 0 TO 39
    x = i * 16: y = i * 5
    LINE (0, y)-(x, 199), 9               ' bottom-left corner: blue
    LINE (639, y)-(639 - x, 199), 10      ' bottom-right: green
    LINE (0, 199 - y)-(x, 0), 12          ' top-left: red
    LINE (639, 199 - y)-(639 - x, 0), 14  ' top-right: yellow
NEXT i
LOCATE 13, 32: PRINT " Only straight lines! "
LOCATE 25, 30: PRINT "Press any key";
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN GOTO Finish

' ---- Part 2: times-table circle -------------------------------------
' Work out where each nail sits on the circle just once.
' Because SCREEN 8 pixels are very tall, the x radius must be about
' 2.4 times the y radius for the circle to look round.
FOR i = 0 TO NAILS - 1
    a = 2 * PI * i / NAILS
    nx(i) = 320 - COS(a) * 210
    ny(i) = 100 - SIN(a) * 88
NEXT i

m = 2
DO
    CLS
    ' The nails themselves
    FOR i = 0 TO NAILS - 1
        PSET (nx(i), ny(i)), 15
    NEXT i
    ' The threads: i -> (i * m) MOD NAILS
    FOR i = 0 TO NAILS - 1
        j = (i * m) MOD NAILS
        c = 9 + (i \ 20) MOD 6           ' bands of colour around the ring
        LINE (nx(i), ny(i))-(nx(j), ny(j)), c
    NEXT i
    LOCATE 1, 2: PRINT "Times table of"; m; "on"; NAILS; "nails"
    LOCATE 25, 2: PRINT "Any key = next multiplier, Esc = quit";
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT DO
    m = m + 1
    IF m > 60 THEN m = 2
LOOP

Finish:
SCREEN 0: WIDTH 80
END
