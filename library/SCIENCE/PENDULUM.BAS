' ============================================================
' TITLE:    Pendulum Lab (Single and Double)
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     physics, pendulum, chaos, oscillation, graphics
' SUMMARY:  Time a simple pendulum against the textbook formula, then watch a double pendulum go chaotic.
' ------------------------------------------------------------
' WHAT IT DOES
'   1) SIMPLE PENDULUM - a weight on a string.  The program measures
'      how long one full swing takes (the PERIOD) and compares it with
'      the famous formula T = 2*pi*SQR(L/g).  That formula is only
'      exact for small swings; try a big angle and see the difference.
'   2) DOUBLE PENDULUM - a pendulum hanging from a pendulum.  It obeys
'      simple laws, yet its motion is CHAOTIC: a tiny change in the
'      start makes a completely different dance.  A trail shows the
'      path of the lower weight.
'
' HOW TO USE
'   Choose 1 or 2 from the menu (Q quits).  In the simple pendulum
'   you type the starting angle.  Press any key to return to the menu.
'
' CONCEPTS YOU WILL LEARN
'   * Angular acceleration: theta'' = -(g/L) * SIN(theta)
'   * Numerical integration in small time steps
'   * Measuring a period by detecting direction changes
'   * Chaos and sensitive dependence on initial conditions
'
' THINGS TO TRY
'   * Simple: compare 5, 30, 90 and 170 degrees.  Big swings are slower!
'   * Double: change a1 by 0.001 radians and run again - totally different.
'   * Make the lower mass m2 much heavier than m1.
' ============================================================

DEFDBL A-Z
CONST PI = 3.14159265358979#
CONST G = 9.81

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "PENDULUM LAB": COLOR 7
    PRINT
    PRINT "  1) Simple pendulum - measure the period"
    PRINT "  2) Double pendulum - chaos!"
    PRINT "  Q) Quit"
    PRINT
    PRINT "Choice? ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    PRINT k$
    SELECT CASE k$
        CASE "1": GOSUB Simple
        CASE "2": GOSUB DoubleP
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80: CLS
END

' ============================================================
' SIMPLE PENDULUM
' ============================================================
Simple:
    INPUT "Starting angle in degrees (1-175)"; deg
    IF deg < 1 THEN deg = 1
    IF deg > 175 THEN deg = 175
    L = 1                           ' string length: 1 metre
    th = deg * PI / 180             ' angle from straight down (radians)
    w = 0                           ' angular velocity (radians/second)
    dt = 1 / 600                    ' 10 physics steps per 60 Hz frame
    t = 0: lastCross = -1: period = 0: swings = 0
    formula = 2 * PI * SQR(L / G)   ' small-angle prediction

    SCREEN 12
    cx = 320: cy = 120: rpx = 220   ' pivot point and 1 m in pixels
    ox = cx: oy = cy + rpx
    LOCATE 1, 1: COLOR 14: PRINT "SIMPLE PENDULUM   L = 1 m   start ="; deg; "deg"
    COLOR 7
    PRINT USING "Small-angle formula 2*pi*SQR(L/g) = #.### s"; formula
    DO
        FOR s = 1 TO 10
            ' The pull of gravity along the arc is g*SIN(theta).
            ' Dividing by L gives the angular acceleration.
            alpha = -(G / L) * SIN(th)
            oldw = w
            w = w + alpha * dt        ' "semi-implicit Euler": update speed first,
            th = th + w * dt          ' then position - this keeps energy stable
            t = t + dt
            ' A full period passes between two moments when the bob
            ' turns around at the SAME side.  Detect w going + to -.
            IF oldw > 0 AND w <= 0 THEN
                IF lastCross >= 0 THEN period = t - lastCross: swings = swings + 1
                lastCross = t
            END IF
        NEXT
        ' erase old string and bob, draw new ones
        LINE (cx, cy)-(ox, oy), 0
        LINE (ox - 13, oy - 13)-(ox + 13, oy + 13), 0, BF   ' black box wipes the bob
        ox = cx + rpx * SIN(th): oy = cy + rpx * COS(th)
        LINE (cx, cy)-(ox, oy), 7
        CIRCLE (ox, oy), 12, 12: PAINT (ox, oy), 12, 12
        CIRCLE (cx, cy), 3, 15
        LOCATE 4, 1
        PRINT USING "Time ###.## s   measured period #.### s   swings ###"; t; period; swings
        IF period > 0 THEN PRINT USING "Measured / formula = #.###"; period / formula
        WAIT &H3DA, 8
    LOOP WHILE INKEY$ = ""
RETURN

' ============================================================
' DOUBLE PENDULUM
' Equations of motion from Lagrangian mechanics (see any classical
' mechanics text).  a1, a2 are the angles, w1, w2 their speeds.
' ============================================================
DoubleP:
    RANDOMIZE TIMER
    m1 = 1: m2 = 1: L1 = 1: L2 = 1
    a1 = PI / 2 + RND * .5          ' start high up, slightly random
    a2 = PI / 2 + RND * 1
    w1 = 0: w2 = 0
    dt = 1 / 1200
    SCREEN 12
    cx = 320: cy = 230: sc = 110    ' pivot and pixels per metre
    LOCATE 1, 1: COLOR 14: PRINT "DOUBLE PENDULUM - chaotic motion.  Any key = menu"
    ' starting screen positions of the two bobs
    x1 = cx + sc * L1 * SIN(a1): y1 = cy + sc * L1 * COS(a1)
    x2 = x1 + sc * L2 * SIN(a2): y2 = y1 + sc * L2 * COS(a2)
    DO
        FOR s = 1 TO 20
            d = a1 - a2
            den = 2 * m1 + m2 - m2 * COS(2 * d)
            n1 = -G * (2 * m1 + m2) * SIN(a1) - m2 * G * SIN(a1 - 2 * a2)
            n1 = n1 - 2 * SIN(d) * m2 * (w2 * w2 * L2 + w1 * w1 * L1 * COS(d))
            acc1 = n1 / (L1 * den)
            n2 = 2 * SIN(d) * (w1 * w1 * L1 * (m1 + m2) + G * (m1 + m2) * COS(a1) + w2 * w2 * L2 * m2 * COS(d))
            acc2 = n2 / (L2 * den)
            w1 = w1 + acc1 * dt: w2 = w2 + acc2 * dt
            a1 = a1 + w1 * dt: a2 = a2 + w2 * dt
        NEXT
        ' erase old rods (black), leaving the trail mostly intact
        LINE (cx, cy)-(x1, y1), 0: LINE (x1, y1)-(x2, y2), 0
        CIRCLE (x1, y1), 6, 0: CIRCLE (x2, y2), 6, 0
        PSET (x2, y2), 3                ' trail point for the lower bob
        nx1 = cx + sc * L1 * SIN(a1): ny1 = cy + sc * L1 * COS(a1)
        nx2 = nx1 + sc * L2 * SIN(a2): ny2 = ny1 + sc * L2 * COS(a2)
        LINE (x2, y2)-(nx2, ny2), 3     ' connect the trail smoothly
        x1 = nx1: y1 = ny1: x2 = nx2: y2 = ny2
        LINE (cx, cy)-(x1, y1), 15: LINE (x1, y1)-(x2, y2), 15
        CIRCLE (x1, y1), 6, 14: CIRCLE (x2, y2), 6, 12
        WAIT &H3DA, 8
    LOOP WHILE INKEY$ = ""
RETURN
