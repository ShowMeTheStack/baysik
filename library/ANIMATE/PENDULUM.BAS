' ============================================================
' TITLE:    Swinging Pendulum
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     physics, simulation, pendulum, SIN, graph
' SUMMARY:  A physics-driven pendulum swings, slows down with friction, and draws a live graph of its angle over time.
' ------------------------------------------------------------
' WHAT IT DOES
'   Simulates a real pendulum.  Gravity pulls the bob back toward
'   the bottom with a force proportional to SIN(angle); that
'   changes the angular velocity, which changes the angle.
'   Repeating these tiny steps 60 times a second produces a
'   natural swing.  Friction (damping) slowly steals energy.
'   Underneath, a strip chart plots the angle over time - you
'   will see a sine wave that shrinks as friction acts.
'
' HOW TO USE
'   Left / Right   give the bob a push
'   Up / Down      shorter / longer string (watch the speed!)
'   D              friction on / off
'   Esc            quit
'
' CONCEPTS YOU WILL LEARN
'   * Simple physics simulation (Euler integration):
'       acceleration = -(g / L) * SIN(angle) - friction * velocity
'       velocity = velocity + acceleration * dt
'       angle    = angle + velocity * dt
'   * Converting an angle to x, y with SIN and COS
'   * A scrolling strip chart
'   * Short strings swing faster: period = 2 * PI * SQR(L / g)
'
' THINGS TO TRY
'   * Start at a huge angle (almost upside down) - is it still
'     a perfect sine wave?
'   * Add a second pendulum with a different length beside it
' ============================================================
DEFINT A-Z
DECLARE SUB DrawPend (ang!, L, c, bobC)

CONST PIVX = 320, PIVY = 40
CONST G = 9.8
CONST DT = 1 / 60                 ' simulation step: 1/60 second
CONST SCALEPX = 120               ' pixels per metre of string

SCREEN 12
ang! = 1.2: vel! = 0              ' start lifted 1.2 radians (~69 deg)
L! = 2!                           ' string length in metres
damp! = .15: friction = -1
gx = 0                            ' x position on the strip chart

' Ceiling and chart frame.
LINE (PIVX - 60, PIVY - 6)-(PIVX + 60, PIVY), 6, BF
LINE (0, 380)-(639, 470), 8, B
LINE (1, 425)-(638, 425), 8           ' the zero-angle line
COLOR 7
LOCATE 1, 1: PRINT "<- -> push  Up/Down length  D friction  Esc quit"

oldAng! = ang!: oldLen = L! * SCALEPX
DO
    ' ---- 1. Physics ----------------------------------------
    acc! = -(G / L!) * SIN(ang!)
    IF friction THEN acc! = acc! - damp! * vel!
    vel! = vel! + acc! * DT
    ang! = ang! + vel! * DT

    ' ---- 2. Draw: erase old pendulum, draw new one ---------
    DrawPend oldAng!, oldLen, 0, 0
    lenPx = L! * SCALEPX
    DrawPend ang!, lenPx, 7, 14
    oldAng! = ang!: oldLen = lenPx

    ' ---- 3. Strip chart: one dot per frame -----------------
    LINE (gx + 1, 381)-(gx + 6, 469), 0, BF        ' clear just ahead
    PSET (gx + 1, 425), 8                         ' redraw zero line
    gy = 425 - ang! * 30                          ' 30 px per radian
    IF gy < 382 THEN gy = 382
    IF gy > 468 THEN gy = 468
    PSET (gx + 1, gy), 10
    gx = (gx + 1) MOD 632

    ' ---- 4. Info -------------------------------------------
    LOCATE 2, 1
    PRINT USING "angle ####.# deg   length #.## m   period #.## s   "; ang! * 57.29578; L!; 2 * 3.14159 * SQR(L! / G);
    IF friction THEN PRINT "friction ON "; ELSE PRINT "friction OFF";

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE CHR$(0) + "K": vel! = vel! - .8          ' push left
        CASE CHR$(0) + "M": vel! = vel! + .8          ' push right
        CASE CHR$(0) + "H": IF L! > .6 THEN L! = L! - .1
        CASE CHR$(0) + "P": IF L! < 2.5 THEN L! = L! + .1
        CASE "D": friction = NOT friction
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SUB DrawPend (ang!, L, c, bobC)
    ' Angle 0 = hanging straight down.  Positive = swung right.
    bx = PIVX + L * SIN(ang!)
    by = PIVY + L * COS(ang!)
    ' The string stops at the edge of the bob (L - 14).  If it
    ' went to the centre, then when erasing, the PAINT start point
    ' would already be border color and nothing would be filled!
    LINE (PIVX, PIVY)-(PIVX + (L - 14) * SIN(ang!), PIVY + (L - 14) * COS(ang!)), c
    CIRCLE (bx, by), 14, bobC
    ' Only PAINT if the centre is on screen (a big push can send
    ' the bob right over the top!).
    IF by >= 0 THEN PAINT (bx, by), bobC, bobC
    IF bobC THEN CIRCLE (bx - 4, by - 4), 3, 15   ' a shiny highlight
END SUB
