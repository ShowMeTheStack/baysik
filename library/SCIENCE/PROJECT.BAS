' ============================================================
' TITLE:    Projectile Motion with Air Drag
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     physics, gravity, drag, euler method, graphics
' SUMMARY:  Fire a cannonball and compare its real (air drag) path with the perfect vacuum parabola.
' ------------------------------------------------------------
' WHAT IT DOES
'   A cannon on the left fires a ball at the angle and speed you
'   choose.  Two paths are drawn at the same time:
'     - YELLOW: no air at all (the textbook parabola)
'     - RED:    with air resistance (drag) slowing the ball down
'   When both land, the program prints the range, flight time and
'   highest point of each, so you can see how much air matters.
'
' HOW TO USE
'   Enter a launch angle in degrees (1-89) and a speed in metres
'   per second (5-120).  Watch the shot, read the results, then
'   press a key for another shot.  Enter 0 for the angle to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting velocity into x and y parts with COS and SIN
'   * Gravity as a constant downward acceleration (9.81 m/s^2)
'   * Quadratic drag: force grows with speed squared
'   * Step-by-step simulation (the Euler method)
'   * WINDOW to draw in real-world metres instead of pixels
'
' THINGS TO TRY
'   * In a vacuum 45 degrees gives the longest range.  With drag the
'     best angle is LOWER - find it by experiment!
'   * Change K (the drag constant) to model a ping-pong ball (big K)
'     or a heavy shot-put (tiny K).
'   * Change G to 1.62 to fire on the Moon.
' ============================================================

DEFDBL A-Z                      ' double precision for smooth physics

CONST G = 9.81                  ' gravity on Earth, metres per second squared
CONST K = .0025                 ' drag constant per kg: (air density*area*Cd)/(2*mass)
CONST DT = .01                  ' time step: 1/100 of a second
CONST PI = 3.14159265358979#

DO
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "PROJECTILE MOTION WITH AIR DRAG": COLOR 7
    PRINT
    PRINT "Yellow = vacuum (no air),  Red = real air with drag."
    PRINT
    INPUT "Launch angle in degrees (1-89, 0 = quit)"; angle
    IF angle <= 0 THEN EXIT DO
    IF angle > 89 THEN angle = 89
    INPUT "Launch speed in m/s (5-120)"; speed
    IF speed < 5 THEN speed = 5
    IF speed > 120 THEN speed = 120

    ' --- Work out a nice drawing scale -------------------------
    ' The vacuum range is v^2 * sin(2a) / g and max height is
    ' (v sin a)^2 / (2g).  We use them to size the WINDOW so the
    ' whole flight fits on screen.
    rad = angle * PI / 180
    vacRange = speed * speed * SIN(2 * rad) / G
    vacHeight = (speed * SIN(rad)) ^ 2 / (2 * G)
    span = vacRange
    IF vacHeight * 1.6 > span THEN span = vacHeight * 1.6
    IF span < 10 THEN span = 10

    SCREEN 12
    ' WINDOW maps world coordinates onto the screen.  Y grows upward,
    ' just like in a physics book.  We leave a margin around the edges.
    WINDOW (-span * .05, -span * .08)-(span * 1.1, span * .75)
    LINE (-span * .05, 0)-(span * 1.1, 0), 2          ' the ground
    ' tick marks every tenth of the span
    FOR t = 0 TO 10
        LINE (span * t / 10, 0)-(span * t / 10, -span * .015), 8
    NEXT

    ' --- State for both balls ---------------------------------
    ' Ball 1 (vacuum): position x1,y1 velocity vx1,vy1
    ' Ball 2 (drag)  : position x2,y2 velocity vx2,vy2
    x1 = 0: y1 = 0: vx1 = speed * COS(rad): vy1 = speed * SIN(rad)
    x2 = 0: y2 = 0: vx2 = vx1: vy2 = vy1
    top1 = 0: top2 = 0: done1 = 0: done2 = 0: t = 0

    DO
        t = t + DT
        ' --- Vacuum ball: only gravity acts --------------------
        IF done1 = 0 THEN
            vy1 = vy1 - G * DT              ' gravity changes vertical speed
            x1 = x1 + vx1 * DT              ' velocity changes position
            y1 = y1 + vy1 * DT
            IF y1 > top1 THEN top1 = y1
            IF y1 < 0 THEN done1 = 1: t1 = t: y1 = 0
            PSET (x1, y1), 14
        END IF
        ' --- Drag ball: gravity + air resistance ---------------
        ' Drag points opposite to the motion and its size is
        ' K * v^2.  Splitting into parts: ax = -K*v*vx, ay = -g -K*v*vy
        IF done2 = 0 THEN
            v = SQR(vx2 * vx2 + vy2 * vy2)
            ax = -K * v * vx2
            ay = -G - K * v * vy2
            vx2 = vx2 + ax * DT
            vy2 = vy2 + ay * DT
            x2 = x2 + vx2 * DT
            y2 = y2 + vy2 * DT
            IF y2 > top2 THEN top2 = y2
            IF y2 < 0 THEN done2 = 1: t2 = t: y2 = 0
            CIRCLE (x2, y2), span * .004, 12
        END IF
        ' Slow the animation to roughly real time (100 steps/second
        ' would be too slow for big shots, so draw 4 steps per frame).
        frame = frame + 1
        IF frame MOD 4 = 0 THEN WAIT &H3DA, 8
        IF INKEY$ = CHR$(27) THEN done1 = 1: done2 = 1: t1 = t: t2 = t
    LOOP UNTIL done1 = 1 AND done2 = 1

    ' --- Report ---------------------------------------------------
    LOCATE 2, 2: COLOR 14
    PRINT USING "Vacuum: range ####.# m  height ####.# m  time ###.## s"; x1; top1; t1
    LOCATE 3, 2: COLOR 12
    PRINT USING "Drag  : range ####.# m  height ####.# m  time ###.## s"; x2; top2; t2
    LOCATE 4, 2: COLOR 7
    IF x1 > 0 THEN PRINT USING "Air resistance cut the range by ###%"; 100 * (1 - x2 / x1)
    LOCATE 29, 2: PRINT "Press any key for another shot...";
    DO: LOOP WHILE INKEY$ = ""
LOOP

SCREEN 0: WIDTH 80: CLS
PRINT "Thanks for experimenting with projectiles!"
END
