' ============================================================
' TITLE:    Analog Clock
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     clock, time$, trigonometry, animation, screen 9
' SUMMARY:  A ticking analog wall clock with hour, minute and second hands, driven by the computer's TIME$.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a clock face with 60 minute ticks and 12 numbers, then
'   reads TIME$ ("HH:MM:SS") over and over. When the second
'   changes, the old hands are erased and the new ones drawn.
'   A digital readout and today's DATE$ sit underneath.
'
' HOW TO USE
'   Just watch it tick. Press any key to quit.
'
' CONCEPTS YOU WILL LEARN
'   * TIME$ and DATE$, and slicing them with MID$ and VAL
'   * Angles on a clock: 12 o'clock is "up", and clocks go
'     CLOCKWISE (the opposite of maths angles)
'   * Turning (angle, length) into an (x, y) end point
'   * Erasing by redrawing in the background colour
'   * Why the hour hand should move a little every minute
'
' THINGS TO TRY
'   * Add a pendulum swinging under the clock
'   * Make the second hand red and add a little circle at its tip
'   * Show Roman numerals instead of 1..12
' ============================================================

DECLARE SUB Hand (angleDeg!, length!, wid%, c%)
CONST PI = 3.14159265#
' The clock is centred at (320, 160). SCREEN 9 pixels are taller
' than wide, so every y distance is multiplied by ASP.
CONST CX = 320, CY = 160, ASP = .73

SCREEN 9
CLS

' ---- The face -------------------------------------------------------
' A grey rim: two circles in colour 7, fill the gap between them.
CIRCLE (CX, CY), 150, 7
CIRCLE (CX, CY), 144, 7
PAINT (CX + 147, CY), 8, 7
' Redraw the inner circle in white, then fill INSIDE it with blue.
' PAINT stops at the border colour, so the border must be one
' unbroken colour all the way round.
CIRCLE (CX, CY), 144, 15
PAINT (CX, CY), 1, 15

' 60 tick marks; every 5th is longer and brighter.
FOR m = 0 TO 59
    a = m * 6 * PI / 180              ' 6 degrees per minute
    IF m MOD 5 = 0 THEN r1 = 120: c = 15 ELSE r1 = 133: c = 7
    LINE (CX + SIN(a) * r1, CY - COS(a) * r1 * ASP)-(CX + SIN(a) * 140, CY - COS(a) * 140 * ASP), c
NEXT m

' Numbers 1..12. Text uses 8 x 14 character cells in SCREEN 9.
FOR h = 1 TO 12
    a = h * 30 * PI / 180
    x = CX + SIN(a) * 106
    y = CY - COS(a) * 106 * ASP
    n$ = LTRIM$(STR$(h))
    col = INT(x / 8) + 1 - LEN(n$) \ 2
    row = INT(y / 14) + 1
    COLOR 14
    LOCATE row, col: PRINT n$;
NEXT h

' ---- Run the clock ---------------------------------------------------
' The hands are kept shorter than the ring of numbers, so erasing
' a hand never rubs out part of a number.
oldT$ = ""
DO
    t$ = TIME$
    IF t$ <> oldT$ THEN
        ' Erase the previous hands (if any) by drawing them in blue.
        IF oldT$ <> "" THEN
            Hand hA, 55, 3, 1
            Hand mA, 80, 2, 1
            Hand sA, 88, 1, 1
        END IF

        hh = VAL(LEFT$(t$, 2))
        mm = VAL(MID$(t$, 4, 2))
        ss = VAL(RIGHT$(t$, 2))
        ' Angles in degrees, measured clockwise from 12 o'clock.
        sA = ss * 6                      ' 360 / 60
        mA = mm * 6 + ss * .1            ' creeps along with seconds
        hA = (hh MOD 12) * 30 + mm * .5  ' 360 / 12, plus 0.5 per minute

        Hand hA, 55, 3, 14
        Hand mA, 80, 2, 15
        Hand sA, 88, 1, 12
        CIRCLE (CX, CY), 5, 12: PAINT (CX, CY), 12, 12

        COLOR 15
        LOCATE 24, 36: PRINT t$
        LOCATE 25, 35: PRINT DATE$;
        oldT$ = t$
    END IF
LOOP WHILE INKEY$ = ""

SCREEN 0: WIDTH 80
END

' ---- Draw one hand ------------------------------------------------
' A thick hand is just several parallel lines side by side.
SUB Hand (angleDeg!, length!, wid%, c%)
    a! = angleDeg! * PI / 180
    ' Clockwise from "up": x uses SIN, y uses -COS.
    ex! = CX + SIN(a!) * length!
    ey! = CY - COS(a!) * length! * ASP
    FOR o% = -(wid% - 1) TO wid% - 1
        ' Shift sideways (at right angles to the hand).
        ox! = COS(a!) * o%
        oy! = SIN(a!) * o% * ASP
        LINE (CX + ox!, CY + oy!)-(ex!, ey!), c%
    NEXT o%
END SUB
