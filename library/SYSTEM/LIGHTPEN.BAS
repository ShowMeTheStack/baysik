' ============================================================
' TITLE:    Light Pen Target Practice (PEN)
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     pen, on pen, light pen, mouse, events, game
' SUMMARY:  Use the mouse as a 1980s light pen: ON PEN traps each "touch" and PEN(n) tells you where it landed.
' ------------------------------------------------------------
' WHAT IT DOES
'   Before mice were common, some PCs had a LIGHT PEN: a pen with a
'   light sensor that you pressed against the CRT screen.  BASIC reads
'   it with the PEN function.  In this IDE the mouse plays the role of
'   the pen - clicking = pressing the pen on the glass.
'     PEN(0)  -1 if the pen was pressed since the last PEN(0)
'     PEN(1), PEN(2)  x, y (pixels) where it was last pressed
'     PEN(3)  -1 if the pen is touching the screen right now
'     PEN(4), PEN(5)  x, y where the pen is now
'     PEN(6), PEN(7)  text row, column where it was last pressed
'     PEN(8), PEN(9)  text row, column where it is now
'   ON PEN GOSUB + PEN ON runs a subroutine on every press.
'   Click the targets before they vanish!  30-second round.
'
' HOW TO USE
'   Click (pen-press) on the yellow targets.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * The PEN function and its ten sub-values
'   * ON PEN GOSUB, PEN ON / PEN OFF
'   * Hit-testing: is the press inside a circle?  (Pythagoras)
'
' THINGS TO TRY
'   * Make targets shrink as your score goes up
'   * Add a "miss" penalty
'   * Build a text-mode menu that is chosen with PEN(6) and PEN(7)
' ============================================================

DEFINT A-Z
SCREEN 12
RANDOMIZE TIMER
CONST R = 18                       ' target radius in pixels

hits = 0: misses = 0
ON PEN GOSUB PenPressed            ' trap every pen press
PEN ON

GOSUB NewTarget
start! = TIMER
DO
    remain! = 30 - (TIMER - start!)
    IF TIMER < start! THEN remain! = 0          ' (midnight safety)
    ' live pen position - updates as you move the mouse
    LOCATE 1, 1
    PRINT USING "Time ##  Hits ###  Misses ###   Pen now at x=### y=###"; remain!; hits; misses; PEN(4); PEN(5);
    IF PEN(3) THEN PRINT "  TOUCHING"; ELSE PRINT "          ";

    ' targets move to a new place every 1.5 seconds
    IF TIMER - born! > 1.5 OR TIMER < born! THEN
        LINE (tx - R - 1, ty - R - 1)-(tx + R + 1, ty + R + 1), 0, BF
        GOSUB NewTarget
    END IF
    k$ = INKEY$
LOOP UNTIL k$ = CHR$(27) OR remain! <= 0

PEN OFF
SCREEN 0: WIDTH 80
PRINT "Round over!  Hits:"; hits; "  Misses:"; misses
IF hits + misses > 0 THEN PRINT "Accuracy:"; INT(hits * 100 / (hits + misses)); "%"
END

' ---- event handler: the pen was pressed on the screen --------------
PenPressed:
    px = PEN(1): py = PEN(2)       ' where it was pressed (pixels)
    ' distance from the target centre, squared (no SQR needed)
    d& = CLNG(px - tx) * (px - tx) + CLNG(py - ty) * (py - ty)
    IF d& <= R * R THEN
        hits = hits + 1
        SOUND 1000, 1
        LINE (tx - R - 1, ty - R - 1)-(tx + R + 1, ty + R + 1), 0, BF
        GOSUB NewTarget
    ELSE
        misses = misses + 1
        CIRCLE (px, py), 3, 4      ' red dot where you missed
    END IF
    LOCATE 30, 1: PRINT USING "Last press: x=### y=###  text row ## col ##"; px; py; PEN(6); PEN(7);
RETURN

NewTarget:
    tx = 40 + RND * 560: ty = 60 + RND * 380
    CIRCLE (tx, ty), R, 14
    PAINT (tx, ty), 14
    CIRCLE (tx, ty), R \ 2, 12
    born! = TIMER
RETURN
