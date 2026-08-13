' ============================================================
' TITLE:    Joystick Sketch Pad (STICK / STRIG)
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     stick, strig, on strig, joystick, gamepad, drawing
' SUMMARY:  A joystick tester and drawing toy that reads axes with STICK and buttons with STRIG and ON STRIG.
' ------------------------------------------------------------
' WHAT IT DOES
'   PCs had a "game port" for analog joysticks.  BASIC reads it with:
'     STICK(0)  - X of joystick A   (calling STICK(0) also SAMPLES all
'     STICK(1)  - Y of joystick A    axes; always call it first!)
'     STICK(2), STICK(3) - X and Y of joystick B
'     STRIG(1)  - button A1 is held now (-1 = yes, 0 = no)
'     STRIG(0)  - button A1 was pressed since the last check
'     STRIG(5)  - button A2 held,  STRIG(4) - A2 pressed since last check
'   Here, any modern gamepad plugged into your computer acts as the
'   joystick.  Axis values run from about 1 (left/up) to 200
'   (right/down), with ~100 in the middle.
'   Steer the pen with the left stick.  Hold button A to draw.  Press
'   button B to change colour (caught by an ON STRIG(4) event trap).
'
' HOW TO USE
'   Connect a gamepad and press a button on it once so the browser
'   notices it.  Left stick moves, A draws, B changes colour.
'   C clears the picture, Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * STICK(n) and the "sample with STICK(0) first" rule
'   * STRIG(n): even numbers = "was pressed", odd = "is held"
'   * ON STRIG(n) GOSUB + STRIG(n) ON for button events
'   * A dead zone so a resting stick does not drift
'
' THINGS TO TRY
'   * Make the pen speed depend on how far the stick is pushed (done!
'     - try changing the divisor 12)
'   * Use STICK(2)/STICK(3) for a second player's pen
'   * Turn it into a "Snake" game
' ============================================================

DEFINT A-Z
SCREEN 12                           ' 640x480, 16 colours
x = 320: y = 260: pc = 14

ON STRIG(4) GOSUB NextColour        ' button A2 (gamepad "B") pressed
STRIG(4) ON

GOSUB DrawFrame
DO
    ' ---- read the hardware -----------------------------------------
    jx = STICK(0)                   ' samples all axes + returns X
    jy = STICK(1)                   ' Y from that same sample
    held = STRIG(1)                 ' -1 while button A is held

    ' ---- convert 1..200 into a speed of about -8..+8 -----------------
    ' A small dead zone (90..110) means "stick is centred".
    dx = 0: dy = 0
    IF jx > 0 AND (jx < 90 OR jx > 110) THEN dx = (jx - 100) \ 12
    IF jy > 0 AND (jy < 90 OR jy > 110) THEN dy = (jy - 100) \ 12

    ' erase the old cursor (XOR-style cross drawn twice cancels out)
    GOSUB Cursor
    ox = x: oy = y
    x = x + dx: y = y + dy
    IF x < 2 THEN x = 2
    IF x > 637 THEN x = 637
    IF y < 42 THEN y = 42
    IF y > 477 THEN y = 477
    IF held THEN LINE (ox, oy)-(x, y), pc        ' draw while A is held
    GOSUB Cursor

    ' ---- status line -------------------------------------------------
    LOCATE 1, 1
    PRINT USING "STICK(0)=### STICK(1)=###  "; jx; jy;
    IF held THEN PRINT "STRIG(1)=-1 DRAW "; ELSE PRINT "STRIG(1)= 0 move ";
    PRINT USING " colour ## "; pc;
    LOCATE 2, 1: PRINT "A=draw  B=colour  C=clear  Esc=quit";
    IF jx = 0 THEN LOCATE 2, 45: PRINT "(no gamepad found yet)";

    k$ = UCASE$(INKEY$)
    IF k$ = "C" THEN GOSUB DrawFrame
    t! = TIMER: DO WHILE TIMER = t!: LOOP   ' one clock tick per frame
LOOP UNTIL k$ = CHR$(27)

STRIG(4) OFF
SCREEN 0: WIDTH 80
PRINT "Thanks for drawing!"
END

' ---- event trap: button B pressed -----------------------------------
NextColour:
    pc = pc + 1
    IF pc > 15 THEN pc = 1
    SOUND 600 + pc * 40, 1
RETURN

DrawFrame:
    CLS
    LINE (0, 38)-(639, 479), 8, B
RETURN

' A small cross drawn with XOR so drawing it twice restores the picture.
Cursor:
    PSET (x, y), POINT(x, y) XOR 15
    FOR i = 3 TO 5
        PSET (x + i, y), POINT(x + i, y) XOR 15
        PSET (x - i, y), POINT(x - i, y) XOR 15
        PSET (x, y + i), POINT(x, y + i) XOR 15
        PSET (x, y - i), POINT(x, y - i) XOR 15
    NEXT i
RETURN
