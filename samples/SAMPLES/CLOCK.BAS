' CLOCK.BAS - An analog clock driven by ON TIMER events
' Concepts: ON TIMER(n) GOSUB, TIMER ON, TIME$, CIRCLE, trig, event handlers
SCREEN 12
CONST PI = 3.14159265#
cx = 320: cy = 230: r = 180
CIRCLE (cx, cy), r + 10, 7
FOR h = 1 TO 12
    a = h * PI / 6
    LOCATE INT((cy - (r - 15) * COS(a)) / 16) + 1, INT((cx + (r - 15) * SIN(a)) / 8): PRINT LTRIM$(STR$(h));
NEXT
ON TIMER(1) GOSUB Tick
TIMER ON
GOSUB Tick
LOCATE 29, 25: PRINT "Press any key to stop";
DO: LOOP WHILE INKEY$ = ""
TIMER OFF
END

Tick:
    t$ = TIME$
    hh = VAL(LEFT$(t$, 2)) MOD 12: mm = VAL(MID$(t$, 4, 2)): ss = VAL(RIGHT$(t$, 2))
    CIRCLE (cx, cy), r - 25, 0, , , 1: PAINT (cx, cy), 0, 0
    CIRCLE (cx, cy), r - 25, 8
    DrawHand (hh + mm / 60) * PI / 6, r * .5, 15
    DrawHand (mm + ss / 60) * PI / 30, r * .75, 11
    DrawHand ss * PI / 30, r * .8, 12
    LOCATE 2, 36: PRINT t$
    RETURN

SUB DrawHand (a, length, colr)
    SHARED cx, cy
    LINE (cx, cy)-(cx + length * SIN(a), cy - length * COS(a)), colr
END SUB
