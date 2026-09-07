' ============================================================
' TITLE:    Animated Analog Clock
' CATEGORY: Animation & Sprites
' LEVEL:    Beginner
' TAGS:     clock, TIMER, TIME$, trigonometry, animation
' SUMMARY:  A real-time wall clock with a smoothly sweeping second hand, tick marks, and a digital readout.
' ------------------------------------------------------------
' WHAT IT DOES
'   Reads the computer's clock with TIMER (seconds since
'   midnight, including fractions) and turns hours, minutes and
'   seconds into angles for the three hands.  The face is drawn
'   once; each frame only the hands are erased (redrawn in the
'   background color) and drawn again at their new angles.
'
' HOW TO USE
'   Just watch it tell the time.
'     T   toggle tick sound    S   toggle smooth / jumping seconds
'     Esc quit
'
' CONCEPTS YOU WILL LEARN
'   * TIMER, and turning seconds into hours/minutes/seconds
'     with \ (integer divide) and MOD
'   * Angles on a clock: 12 o'clock is "up", and angles grow
'     clockwise - so x uses SIN and y uses -COS
'   * Erasing by redrawing in the background color
'   * Fractions: the hour hand moves a little every minute too
'
' THINGS TO TRY
'   * Add a second clock showing another time zone (+5 hours)
'   * Add an alarm that BEEPs at a time you choose
' ============================================================
DEFINT A-Z
DECLARE SUB Hand (ang!, length, wide, c)

CONST PI = 3.14159
CONST CX = 320, CY = 230, R = 190
CONST FACE = 1                    ' dark blue clock face

SCREEN 12

' ---- 1. Draw the face once ----------------------------------
CIRCLE (CX, CY), R + 12, 7
PAINT (CX, CY), 8, 7
CIRCLE (CX, CY), R, 15
PAINT (CX, CY), FACE, 15
FOR m = 0 TO 59
    a! = m * 2 * PI / 60
    IF m MOD 5 = 0 THEN inner = R - 20 ELSE inner = R - 8
    LINE (CX + inner * SIN(a!), CY - inner * COS(a!))-(CX + (R - 2) * SIN(a!), CY - (R - 2) * COS(a!)), 15
NEXT
' Numbers 1-12: find the spot, then convert pixels to text cells
' (each text cell in SCREEN 12 is 8 wide and 16 tall).
COLOR 14
FOR h = 1 TO 12
    a! = h * 2 * PI / 12
    tx = CX + (R - 38) * SIN(a!): ty = CY - (R - 38) * COS(a!)
    n$ = LTRIM$(STR$(h))
    ' Centre the text on (tx, ty): back up half its width/height.
    LOCATE (ty - 8) \ 16 + 1, (tx - 4 * LEN(n$)) \ 8 + 1
    PRINT n$;
NEXT
COLOR 7: LOCATE 30, 2: PRINT "T tick sound   S smooth/jump   Esc quit";

' ---- 2. Run the clock ---------------------------------------
smooth = -1: tick = 0
oldH! = -1: oldM! = -1: oldS! = -1
lastSec = -1
DO
    t! = TIMER
    IF NOT smooth THEN t! = INT(t!)       ' drop the fraction: jumpy seconds
    ' x - INT(x / n) * n  is the remainder after dividing by n,
    ' and (unlike MOD) it keeps the fraction.
    h! = t! / 3600                          ' hours since midnight
    hrs! = h! - INT(h! / 12) * 12           ' 0-11.99 (12-hour dial)
    mins! = t! / 60 - INT(h!) * 60          ' minutes 0-59.99
    secs! = t! - INT(t! / 60) * 60          ' seconds 0-59.99

    aH! = hrs! * 2 * PI / 12
    aM! = mins! * 2 * PI / 60
    aS! = secs! * 2 * PI / 60

    IF aS! <> oldS! OR aM! <> oldM! THEN
        ' Erase old hands by painting them in the face color.
        IF oldS! >= 0 THEN
            Hand oldS!, R - 50, 1, FACE
            Hand oldM!, R - 60, 4, FACE
            Hand oldH!, R - 100, 6, FACE
        END IF
        Hand aH!, R - 100, 6, 15       ' hour: short and wide
        Hand aM!, R - 60, 4, 11        ' minute: long
        Hand aS!, R - 50, 1, 12        ' second: thin and red
        CIRCLE (CX, CY), 6, 12: PAINT (CX, CY), 12, 12
        oldH! = aH!: oldM! = aM!: oldS! = aS!
    END IF

    ' Once per second: update the digital time and maybe tick.
    IF INT(secs!) <> lastSec THEN
        lastSec = INT(secs!)
        COLOR 15: LOCATE 2, 36: PRINT TIME$
        IF tick THEN SOUND 1200, .3
    END IF

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8
    k$ = UCASE$(INKEY$)
    IF k$ = "T" THEN tick = NOT tick
    IF k$ = "S" THEN smooth = NOT smooth
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

SUB Hand (ang!, length, wide, c)
    ' Draw a hand as a thin diamond: from a point slightly behind
    ' the centre, out to 'wide' pixels at each side, to the tip.
    tipX = CX + length * SIN(ang!): tipY = CY - length * COS(ang!)
    tailX = CX - 15 * SIN(ang!): tailY = CY + 15 * COS(ang!)
    ' The sideways direction is the hand's angle + 90 degrees.
    sx = wide * COS(ang!): sy = wide * SIN(ang!)
    LINE (tailX, tailY)-(CX + sx, CY + sy), c
    LINE (CX + sx, CY + sy)-(tipX, tipY), c
    LINE (tipX, tipY)-(CX - sx, CY - sy), c
    LINE (CX - sx, CY - sy)-(tailX, tailY), c
    LINE (tailX, tailY)-(tipX, tipY), c
END SUB
