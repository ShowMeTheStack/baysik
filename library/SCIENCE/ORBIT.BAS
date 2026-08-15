' ============================================================
' TITLE:    Planetary Orbits (Newton's Gravity)
' CATEGORY: Science & Simulation
' LEVEL:    Intermediate
' TAGS:     physics, gravity, orbits, kepler, astronomy, graphics
' SUMMARY:  The inner planets and a comet orbit the Sun using nothing but Newton's law of gravity.
' ------------------------------------------------------------
' WHAT IT DOES
'   Newton discovered that every mass pulls on every other mass with
'   a force   F = G * M * m / r^2   (r = distance).  This program
'   gives Mercury, Venus, Earth, Mars and a comet a starting position
'   and speed, then lets gravity do ALL the rest.  Out of that one
'   rule come Kepler's laws: orbits are ellipses, the comet races
'   near the Sun and crawls far away, and outer planets take longer.
'
' HOW TO USE
'   +/-   speed time up or down        T  toggle orbit trails
'   ESC   quit
'   The panel shows how many Earth-years have passed and each body's
'   orbit count, so you can check that Mars takes ~1.9 years.
'
' CONCEPTS YOU WILL LEARN
'   * Inverse-square law of gravity
'   * Units chosen to make the maths simple (AU, years, G*M = 4*pi^2)
'   * Leapfrog integration (better energy behaviour than plain Euler)
'   * Kepler's 2nd and 3rd laws, seen in action
'
' THINGS TO TRY
'   * Give Earth 1.2x its speed: its orbit becomes an ellipse.
'   * Give Earth 1.42x (SQR(2)) its speed - escape velocity!
'   * Add Jupiter at 5.2 AU (you will need to zoom out: change SC).
' ============================================================

DEFDBL A-Z
DEFINT I-N
CONST PI = 3.14159265358979#
CONST NP = 5                    ' number of bodies
CONST SC = 100                  ' pixels per astronomical unit (AU)
CONST CX = 320, CY = 240        ' the Sun's position on screen

' In "astronomer units" - distance in AU (Sun-Earth distance), time
' in years - the Sun's G*M is exactly 4*pi^2.  So Earth at 1 AU
' needs speed 2*pi AU/year: one lap (2*pi*1) per year.
GM = 4 * PI * PI

DIM x(NP), y(NP), vx(NP), vy(NP), ax(NP), ay(NP)
DIM nm$(NP), col(NP), sx(NP), sy(NP), laps(NP), prevY(NP)

' name, distance (AU), speed factor (1 = circular orbit), colour
FOR i = 1 TO NP
    READ nm$(i), r, f, col(i)
    x(i) = r: y(i) = 0
    vx(i) = 0
    vy(i) = f * SQR(GM / r)     ' circular speed is SQR(GM/r)
NEXT
DATA "Mercury", 0.387, 1.0, 7
DATA "Venus", 0.723, 1.0, 14
DATA "Earth", 1.0, 1.0, 9
DATA "Mars", 1.524, 1.0, 12
DATA "Comet", 2.1, 0.45, 11

dt = .0005                      ' time step in years (about 4.4 hours)
spf = 6                         ' physics steps per frame
trails = 1
years = 0

SCREEN 12
GOSUB Accel                     ' leapfrog needs the starting accelerations
CIRCLE (CX, CY), 8, 14: PAINT (CX, CY), 14, 14
FOR i = 1 TO NP: sx(i) = CX + x(i) * SC: sy(i) = CY - y(i) * SC: NEXT

DO
    k$ = UCASE$(INKEY$)
    IF k$ = "+" OR k$ = "=" THEN spf = spf + 2: IF spf > 40 THEN spf = 40
    IF k$ = "-" THEN spf = spf - 2: IF spf < 2 THEN spf = 2
    IF k$ = "T" THEN trails = 1 - trails: CLS : CIRCLE (CX, CY), 8, 14: PAINT (CX, CY), 14, 14
    IF k$ = CHR$(27) THEN EXIT DO

    FOR s = 1 TO spf
        ' ---- Leapfrog ("kick-drift-kick") -----------------------
        ' half a kick of velocity, a full drift of position, then
        ' recompute forces and give the second half kick.
        FOR i = 1 TO NP
            vx(i) = vx(i) + ax(i) * dt / 2: vy(i) = vy(i) + ay(i) * dt / 2
            prevY(i) = y(i)
            x(i) = x(i) + vx(i) * dt: y(i) = y(i) + vy(i) * dt
        NEXT
        GOSUB Accel
        FOR i = 1 TO NP
            vx(i) = vx(i) + ax(i) * dt / 2: vy(i) = vy(i) + ay(i) * dt / 2
            ' count a lap each time the body crosses the +x axis upward
            IF prevY(i) < 0 AND y(i) >= 0 AND x(i) > 0 THEN laps(i) = laps(i) + 1
        NEXT
        years = years + dt
    NEXT

    ' ---- draw ----------------------------------------------------
    FOR i = 1 TO NP
        ' erase the old dot (or leave a faint trail behind)
        IF trails THEN
            LINE (sx(i) - 3, sy(i) - 3)-(sx(i) + 3, sy(i) + 3), 0, BF
            PSET (sx(i), sy(i)), 8
        ELSE
            LINE (sx(i) - 3, sy(i) - 3)-(sx(i) + 3, sy(i) + 3), 0, BF
        END IF
        sx(i) = CX + x(i) * SC
        sy(i) = CY - y(i) * SC          ' minus: screen y points down
        CIRCLE (sx(i), sy(i)), 2, col(i)
        PAINT (sx(i), sy(i)), col(i), col(i)
    NEXT
    CIRCLE (CX, CY), 8, 14
    COLOR 15: LOCATE 1, 1
    PRINT USING "Years: ###.##   speed x##   (+/- speed, T trails, ESC)"; years; spf
    FOR i = 1 TO NP
        COLOR col(i): LOCATE 2 + i, 1
        r = SQR(x(i) * x(i) + y(i) * y(i))
        v = SQR(vx(i) * vx(i) + vy(i) * vy(i))
        PRINT USING "\     \ r=#.## AU v=##.# AU/yr laps ###"; nm$(i); r; v; laps(i)
    NEXT
    WAIT &H3DA, 8
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Accel: gravity from the Sun on every body.
'   a = -GM / r^2 pointing toward the Sun.  Splitting into x and y:
'   ax = -GM * x / r^3,  ay = -GM * y / r^3
' ------------------------------------------------------------
Accel:
    FOR j = 1 TO NP
        r2 = x(j) * x(j) + y(j) * y(j)
        r3 = r2 * SQR(r2)
        ax(j) = -GM * x(j) / r3
        ay(j) = -GM * y(j) / r3
    NEXT
RETURN
